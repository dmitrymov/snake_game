import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/direction.dart';
import '../models/game_settings.dart';
import '../models/difficulty.dart';
import '../models/position.dart';
import '../models/snake.dart';
import '../models/eat_particle.dart';
import '../models/score_popup.dart';
import '../models/food.dart';
import '../services/game_service.dart';
import '../services/high_score_service.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';

/// ViewModel that manages the Snake game state and business logic
class GameViewModel extends ChangeNotifier {
  final GameService _gameService = GameService();
  bool _badFoodEnabled = true;
  final HighScoreService _highScoreService = HighScoreService();
  final SettingsService _settingsService = SettingsService();
  final SoundService _soundService = SoundService();
  Difficulty _difficulty = Difficulty.normal;
  Direction? _pendingDirection;
  
  GameState _gameState = GameState.initial();
  Timer? _gameTimer;
  Timer? _badFoodTimer;
  Timer? _effectsTimer;

  GameViewModel() {
    _loadHighScore();
    _loadSettings();
  }

  /// Current game state (read-only access)
  GameState get gameState => _gameState;

  /// Quick access getters for common state properties
  bool get isPlaying => _gameState.isPlaying;
  bool get isPaused => _gameState.isPaused;
  bool get isGameOver => _gameState.isGameOver;
  bool get isReady => _gameState.isReady;
  int get score => _gameState.score;
  int get snakeLength => _gameState.snake.length;
int get highScore => _gameState.highScore;
  Difficulty get difficulty => _difficulty;

  // Transient eat particles for effects
  final List<EatParticle> _eatParticles = [];
  List<EatParticle> get eatParticles => List.unmodifiable(_eatParticles);

  // Floating score popups
  final List<ScorePopup> _scorePopups = [];
  List<ScorePopup> get scorePopups => List.unmodifiable(_scorePopups);

  /// Starts a new game
  void startNewGame() {
    _stopGameTimer();

    // Generate obstacles based on difficulty and board size
    final obstacleCount = _computeObstacleCount(_difficulty);
    final obstacles = _gameService.generateObstacles(
      Snake.initial(boardWidth: _gameState.boardWidth, boardHeight: _gameState.boardHeight),
      _gameState.boardWidth,
      _gameState.boardHeight,
      count: obstacleCount,
    );
    
    final initialStatus = (_difficulty == Difficulty.easy) ? GameStatus.playing : GameStatus.paused;

    _gameState = GameState.initial(
      boardWidth: _gameState.boardWidth,
      boardHeight: _gameState.boardHeight,
      gameSpeed: _gameState.baseSpeed,
      highScore: _gameState.highScore,
      baseSpeed: _gameState.baseSpeed,
      wrapAround: _gameState.wrapAround,
      obstacles: obstacles,
    ).copyWith(status: initialStatus);

    _generateFood();

    // For non-easy difficulty, show 3-2-1 countdown before starting
    if (_difficulty == Difficulty.easy) {
      _startGameTimer();
    } else {
      _startResumeCountdown();
    }

    _eatParticles.clear();
    _scorePopups.clear();
    _pendingDirection = null;
    
    notifyListeners();
  }

  /// Pauses the current game
  void pauseGame() {
    if (!_gameState.isPlaying) return;
    
    _stopGameTimer();
    _gameState = _gameState.copyWith(status: GameStatus.paused);
    notifyListeners();
  }

  /// Resumes the paused game
  int? _resumeCountdown; // 3..2..1 when resuming
  int? get resumeCountdown => _resumeCountdown;

  void resumeGame() {
    if (!_gameState.isPaused) return;
    _startResumeCountdown();
  }

  void _startResumeCountdown() {
    _resumeCountdown = 3;
    notifyListeners();
    Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_resumeCountdown == null) {
        timer.cancel();
        return;
      }
      _resumeCountdown = (_resumeCountdown! - 1);
      if (_resumeCountdown! <= 0) {
        timer.cancel();
        _resumeCountdown = null;
        _gameState = _gameState.copyWith(status: GameStatus.playing);
        _startGameTimer();
      }
      notifyListeners();
    });
  }

  /// Ends the current game
  void endGame() {
    _stopGameTimer();
    _cancelBadFoodTimer();
    _soundService.playCrash();
    _gameState = _gameState.copyWith(status: GameStatus.gameOver);
    notifyListeners();
  }

  /// Resets the game to initial state
  void resetGame() {
    _stopGameTimer();
    _cancelBadFoodTimer();
    _stopEffectsTimerIfIdle();
    _gameState = GameState.initial(
      boardWidth: _gameState.boardWidth,
      boardHeight: _gameState.boardHeight,
      gameSpeed: _gameState.baseSpeed,
      highScore: _gameState.highScore,
      baseSpeed: _gameState.baseSpeed,
      wrapAround: _gameState.wrapAround,
    );
    _eatParticles.clear();
    _scorePopups.clear();
    _pendingDirection = null;
    notifyListeners();
  }

  /// Dynamically update the board size to fit the current screen (in cells).
  /// This resets the game to Ready with preserved high score and settings.
  void updateBoardSizeIfNeeded(int width, int height) {
    if (width <= 0 || height <= 0) return;
    if (width == _gameState.boardWidth && height == _gameState.boardHeight) return;

    _stopGameTimer();

    final obstacleCount = _computeObstacleCount(_difficulty, width: width, height: height);
    final initialSnake = Snake.initial(boardWidth: width, boardHeight: height);
    final obstacles = _gameService.generateObstacles(
      initialSnake,
      width,
      height,
      count: obstacleCount,
    );

    _gameState = GameState.initial(
      boardWidth: width,
      boardHeight: height,
      gameSpeed: _gameState.baseSpeed,
      highScore: _gameState.highScore,
      baseSpeed: _gameState.baseSpeed,
      wrapAround: _gameState.wrapAround,
      obstacles: obstacles,
    );

    // Generate food for the new board
    _generateFood();

    _eatParticles.clear();
    _scorePopups.clear();
    _pendingDirection = null;

    notifyListeners();
  }

  /// Apply settings and reset to ready state (preserves high score)
  Future<void> applySettings(GameSettings settings) async {
    _stopGameTimer();
    await _settingsService.saveSettings(settings);

    // Keep current auto-fitted board size. Do not override with persisted settings.
    final bw = _gameState.boardWidth;
    final bh = _gameState.boardHeight;

    // Update sound toggle
    _soundService.setEnabled(settings.soundEnabled);
    _soundService.setHapticsEnabled(settings.hapticsEnabled);
    _badFoodEnabled = settings.badFoodEnabled;
    _difficulty = settings.difficulty;

    // Pre-generate obstacles to visualize density for new settings
    final obstacleCount = _computeObstacleCount(_difficulty, width: bw, height: bh);
    final initialSnake = Snake.initial(boardWidth: bw, boardHeight: bh);
    final obstacles = _gameService.generateObstacles(
      initialSnake,
      bw,
      bh,
      count: obstacleCount,
    );

    _gameState = GameState.initial(
      boardWidth: bw,
      boardHeight: bh,
      gameSpeed: settings.baseSpeed,
      highScore: _gameState.highScore,
      baseSpeed: settings.baseSpeed,
      wrapAround: settings.wrapAround,
      obstacles: obstacles,
    );
    _eatParticles.clear();
    _scorePopups.clear();
    _cancelBadFoodTimer();
    _generateFood();
    _pendingDirection = null;
    notifyListeners();
  }

  /// Changes the snake's direction
  void changeDirection(Direction direction) {
    if (!_gameState.isPlaying) return;

    // Buffer direction changes and apply once per tick for deterministic movement.
    // Prevent reversing into itself by validating against the most recent intended direction.
    final currentDir = _pendingDirection ?? _gameState.snake.direction;
    if (direction == currentDir.opposite && _gameState.snake.length > 1) return;
    if (direction == currentDir) return;
    _pendingDirection = direction;
  }


  /// Handles game tick - moves snake and updates game state
  void _gameTick() {
    if (!_gameState.isPlaying) return;

    // Apply buffered direction exactly once per tick.
    if (_pendingDirection != null) {
      _gameState = _gameState.copyWith(
        snake: _gameState.snake.changeDirection(_pendingDirection!),
      );
      _pendingDirection = null;
    }

    var newSnake = _gameState.snake;
    var newScore = _gameState.score;
    var newFood = _gameState.food;

    // Determine next head position depending on wrap setting
    var nextHeadPosition = newSnake.head.move(newSnake.direction);
    if (_gameState.wrapAround) {
      nextHeadPosition = nextHeadPosition.wrap(_gameState.boardWidth, _gameState.boardHeight);
    } else {
      // If out of bounds, it's a wall collision -> game over
      if (nextHeadPosition.x < 0 ||
          nextHeadPosition.y < 0 ||
          nextHeadPosition.x >= _gameState.boardWidth ||
          nextHeadPosition.y >= _gameState.boardHeight) {
        endGame();
        return;
      }
    }

    // Collision with obstacle -> game over
    if (_gameState.obstacles.contains(nextHeadPosition)) {
      endGame();
      return;
    }

    // Check if snake will eat food
    final bool willEatFood = newFood != null && nextHeadPosition == newFood.position;

    if (willEatFood) {
      // Snake grows and score increases
      _soundService.playEat();
      final foodPoints = newFood.points;
      final kind = foodPoints >= 2 ? 1 : (foodPoints < 0 ? -1 : 0);
      _spawnEatParticles(nextHeadPosition, kind);
      if (foodPoints > 0) {
        final inc = _gameService.calculateScoreIncrease(newScore, newSnake.length, _difficulty);
        _spawnScorePopup(nextHeadPosition, inc);
        newSnake = newSnake.moveAndGrow(_gameState.boardWidth, _gameState.boardHeight);
        newScore += inc;
      } else {
        // Bad food: shrink by 1
        newSnake = newSnake.move(_gameState.boardWidth, _gameState.boardHeight);
        if (newSnake.length > 1) {
          final reduced = List<Position>.from(newSnake.body)..removeLast();
          newSnake = newSnake.copyWith(body: reduced);
        } else {
          endGame();
          return;
        }
      }
      newFood = null; // Food is consumed
    } else {
      // Normal movement
      newSnake = newSnake.move(_gameState.boardWidth, _gameState.boardHeight);
    }

    // Check for collision with self
    if (newSnake.hasSelfCollision) {
      endGame();
      return;
    }

    // Update high score if needed
    final bool isNewHigh = newScore > _gameState.highScore;
    final int updatedHighScore = isNewHigh ? newScore : _gameState.highScore;

    // Update game state
    _gameState = _gameState.copyWith(
      snake: newSnake,
      score: newScore,
      food: newFood,
      highScore: updatedHighScore,
    );

    // Persist high score asynchronously (no await to keep tick lightweight)
    if (isNewHigh) {
      _highScoreService.setHighScore(updatedHighScore);
    }

    // Generate new food if needed
    if (_gameState.food == null) {
      _generateFood();
    }

    // Update game speed based on score
    _updateGameSpeed();

    // Prune transient effects (particles/popups)
    _pruneEffects();

    notifyListeners();
  }

  /// Generates new food at a random position
  void _generateFood() {
    final food = _gameService.generateFood(
      _gameState.snake,
      _gameState.boardWidth,
      _gameState.boardHeight,
      blocked: _gameState.obstacles,
      allowBad: _badFoodEnabled,
    );
    _gameState = _gameState.copyWith(food: food);
    _scheduleBadFoodExpiry(food);
  }

  /// Updates the game speed based on current score
  void _updateGameSpeed() {
    final newSpeed = _gameService.calculateGameSpeed(_gameState.score, _gameState.baseSpeed, _difficulty);
    if (newSpeed != _gameState.gameSpeed) {
      _gameState = _gameState.copyWith(gameSpeed: newSpeed);
      _restartGameTimer();
    }
  }

  /// Starts the game timer
  void _startGameTimer() {
    _gameTimer = Timer.periodic(
      Duration(milliseconds: _gameState.gameSpeed),
      (_) => _gameTick(),
    );
  }

  /// Stops the game timer
  void _stopGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  /// Restarts the game timer with new speed
  void _restartGameTimer() {
    if (_gameState.isPlaying) {
      _stopGameTimer();
      _startGameTimer();
    }
  }

  Future<void> _loadHighScore() async {
    final hs = await _highScoreService.getHighScore();
    _gameState = _gameState.copyWith(highScore: hs);
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final s = await _settingsService.getSettings();

    // Initialize sound toggle
    _soundService.setEnabled(s.soundEnabled);
    _soundService.setHapticsEnabled(s.hapticsEnabled);
    _badFoodEnabled = s.badFoodEnabled;
    _difficulty = s.difficulty;

    // Pre-generate obstacles using loaded settings
    final obstacleCount = _computeObstacleCount(_difficulty, width: s.boardWidth, height: s.boardHeight);
    final initialSnake = Snake.initial(boardWidth: s.boardWidth, boardHeight: s.boardHeight);
    final obstacles = _gameService.generateObstacles(
      initialSnake,
      s.boardWidth,
      s.boardHeight,
      count: obstacleCount,
    );

    _gameState = GameState.initial(
      boardWidth: s.boardWidth,
      boardHeight: s.boardHeight,
      gameSpeed: s.baseSpeed,
      highScore: _gameState.highScore,
      baseSpeed: s.baseSpeed,
      wrapAround: s.wrapAround,
      obstacles: obstacles,
    );
    _pendingDirection = null;
    notifyListeners();
  }

  void _scheduleBadFoodExpiry(Food food) {
    _cancelBadFoodTimer();
    if (food.kind == FoodKind.bad) {
      _badFoodTimer = Timer(const Duration(seconds: 30), () {
        // If food is unchanged and still bad, remove and respawn
        final current = _gameState.food;
        if (current != null &&
            current.kind == FoodKind.bad &&
            current.createdAtMs == food.createdAtMs &&
            current.position == food.position &&
            _gameState.status != GameStatus.gameOver) {
          _gameState = _gameState.copyWith(food: null);
          _generateFood();
          notifyListeners();
        }
      });
    }
  }

  void _cancelBadFoodTimer() {
    _badFoodTimer?.cancel();
    _badFoodTimer = null;
  }

  @override
  void dispose() {
    _stopGameTimer();
    _cancelBadFoodTimer();
    _effectsTimer?.cancel();
    _effectsTimer = null;
    _soundService.dispose();
    super.dispose();
  }

  int _computeObstacleCount(Difficulty difficulty, {int? width, int? height}) {
    final w = width ?? _gameState.boardWidth;
    final h = height ?? _gameState.boardHeight;
    final area = w * h;
    final density = difficulty.obstacleDensity;
    final raw = (area * density).round();
    // Ensure there is always enough free space: cap to area - snake length - 5
    final maxAllowed = area - _gameState.snake.length - 5;
    return raw.clamp(0, maxAllowed);
  }

  void _spawnEatParticles(Position origin, int kind) {
    final rng = math.Random();
    const count = 8;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < count; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final p = EatParticle(
        id: '${DateTime.now().microsecondsSinceEpoch}_$i',
        origin: origin,
        angle: angle,
        isRed: i.isEven,
        createdAtMs: now,
        kind: kind,
      );
      _eatParticles.add(p);
    }
    _ensureEffectsTimer();
  }

  void _spawnScorePopup(Position origin, int value) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final popup = ScorePopup(
      id: 'popup_${now}_${_scorePopups.length}',
      value: value,
      createdAtMs: now,
      x: origin.x,
      y: origin.y,
    );
    _scorePopups.add(popup);
    _ensureEffectsTimer();
  }

  void _ensureEffectsTimer() {
    if (_effectsTimer != null) return;
    _effectsTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final changed = _pruneEffects();
      if (changed) notifyListeners();
      _stopEffectsTimerIfIdle();
    });
    notifyListeners();
  }

  bool _pruneEffects() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final beforeParticles = _eatParticles.length;
    final beforePopups = _scorePopups.length;

    // Particles live for ~250ms
    _eatParticles.removeWhere((p) => (now - p.createdAtMs) >= 260);

    // Popups live for their duration
    _scorePopups.removeWhere((p) => (now - p.createdAtMs) >= p.durationMs);

    return _eatParticles.length != beforeParticles || _scorePopups.length != beforePopups;
  }

  void _stopEffectsTimerIfIdle() {
    if (_eatParticles.isNotEmpty || _scorePopups.isNotEmpty) return;
    _effectsTimer?.cancel();
    _effectsTimer = null;
  }

}

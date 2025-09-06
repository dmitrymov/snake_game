import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_state.dart';
import '../models/direction.dart';
import '../models/game_settings.dart';
import '../models/difficulty.dart';
import '../models/position.dart';
import '../models/snake.dart';
import '../services/game_service.dart';
import '../services/high_score_service.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';

/// ViewModel that manages the Snake game state and business logic
class GameViewModel extends ChangeNotifier {
  final GameService _gameService = GameService();
  final HighScoreService _highScoreService = HighScoreService();
  final SettingsService _settingsService = SettingsService();
  final SoundService _soundService = SoundService();
  
  GameState _gameState = GameState.initial();
  Timer? _gameTimer;

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

  /// Starts a new game
  void startNewGame() {
    _stopGameTimer();

    // Generate obstacles based on difficulty and board size
    final difficulty = _deriveDifficulty();
    final obstacleCount = _computeObstacleCount(difficulty);
    final obstacles = _gameService.generateObstacles(
      Snake.initial(boardWidth: _gameState.boardWidth, boardHeight: _gameState.boardHeight),
      _gameState.boardWidth,
      _gameState.boardHeight,
      count: obstacleCount,
    );
    
    _gameState = GameState.initial(
      boardWidth: _gameState.boardWidth,
      boardHeight: _gameState.boardHeight,
      gameSpeed: _gameState.baseSpeed,
      highScore: _gameState.highScore,
      baseSpeed: _gameState.baseSpeed,
      wrapAround: _gameState.wrapAround,
      obstacles: obstacles,
    ).copyWith(status: GameStatus.playing);
    _generateFood();
    _startGameTimer();
    
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
  void resumeGame() {
    if (!_gameState.isPaused) return;
    
    _gameState = _gameState.copyWith(status: GameStatus.playing);
    _startGameTimer();
    notifyListeners();
  }

  /// Ends the current game
  void endGame() {
    _stopGameTimer();
    _soundService.playCrash();
    _gameState = _gameState.copyWith(status: GameStatus.gameOver);
    notifyListeners();
  }

  /// Resets the game to initial state
  void resetGame() {
    _stopGameTimer();
    _gameState = GameState.initial(
      boardWidth: _gameState.boardWidth,
      boardHeight: _gameState.boardHeight,
      gameSpeed: _gameState.baseSpeed,
      highScore: _gameState.highScore,
      baseSpeed: _gameState.baseSpeed,
      wrapAround: _gameState.wrapAround,
    );
    notifyListeners();
  }

  /// Apply settings and reset to ready state (preserves high score)
  Future<void> applySettings(GameSettings settings) async {
    _stopGameTimer();
    await _settingsService.saveSettings(settings);

    // Update sound toggle
    _soundService.setEnabled(settings.soundEnabled);

    // Pre-generate obstacles to visualize density for new settings
    final difficulty = settings.difficulty;
    final obstacleCount = _computeObstacleCount(difficulty, width: settings.boardWidth, height: settings.boardHeight);
    final initialSnake = Snake.initial(boardWidth: settings.boardWidth, boardHeight: settings.boardHeight);
    final obstacles = _gameService.generateObstacles(
      initialSnake,
      settings.boardWidth,
      settings.boardHeight,
      count: obstacleCount,
    );

    _gameState = GameState.initial(
      boardWidth: settings.boardWidth,
      boardHeight: settings.boardHeight,
      gameSpeed: settings.baseSpeed,
      highScore: _gameState.highScore,
      baseSpeed: settings.baseSpeed,
      wrapAround: settings.wrapAround,
      obstacles: obstacles,
    );
    notifyListeners();
  }

  /// Changes the snake's direction
  void changeDirection(Direction direction) {
    if (!_gameState.isPlaying) return;
    
    final newSnake = _gameState.snake.changeDirection(direction);
    _gameState = _gameState.copyWith(snake: newSnake);
    notifyListeners();
  }

  /// Handles game tick - moves snake and updates game state
  void _gameTick() {
    if (!_gameState.isPlaying) return;

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
      newSnake = newSnake.moveAndGrow(_gameState.boardWidth, _gameState.boardHeight);
      newScore += _gameService.calculateScoreIncrease(newScore, newSnake.length);
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

    notifyListeners();
  }

  /// Generates new food at a random position
  void _generateFood() {
    final food = _gameService.generateFood(
      _gameState.snake,
      _gameState.boardWidth,
      _gameState.boardHeight,
      blocked: _gameState.obstacles,
    );
    _gameState = _gameState.copyWith(food: food);
  }

  /// Updates the game speed based on current score
  void _updateGameSpeed() {
    final difficulty = _deriveDifficulty();
    final newSpeed = _gameService.calculateGameSpeed(_gameState.score, _gameState.baseSpeed, difficulty);
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

    // Pre-generate obstacles using loaded settings
    final difficulty = s.difficulty;
    final obstacleCount = _computeObstacleCount(difficulty, width: s.boardWidth, height: s.boardHeight);
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
    notifyListeners();
  }

  Difficulty _deriveDifficulty() {
    // We infer difficulty from settings by comparing baseSpeed and wrapAround is not relevant.
    // Since GameState does not store difficulty explicitly, read current persisted settings again would be heavy.
    // Instead, approximate by using SettingsService.getSettings? But that is async.
    // We'll assume the last applied settings are represented by baseSpeed and that _loadSettings/applySettings used s.difficulty.
    // To keep it simple, map baseSpeed to nearest preset when computing speed & obstacles.
    final base = _gameState.baseSpeed;
    if (base <= Difficulty.hard.suggestedBaseSpeed) return Difficulty.hard;
    if (base >= Difficulty.easy.suggestedBaseSpeed) return Difficulty.easy;
    return Difficulty.normal;
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

  @override
  void dispose() {
    _stopGameTimer();
    super.dispose();
  }
}

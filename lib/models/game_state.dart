import 'snake.dart';
import 'food.dart';

// Sentinel used to distinguish between "no change" and "explicit null" in copyWith.
const Object _unset = Object();

/// Enum representing the current state of the game
enum GameStatus {
  ready,    // Game is ready to start
  playing,  // Game is currently being played
  paused,   // Game is paused
  gameOver, // Game has ended
}

/// Represents the complete state of the Snake game
class GameState {
  final Snake snake;
  final Food? food;
  final int score;
  final int highScore;
  final GameStatus status;
  final int boardWidth;
  final int boardHeight;
  final int gameSpeed; // milliseconds between moves

  const GameState({
    required this.snake,
    this.food,
    this.score = 0,
    this.highScore = 0,
    this.status = GameStatus.ready,
    this.boardWidth = 20,
    this.boardHeight = 20,
    this.gameSpeed = 200,
  });

  /// Creates an initial game state
  factory GameState.initial({
    int boardWidth = 20,
    int boardHeight = 20,
    int gameSpeed = 200,
    int highScore = 0,
  }) {
    return GameState(
      snake: Snake.initial(
        boardWidth: boardWidth,
        boardHeight: boardHeight,
      ),
      boardWidth: boardWidth,
      boardHeight: boardHeight,
      gameSpeed: gameSpeed,
      highScore: highScore,
    );
  }

  /// Creates a copy of this game state with updated values
  /// Note: `food` supports explicit null. Pass `food: null` to remove food.
  GameState copyWith({
    Snake? snake,
    Object? food = _unset,
    int? score,
    int? highScore,
    GameStatus? status,
    int? boardWidth,
    int? boardHeight,
    int? gameSpeed,
  }) {
    return GameState(
      snake: snake ?? this.snake,
      food: identical(food, _unset) ? this.food : food as Food?,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      status: status ?? this.status,
      boardWidth: boardWidth ?? this.boardWidth,
      boardHeight: boardHeight ?? this.boardHeight,
      gameSpeed: gameSpeed ?? this.gameSpeed,
    );
  }

  /// Removes food from the game state
  GameState removeFood() {
    return copyWith(food: null);
  }

  /// Checks if the game is currently active (playing or paused)
  bool get isActive => status == GameStatus.playing || status == GameStatus.paused;

  /// Checks if the game is over
  bool get isGameOver => status == GameStatus.gameOver;

  /// Checks if the game is ready to start
  bool get isReady => status == GameStatus.ready;

  /// Checks if the game is playing
  bool get isPlaying => status == GameStatus.playing;

  /// Checks if the game is paused
  bool get isPaused => status == GameStatus.paused;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameState &&
          runtimeType == other.runtimeType &&
          snake == other.snake &&
          food == other.food &&
          score == other.score &&
          highScore == other.highScore &&
          status == other.status &&
          boardWidth == other.boardWidth &&
          boardHeight == other.boardHeight &&
          gameSpeed == other.gameSpeed;

  @override
  int get hashCode =>
      snake.hashCode ^
      food.hashCode ^
      score.hashCode ^
      highScore.hashCode ^
      status.hashCode ^
      boardWidth.hashCode ^
      boardHeight.hashCode ^
      gameSpeed.hashCode;

  @override
  String toString() => 'GameState(snake: $snake, food: $food, score: $score, highScore: $highScore, status: $status)';
}

import 'dart:math';
import '../models/position.dart';
import '../models/food.dart';
import '../models/snake.dart';
import '../models/difficulty.dart';

/// Service class that handles core game logic operations
class GameService {
  final Random _random = Random();

  /// Generates a random food position that doesn't collide with the snake or blocked cells.
  /// Picks uniformly from all currently unoccupied cells to avoid bias or repeats.
  Food generateFood(Snake snake, int boardWidth, int boardHeight, {Set<Position> blocked = const {}}) {
    // Build a list of all available cells not occupied by the snake or blocks.
    final occupied = Set<Position>.from(snake.body)..addAll(blocked);
    final available = <Position>[];
    for (int y = 0; y < boardHeight; y++) {
      for (int x = 0; x < boardWidth; x++) {
        final cell = Position(x, y);
        if (!occupied.contains(cell)) {
          available.add(cell);
        }
      }
    }

    // Fallback: if no cells are available (rare end state), keep food at head.
    if (available.isEmpty) {
      return Food(position: snake.head);
    }

    final idx = _random.nextInt(available.length);
    return Food(position: available[idx]);
  }

  /// Calculates the score increase based on current snake length
  int calculateScoreIncrease(int currentScore, int snakeLength) {
    // Base score + bonus for longer snake
    return 10 + (snakeLength ~/ 5) * 5;
  }

  /// Calculates the game speed based on current score and difficulty
  int calculateGameSpeed(int score, int baseSpeed, Difficulty difficulty) {
    return difficulty.speedFor(score, baseSpeed);
  }

  /// Generate a set of obstacle cells that do not overlap with the snake (and optionally food)
  Set<Position> generateObstacles(
    Snake snake,
    int boardWidth,
    int boardHeight, {
    int count = 0,
    Food? avoidFood,
  }) {
    if (count <= 0) return <Position>{};

    final occupied = Set<Position>.from(snake.body);
    if (avoidFood != null) occupied.add(avoidFood.position);

    final allCells = <Position>[];
    for (int y = 0; y < boardHeight; y++) {
      for (int x = 0; x < boardWidth; x++) {
        final cell = Position(x, y);
        if (!occupied.contains(cell)) {
          allCells.add(cell);
        }
      }
    }

    // Shuffle and take first N
    allCells.shuffle(_random);
    final take = count.clamp(0, allCells.length);
    return allCells.take(take).toSet();
  }
}

import 'dart:math';
import '../models/position.dart';
import '../models/food.dart';
import '../models/snake.dart';

/// Service class that handles core game logic operations
class GameService {
  final Random _random = Random();

  /// Generates a random food position that doesn't collide with the snake.
  /// Picks uniformly from all currently unoccupied cells to avoid bias or repeats.
  Food generateFood(Snake snake, int boardWidth, int boardHeight) {
    // Build a list of all available cells not occupied by the snake.
    final occupied = Set<Position>.from(snake.body);
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

  /// Calculates the game speed based on current score
  int calculateGameSpeed(int score, int baseSpeed) {
    // Increase speed as score increases, but cap the minimum speed
    final speedIncrease = (score ~/ 50) * 10;
    final newSpeed = baseSpeed - speedIncrease;
    return newSpeed.clamp(50, baseSpeed); // Minimum 50ms, maximum baseSpeed
  }
}

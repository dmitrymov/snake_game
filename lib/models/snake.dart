import 'position.dart';
import 'direction.dart';

/// Represents the snake with its body segments
class Snake {
  final List<Position> body;
  final Direction direction;

  const Snake({
    required this.body,
    required this.direction,
  });

  /// Creates an initial snake at the center of the board
  factory Snake.initial({
    required int boardWidth,
    required int boardHeight,
    Direction direction = Direction.right,
  }) {
    final centerX = boardWidth ~/ 2;
    final centerY = boardHeight ~/ 2;
    
    return Snake(
      body: [
        Position(centerX, centerY),
        Position(centerX - 1, centerY),
        Position(centerX - 2, centerY),
      ],
      direction: direction,
    );
  }

  /// Gets the head position of the snake
  Position get head => body.first;

  /// Gets the tail position of the snake
  Position get tail => body.last;

  /// Returns the length of the snake
  int get length => body.length;

  /// Moves the snake in its current direction
  Snake move(int boardWidth, int boardHeight) {
    final newHead = head.move(direction).wrap(boardWidth, boardHeight);
    final newBody = [newHead, ...body.sublist(0, body.length - 1)];
    
    return copyWith(body: newBody);
  }

  /// Moves the snake and grows it (when eating food)
  Snake moveAndGrow(int boardWidth, int boardHeight) {
    final newHead = head.move(direction).wrap(boardWidth, boardHeight);
    final newBody = [newHead, ...body];
    
    return copyWith(body: newBody);
  }

  /// Changes the snake's direction if it's a valid move
  Snake changeDirection(Direction newDirection) {
    // Prevent the snake from reversing into itself
    if (newDirection == direction.opposite && body.length > 1) {
      return this;
    }
    
    return copyWith(direction: newDirection);
  }

  /// Checks if the snake has collided with itself
  bool get hasSelfCollision {
    final head = this.head;
    return body.skip(1).contains(head);
  }

  /// Checks if the snake's head is at the given position
  bool isAtPosition(Position position) {
    return body.contains(position);
  }

  /// Creates a copy of this snake with updated values
  Snake copyWith({
    List<Position>? body,
    Direction? direction,
  }) {
    return Snake(
      body: body ?? this.body,
      direction: direction ?? this.direction,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Snake &&
          runtimeType == other.runtimeType &&
          _listEquals(body, other.body) &&
          direction == other.direction;

  @override
  int get hashCode => body.hashCode ^ direction.hashCode;

  @override
  String toString() => 'Snake(body: $body, direction: $direction)';
}

/// Helper function to compare lists for equality
bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

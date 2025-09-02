/// Enum representing the four possible directions the snake can move
enum Direction {
  up,
  down,
  left,
  right,
}

/// Extension to add utility methods to Direction enum
extension DirectionExtension on Direction {
  /// Returns the opposite direction
  Direction get opposite {
    switch (this) {
      case Direction.up:
        return Direction.down;
      case Direction.down:
        return Direction.up;
      case Direction.left:
        return Direction.right;
      case Direction.right:
        return Direction.left;
    }
  }

  /// Returns true if the direction is horizontal (left or right)
  bool get isHorizontal => this == Direction.left || this == Direction.right;

  /// Returns true if the direction is vertical (up or down)
  bool get isVertical => this == Direction.up || this == Direction.down;
}

import 'direction.dart';

/// Represents a position on the game board with x and y coordinates
class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);

  /// Creates a new position moved in the specified direction
  Position move(Direction direction) {
    switch (direction) {
      case Direction.up:
        return Position(x, y - 1);
      case Direction.down:
        return Position(x, y + 1);
      case Direction.left:
        return Position(x - 1, y);
      case Direction.right:
        return Position(x + 1, y);
    }
  }

  /// Wraps the position within the given board dimensions
  Position wrap(int boardWidth, int boardHeight) {
    int wrappedX = x % boardWidth;
    int wrappedY = y % boardHeight;
    
    if (wrappedX < 0) wrappedX += boardWidth;
    if (wrappedY < 0) wrappedY += boardHeight;
    
    return Position(wrappedX, wrappedY);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'Position($x, $y)';
}

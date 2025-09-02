import 'position.dart';

/// Represents food items that the snake can eat
class Food {
  final Position position;
  final int points;

  const Food({
    required this.position,
    this.points = 1,
  });

  /// Creates a copy of this food with updated values
  Food copyWith({
    Position? position,
    int? points,
  }) {
    return Food(
      position: position ?? this.position,
      points: points ?? this.points,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Food &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          points == other.points;

  @override
  int get hashCode => position.hashCode ^ points.hashCode;

  @override
  String toString() => 'Food(position: $position, points: $points)';
}

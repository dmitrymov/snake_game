import 'position.dart';

/// Available kinds of food rendered with icons
enum FoodKind { strawberry, banana, apple, pineapple, bad }

/// Represents food items that the snake can eat
class Food {
  final Position position;
  final int points;
  final FoodKind kind;

  const Food({
    required this.position,
    this.points = 1,
    this.kind = FoodKind.apple,
  });

  /// Creates a copy of this food with updated values
  Food copyWith({
    Position? position,
    int? points,
    FoodKind? kind,
  }) {
    return Food(
      position: position ?? this.position,
      points: points ?? this.points,
      kind: kind ?? this.kind,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Food &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          points == other.points &&
          kind == other.kind;

  @override
  int get hashCode => position.hashCode ^ points.hashCode ^ kind.hashCode;

  @override
  String toString() => 'Food(position: $position, points: $points, kind: $kind)';
}

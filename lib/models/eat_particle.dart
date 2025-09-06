import 'position.dart';

/// Transient particle spawned when the snake eats food.
class EatParticle {
  final String id; // unique identifier for widget keys & removal
  final Position origin; // grid cell where it starts (food/head position)
  final double angle; // radians: direction to drift
  final bool isRed; // color variant (red/green)
  final int createdAtMs; // timestamp for animation progress

  const EatParticle({
    required this.id,
    required this.origin,
    required this.angle,
    required this.isRed,
    required this.createdAtMs,
  });
}


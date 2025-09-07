class ScorePopup {
  final String id;
  final int value;
  final int createdAtMs;
  final int durationMs;
  final int x;
  final int y;

  const ScorePopup({
    required this.id,
    required this.value,
    required this.createdAtMs,
    this.durationMs = 400,
    required this.x,
    required this.y,
  });
}

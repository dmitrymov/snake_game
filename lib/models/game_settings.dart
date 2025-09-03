/// Immutable model representing user-configurable game settings
class GameSettings {
  final int boardWidth;
  final int boardHeight;
  final int baseSpeed; // initial speed in ms between moves
  final bool wrapAround; // whether snake wraps at edges

  const GameSettings({
    required this.boardWidth,
    required this.boardHeight,
    required this.baseSpeed,
    required this.wrapAround,
  });

  factory GameSettings.defaults() => const GameSettings(
        boardWidth: 20,
        boardHeight: 20,
        baseSpeed: 200,
        wrapAround: true,
      );

  GameSettings copyWith({
    int? boardWidth,
    int? boardHeight,
    int? baseSpeed,
    bool? wrapAround,
  }) {
    return GameSettings(
      boardWidth: boardWidth ?? this.boardWidth,
      boardHeight: boardHeight ?? this.boardHeight,
      baseSpeed: baseSpeed ?? this.baseSpeed,
      wrapAround: wrapAround ?? this.wrapAround,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSettings &&
          runtimeType == other.runtimeType &&
          boardWidth == other.boardWidth &&
          boardHeight == other.boardHeight &&
          baseSpeed == other.baseSpeed &&
          wrapAround == other.wrapAround;

  @override
  int get hashCode =>
      boardWidth.hashCode ^ boardHeight.hashCode ^ baseSpeed.hashCode ^ wrapAround.hashCode;

  @override
  String toString() =>
      'GameSettings(width: $boardWidth, height: $boardHeight, baseSpeed: $baseSpeed, wrap: $wrapAround)';
}


/// Immutable model representing user-configurable game settings
import 'difficulty.dart';
import 'app_theme_mode.dart';

class GameSettings {
  final int boardWidth;
  final int boardHeight;
  final int baseSpeed; // initial speed in ms between moves
  final bool wrapAround; // whether snake wraps at edges
  final Difficulty difficulty; // controls speed curve and obstacle density
  final AppThemeMode themeMode; // light/dark/system
  final bool soundEnabled; // whether sfx/haptics are enabled

  const GameSettings({
    required this.boardWidth,
    required this.boardHeight,
    required this.baseSpeed,
    required this.wrapAround,
    required this.difficulty,
    required this.themeMode,
    required this.soundEnabled,
  });

  factory GameSettings.defaults() => GameSettings(
        boardWidth: 20,
        boardHeight: 20,
        baseSpeed: Difficulty.normal.suggestedBaseSpeed,
        wrapAround: true,
        difficulty: Difficulty.normal,
        themeMode: AppThemeMode.system,
        soundEnabled: true,
      );

  GameSettings copyWith({
    int? boardWidth,
    int? boardHeight,
    int? baseSpeed,
    bool? wrapAround,
    Difficulty? difficulty,
    AppThemeMode? themeMode,
    bool? soundEnabled,
  }) {
    return GameSettings(
      boardWidth: boardWidth ?? this.boardWidth,
      boardHeight: boardHeight ?? this.boardHeight,
      baseSpeed: baseSpeed ?? this.baseSpeed,
      wrapAround: wrapAround ?? this.wrapAround,
      difficulty: difficulty ?? this.difficulty,
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
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
          wrapAround == other.wrapAround &&
          difficulty == other.difficulty &&
          themeMode == other.themeMode &&
          soundEnabled == other.soundEnabled;

  @override
  int get hashCode =>
      boardWidth.hashCode ^ boardHeight.hashCode ^ baseSpeed.hashCode ^ wrapAround.hashCode ^ difficulty.hashCode ^ themeMode.hashCode ^ soundEnabled.hashCode;

  @override
  String toString() =>
      'GameSettings(width: $boardWidth, height: $boardHeight, baseSpeed: $baseSpeed, wrap: $wrapAround, difficulty: $difficulty, theme: $themeMode, sound: $soundEnabled)';
}


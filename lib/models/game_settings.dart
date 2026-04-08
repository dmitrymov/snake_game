import 'difficulty.dart';
import 'app_theme_mode.dart';

/// Immutable model representing user-configurable game settings
class GameSettings {
  final int boardWidth;
  final int boardHeight;
  final int baseSpeed; // initial speed in ms between moves
  final bool wrapAround; // whether snake wraps at edges
  final Difficulty difficulty; // controls speed curve and obstacle density
  final AppThemeMode themeMode; // light/dark/system
  final bool soundEnabled; // whether sfx are enabled
  final bool hapticsEnabled; // whether haptic feedback is enabled
  final bool badFoodEnabled; // whether to spawn negative food

  const GameSettings({
    required this.boardWidth,
    required this.boardHeight,
    required this.baseSpeed,
    required this.wrapAround,
    required this.difficulty,
    required this.themeMode,
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.badFoodEnabled,
  });

  factory GameSettings.defaults() => GameSettings(
        boardWidth: 20,
        boardHeight: 20,
        baseSpeed: Difficulty.normal.suggestedBaseSpeed,
        wrapAround: true,
        difficulty: Difficulty.normal,
        themeMode: AppThemeMode.system,
        soundEnabled: true,
        hapticsEnabled: true,
        badFoodEnabled: true,
      );

  GameSettings copyWith({
    int? boardWidth,
    int? boardHeight,
    int? baseSpeed,
    bool? wrapAround,
    Difficulty? difficulty,
    AppThemeMode? themeMode,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? badFoodEnabled,
  }) {
    return GameSettings(
      boardWidth: boardWidth ?? this.boardWidth,
      boardHeight: boardHeight ?? this.boardHeight,
      baseSpeed: baseSpeed ?? this.baseSpeed,
      wrapAround: wrapAround ?? this.wrapAround,
      difficulty: difficulty ?? this.difficulty,
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      badFoodEnabled: badFoodEnabled ?? this.badFoodEnabled,
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
          soundEnabled == other.soundEnabled &&
          hapticsEnabled == other.hapticsEnabled &&
          badFoodEnabled == other.badFoodEnabled;

  @override
  int get hashCode =>
      boardWidth.hashCode ^
      boardHeight.hashCode ^
      baseSpeed.hashCode ^
      wrapAround.hashCode ^
      difficulty.hashCode ^
      themeMode.hashCode ^
      soundEnabled.hashCode ^
      hapticsEnabled.hashCode ^
      badFoodEnabled.hashCode;

  @override
  String toString() =>
      'GameSettings(width: $boardWidth, height: $boardHeight, baseSpeed: $baseSpeed, wrap: $wrapAround, difficulty: $difficulty, theme: $themeMode, sound: $soundEnabled, haptics: $hapticsEnabled, badFood: $badFoodEnabled)';
}


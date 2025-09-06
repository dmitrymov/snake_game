import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_settings.dart';
import '../models/difficulty.dart';

import '../models/app_theme_mode.dart';
class SettingsService {
  static const _kBoardWidth = 'board_width';
  static const _kBoardHeight = 'board_height';
  static const _kBaseSpeed = 'base_speed';
  static const _kWrapAround = 'wrap_around';
  static const _kDifficulty = 'difficulty';
  static const _kThemeMode = 'theme_mode';
  // Deprecated key kept for backward-compat read
  static const _kDarkMode = 'dark_mode';
  static const _kSoundEnabled = 'sound_enabled';

  Future<GameSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final difficultyStr = prefs.getString(_kDifficulty) ?? Difficulty.normal.asString;
    final difficulty = DifficultyConfig.fromString(difficultyStr);

    // Theme: prefer new key; else fallback to legacy dark_mode
    final themeStr = prefs.getString(_kThemeMode) ?? ((prefs.getBool(_kDarkMode) ?? false) ? 'dark' : 'light');
    final themeMode = AppThemeModeX.fromString(themeStr);

    return GameSettings(
      boardWidth: prefs.getInt(_kBoardWidth) ?? 20,
      boardHeight: prefs.getInt(_kBoardHeight) ?? 20,
      baseSpeed: prefs.getInt(_kBaseSpeed) ?? difficulty.suggestedBaseSpeed,
      wrapAround: prefs.getBool(_kWrapAround) ?? true,
      difficulty: difficulty,
      themeMode: themeMode,
      soundEnabled: prefs.getBool(_kSoundEnabled) ?? true,
    );
  }

  Future<void> saveSettings(GameSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kBoardWidth, settings.boardWidth);
    await prefs.setInt(_kBoardHeight, settings.boardHeight);
    await prefs.setInt(_kBaseSpeed, settings.baseSpeed);
    await prefs.setBool(_kWrapAround, settings.wrapAround);
    await prefs.setString(_kDifficulty, settings.difficulty.asString);
    await prefs.setString(_kThemeMode, settings.themeMode.asString);
    await prefs.setBool(_kSoundEnabled, settings.soundEnabled);
  }
}


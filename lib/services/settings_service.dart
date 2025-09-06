import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_settings.dart';
import '../models/difficulty.dart';

class SettingsService {
  static const _kBoardWidth = 'board_width';
  static const _kBoardHeight = 'board_height';
  static const _kBaseSpeed = 'base_speed';
  static const _kWrapAround = 'wrap_around';
  static const _kDifficulty = 'difficulty';

  Future<GameSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final difficultyStr = prefs.getString(_kDifficulty) ?? Difficulty.normal.asString;
    final difficulty = DifficultyConfig.fromString(difficultyStr);
    return GameSettings(
      boardWidth: prefs.getInt(_kBoardWidth) ?? 20,
      boardHeight: prefs.getInt(_kBoardHeight) ?? 20,
      baseSpeed: prefs.getInt(_kBaseSpeed) ?? difficulty.suggestedBaseSpeed,
      wrapAround: prefs.getBool(_kWrapAround) ?? true,
      difficulty: difficulty,
    );
  }

  Future<void> saveSettings(GameSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kBoardWidth, settings.boardWidth);
    await prefs.setInt(_kBoardHeight, settings.boardHeight);
    await prefs.setInt(_kBaseSpeed, settings.baseSpeed);
    await prefs.setBool(_kWrapAround, settings.wrapAround);
    await prefs.setString(_kDifficulty, settings.difficulty.asString);
  }
}


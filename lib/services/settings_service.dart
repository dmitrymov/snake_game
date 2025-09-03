import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_settings.dart';

class SettingsService {
  static const _kBoardWidth = 'board_width';
  static const _kBoardHeight = 'board_height';
  static const _kBaseSpeed = 'base_speed';
  static const _kWrapAround = 'wrap_around';

  Future<GameSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return GameSettings(
      boardWidth: prefs.getInt(_kBoardWidth) ?? 20,
      boardHeight: prefs.getInt(_kBoardHeight) ?? 20,
      baseSpeed: prefs.getInt(_kBaseSpeed) ?? 200,
      wrapAround: prefs.getBool(_kWrapAround) ?? true,
    );
  }

  Future<void> saveSettings(GameSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kBoardWidth, settings.boardWidth);
    await prefs.setInt(_kBoardHeight, settings.boardHeight);
    await prefs.setInt(_kBaseSpeed, settings.baseSpeed);
    await prefs.setBool(_kWrapAround, settings.wrapAround);
  }
}


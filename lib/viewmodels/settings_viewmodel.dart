import 'package:flutter/foundation.dart';
import '../models/game_settings.dart';
import '../models/difficulty.dart';
import '../services/settings_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  GameSettings _settings = GameSettings.defaults();
  bool _loading = false;

  GameSettings get settings => _settings;
  bool get isLoading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _settings = await _service.getSettings();
    _loading = false;
    notifyListeners();
  }

  void setBoardWidth(int value) {
    final v = value.clamp(10, 40);
    _settings = _settings.copyWith(boardWidth: v);
    notifyListeners();
  }

  void setBoardHeight(int value) {
    final v = value.clamp(10, 40);
    _settings = _settings.copyWith(boardHeight: v);
    notifyListeners();
  }

  void setBaseSpeed(int value) {
    final v = value.clamp(80, 400);
    _settings = _settings.copyWith(baseSpeed: v);
    notifyListeners();
  }

  void setWrapAround(bool value) {
    _settings = _settings.copyWith(wrapAround: value);
    notifyListeners();
  }

  void setDifficulty(Difficulty value) {
    // When changing difficulty, optionally update base speed to the suggested value
    // but keep user override if they changed base speed manually afterwards.
    _settings = _settings.copyWith(
      difficulty: value,
      // If current base speed equals previous suggestion, snap to new suggestion.
      baseSpeed: _settings.baseSpeed == _settings.difficulty.suggestedBaseSpeed
          ? value.suggestedBaseSpeed
          : _settings.baseSpeed,
    );
    notifyListeners();
  }

  Future<void> save() async {
    await _service.saveSettings(_settings);
  }
}


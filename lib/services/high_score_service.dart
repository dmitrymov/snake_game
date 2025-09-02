import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for persisting and retrieving the game's high score
class HighScoreService {
  static const String _keyHighScore = 'high_score';

  Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyHighScore) ?? 0;
    
  }

  Future<void> setHighScore(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHighScore, value);
  }
}


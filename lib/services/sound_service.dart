import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Lightweight sound service with safe fallbacks when assets are missing.
class SoundService {
  final AudioPlayer _eat = AudioPlayer();
  final AudioPlayer _crash = AudioPlayer();

  Future<void> playEat() async {
    try {
      await _eat.stop();
      // Attempt to play from assets if provided by the project
      await _eat.play(AssetSource('sfx/eat.wav'));
      await HapticFeedback.lightImpact();
    } catch (_) {
      // Fallback to system sound if assets aren't available
      try {
        await SystemSound.play(SystemSoundType.click);
        await HapticFeedback.lightImpact();
      } catch (_) {}
    }
  }

  Future<void> playCrash() async {
    try {
      await _crash.stop();
      await _crash.play(AssetSource('sfx/crash.wav'));
      await HapticFeedback.heavyImpact();
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.alert);
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    try {
      await _eat.dispose();
      await _crash.dispose();
    } catch (_) {}
  }
}

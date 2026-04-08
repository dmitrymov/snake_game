import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Lightweight sound service with safe fallbacks when assets are missing.
class SoundService {
  final AudioPlayer _eat = AudioPlayer();
  final AudioPlayer _crash = AudioPlayer();
  bool _enabled = true;
  bool _hapticsEnabled = true;

  void setEnabled(bool value) {
    _enabled = value;
  }

  void setHapticsEnabled(bool value) {
    _hapticsEnabled = value;
  }

  Future<void> _hapticLight() async {
    if (!_hapticsEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> _hapticHeavy() async {
    if (!_hapticsEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

   Future<void> playEat() async {
    if (!_enabled) return;
    try {
      await _eat.stop();
      // Attempt to play from assets if provided by the project
      await _eat.play(AssetSource('sfx/eat.wav'));
      await _hapticLight();
    } catch (_) {
      // Fallback to system sound if assets aren't available
      try {
        await SystemSound.play(SystemSoundType.click);
        await _hapticLight();
      } catch (_) {}
    }
  }

  Future<void> playCrash() async {
    if (!_enabled) return;
    try {
      await _crash.stop();
      await _crash.play(AssetSource('sfx/crash.wav'));
      await _hapticHeavy();
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.alert);
        await _hapticHeavy();
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

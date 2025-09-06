/// Difficulty presets that control speed ramping and obstacle density
enum Difficulty { easy, normal, hard }

extension DifficultyConfig on Difficulty {
  /// Default base speed suggestion (ms between ticks)
  int get suggestedBaseSpeed {
    switch (this) {
      case Difficulty.easy:
        return 240;
      case Difficulty.normal:
        return 200;
      case Difficulty.hard:
        return 160;
    }
  }

  /// Minimum speed clamp for this difficulty
  int get minSpeed {
    switch (this) {
      case Difficulty.easy:
        return 100;
      case Difficulty.normal:
        return 70;
      case Difficulty.hard:
        return 50;
    }
  }

  /// How many score points are needed to reduce speed by [speedStep]
  int get scorePerStep {
    switch (this) {
      case Difficulty.easy:
        return 80;
      case Difficulty.normal:
        return 50;
      case Difficulty.hard:
        return 30;
    }
  }

  /// How much to reduce the tick interval (ms) each step
  int get speedStep {
    switch (this) {
      case Difficulty.easy:
        return 8;
      case Difficulty.normal:
        return 10;
      case Difficulty.hard:
        return 12;
    }
  }

  /// Compute the current game speed based on score and base speed
  int speedFor(int score, int baseSpeed) {
    final steps = (score ~/ scorePerStep);
    final newSpeed = baseSpeed - steps * speedStep;
    final clamped = newSpeed.clamp(minSpeed, baseSpeed);
    return clamped;
  }

  /// Return a recommended fraction of the board to fill with obstacles
  /// Example: 0.0 (easy), 5% (normal), 8% (hard)
  double get obstacleDensity {
    switch (this) {
      case Difficulty.easy:
        return 0.0;
      case Difficulty.normal:
        return 0.01;
      case Difficulty.hard:
        return 0.05;
    }
  }

  static Difficulty fromString(String value) {
    switch (value) {
      case 'easy':
        return Difficulty.easy;
      case 'hard':
        return Difficulty.hard;
      case 'normal':
      default:
        return Difficulty.normal;
    }
  }

  String get asString {
    switch (this) {
      case Difficulty.easy:
        return 'easy';
      case Difficulty.normal:
        return 'normal';
      case Difficulty.hard:
        return 'hard';
    }
  }
}


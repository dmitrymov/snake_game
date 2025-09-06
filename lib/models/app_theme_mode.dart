/// App theme mode options used in settings
enum AppThemeMode { system, light, dark }

extension AppThemeModeX on AppThemeMode {
  static AppThemeMode fromString(String value) {
    switch (value) {
      case 'system':
        return AppThemeMode.system;
      case 'dark':
        return AppThemeMode.dark;
      case 'light':
      default:
        return AppThemeMode.light;
    }
  }

  String get asString {
    switch (this) {
      case AppThemeMode.system:
        return 'system';
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
    }
  }
}


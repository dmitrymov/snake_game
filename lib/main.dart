import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/game_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'views/game_screen.dart';
import 'models/app_theme_mode.dart';
import 'package:dynamic_color/dynamic_color.dart';

void main() {
  runApp(const SnakeGameApp());
}

class SnakeGameApp extends StatelessWidget {
  const SnakeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsViewModel()..load()),
        ChangeNotifierProvider(create: (_) => GameViewModel()),
      ],
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          return Consumer<SettingsViewModel>(
            builder: (context, settingsVm, _) {
              // Build ColorSchemes with dynamic color on Android 12+, fallback to seed.
              final ColorScheme lightScheme = (lightDynamic?.harmonized()) ??
                  ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light);
              final ColorScheme darkScheme = (darkDynamic?.harmonized()) ??
                  ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark);

              final lightTheme = ThemeData(
                useMaterial3: true,
                colorScheme: lightScheme,
                appBarTheme: const AppBarTheme(
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                ),
              );

              final darkTheme = ThemeData(
                useMaterial3: true,
                colorScheme: darkScheme,
                appBarTheme: const AppBarTheme(
                  elevation: 3,
                  scrolledUnderElevation: 3,
                  surfaceTintColor: Colors.transparent,
                ),
              );

              return MaterialApp(
                title: 'Snake Game',
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: () {
                  switch (settingsVm.settings.themeMode) {
                    case AppThemeMode.system:
                      return ThemeMode.system;
                    case AppThemeMode.light:
                      return ThemeMode.light;
                    case AppThemeMode.dark:
                      return ThemeMode.dark;
                  }
                }(),
                home: const GameScreen(),
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}

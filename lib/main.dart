import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/game_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'views/game_screen.dart';
import 'models/app_theme_mode.dart';

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
      child: Consumer<SettingsViewModel>(
        builder: (context, settingsVm, _) {
          final lightTheme = ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
            brightness: Brightness.light,
          );
          final darkTheme = ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
            useMaterial3: true,
            brightness: Brightness.dark,
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
      ),
    );
  }
}

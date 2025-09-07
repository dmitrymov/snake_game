import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/game_viewmodel.dart';
import '../models/difficulty.dart';
import '../models/app_theme_mode.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = vm.settings;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Theme mode selector
              DropdownButtonFormField<AppThemeMode>(
                decoration: const InputDecoration(
                  labelText: 'Theme',
                  border: OutlineInputBorder(),
                ),
                value: s.themeMode,
                items: const [
                  DropdownMenuItem(value: AppThemeMode.system, child: Text('System')),
                  DropdownMenuItem(value: AppThemeMode.light, child: Text('Light')),
                  DropdownMenuItem(value: AppThemeMode.dark, child: Text('Dark')),
                ],
                onChanged: (value) {
                  if (value != null) vm.setThemeMode(value);
                },
              ),
              const SizedBox(height: 8),

              // Sound effects toggle
              SwitchListTile(
                title: const Text('Sound effects'),
                value: s.soundEnabled,
                onChanged: vm.setSoundEnabled,
              ),
              const SizedBox(height: 8),

              // Bad food toggle
              SwitchListTile(
                title: const Text('Bad food (can shrink snake)'),
                value: s.badFoodEnabled,
                onChanged: vm.setBadFoodEnabled,
              ),
              const SizedBox(height: 16),

              // Difficulty selector
              DropdownButtonFormField<Difficulty>(
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  border: OutlineInputBorder(),
                ),
                value: s.difficulty,
                items: const [
                  DropdownMenuItem(value: Difficulty.easy, child: Text('Easy')),
                  DropdownMenuItem(value: Difficulty.normal, child: Text('Normal')),
                  DropdownMenuItem(value: Difficulty.hard, child: Text('Hard')),
                ],
                onChanged: (value) {
                  if (value != null) vm.setDifficulty(value);
                },
              ),
              const SizedBox(height: 16),

              Text('Board Width: ${s.boardWidth}'),
              Slider(
                min: 10,
                max: 40,
                divisions: 30,
                value: s.boardWidth.toDouble(),
                label: s.boardWidth.toString(),
                onChanged: (v) => vm.setBoardWidth(v.round()),
              ),
              const SizedBox(height: 8),
              Text('Board Height: ${s.boardHeight}'),
              Slider(
                min: 10,
                max: 40,
                divisions: 30,
                value: s.boardHeight.toDouble(),
                label: s.boardHeight.toString(),
                onChanged: (v) => vm.setBoardHeight(v.round()),
              ),
              const SizedBox(height: 8),
              Text('Base Speed (ms): ${s.baseSpeed}'),
              Slider(
                min: 80,
                max: 400,
                divisions: 32,
                value: s.baseSpeed.toDouble(),
                label: s.baseSpeed.toString(),
                onChanged: (v) => vm.setBaseSpeed(v.round()),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Wrap around edges'),
                value: s.wrapAround,
                onChanged: vm.setWrapAround,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await vm.save();
                      if (!context.mounted) return;
                      // Apply settings to game
                      final gameVm = context.read<GameViewModel>();
                      await gameVm.applySettings(vm.settings);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    style: vm.isDirty
                        ? ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          )
                        : null,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}


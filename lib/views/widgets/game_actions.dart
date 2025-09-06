import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/game_viewmodel.dart';

/// Widget that provides action buttons for the snake game
class GameActions extends StatelessWidget {
  const GameActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameViewModel>(
      builder: (context, gameViewModel, child) {
        final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Start/Resume button (hidden on mobile; game starts on tap)
              if (!isMobile && (gameViewModel.isReady || gameViewModel.isPaused))
                _buildActionButton(
                  label: gameViewModel.isReady ? 'Start Game' : 'Resume',
                  icon: Icons.play_arrow,
                  color: Colors.green,
                  onPressed: gameViewModel.isReady
                      ? gameViewModel.startNewGame
                      : gameViewModel.resumeGame,
                ),

              // New Game button (when game over)
              if (gameViewModel.isGameOver)
                _buildActionButton(
                  label: 'New Game',
                  icon: Icons.play_circle_filled,
                  color: Colors.green,
                  onPressed: gameViewModel.startNewGame,
                ),
            ],
          ),
        );
      },
    );
  }

  /// Builds an action button
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

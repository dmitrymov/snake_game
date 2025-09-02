import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/game_viewmodel.dart';

/// Widget that provides action buttons for the snake game
class GameActions extends StatelessWidget {
  const GameActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameViewModel>(
      builder: (context, gameViewModel, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Start/Resume button
              if (gameViewModel.isReady || gameViewModel.isPaused)
                _buildActionButton(
                  label: gameViewModel.isReady ? 'Start Game' : 'Resume',
                  icon: Icons.play_arrow,
                  color: Colors.green,
                  onPressed: gameViewModel.isReady
                      ? gameViewModel.startNewGame
                      : gameViewModel.resumeGame,
                ),

              // Pause button
              if (gameViewModel.isPlaying)
                _buildActionButton(
                  label: 'Pause',
                  icon: Icons.pause,
                  color: Colors.orange,
                  onPressed: gameViewModel.pauseGame,
                ),

              // Reset button
              if (!gameViewModel.isReady)
                _buildActionButton(
                  label: 'Reset',
                  icon: Icons.refresh,
                  color: Colors.blue,
                  onPressed: gameViewModel.resetGame,
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

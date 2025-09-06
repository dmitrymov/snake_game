import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/game_viewmodel.dart';

/// Widget that displays game information like score and status
class GameInfo extends StatelessWidget {
  const GameInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameViewModel>(
      builder: (context, gameViewModel, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(
                label: 'Score',
                value: gameViewModel.score.toString(),
                icon: Icons.star,
                color: Colors.orange,
              ),
              _buildInfoItem(
                label: 'High',
                value: gameViewModel.highScore.toString(),
                icon: Icons.emoji_events,
                color: Colors.purple,
              ),
              _buildInfoItem(
                label: 'Length',
                value: gameViewModel.snakeLength.toString(),
                icon: Icons.straighten,
                color: Colors.green,
              ),
              _buildInfoItem(
                label: 'Status',
                value: _getStatusText(gameViewModel),
                icon: _getStatusIcon(gameViewModel),
                color: _getStatusColor(gameViewModel),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds an individual info item
  Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        // Animate score value changes for feedback
        if (label == 'Score')
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Text(
              value,
              key: ValueKey(value),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
      ],
    );
  }

  /// Gets the status text for display
  String _getStatusText(GameViewModel gameViewModel) {
    if (gameViewModel.isReady) return 'Ready';
    if (gameViewModel.isPlaying) return 'Playing';
    if (gameViewModel.isPaused) return 'Paused';
    if (gameViewModel.isGameOver) return 'Game Over';
    return 'Unknown';
  }

  /// Gets the appropriate icon for the current status
  IconData _getStatusIcon(GameViewModel gameViewModel) {
    if (gameViewModel.isReady) return Icons.play_circle_outline;
    if (gameViewModel.isPlaying) return Icons.play_arrow;
    if (gameViewModel.isPaused) return Icons.pause;
    if (gameViewModel.isGameOver) return Icons.stop;
    return Icons.help;
  }

  /// Gets the appropriate color for the current status
  Color _getStatusColor(GameViewModel gameViewModel) {
    if (gameViewModel.isReady) return Colors.blue;
    if (gameViewModel.isPlaying) return Colors.green;
    if (gameViewModel.isPaused) return Colors.orange;
    if (gameViewModel.isGameOver) return Colors.red;
    return Colors.grey;
  }
}

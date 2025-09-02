import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/game_viewmodel.dart';
import '../../models/direction.dart';

/// Widget that provides directional controls for the snake game
class GameControls extends StatelessWidget {
  const GameControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameViewModel>(
      builder: (context, gameViewModel, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Up button
              _buildDirectionButton(
                icon: Icons.keyboard_arrow_up,
                direction: Direction.up,
                onPressed: () => gameViewModel.changeDirection(Direction.up),
              ),
              
              // Left and Right buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDirectionButton(
                    icon: Icons.keyboard_arrow_left,
                    direction: Direction.left,
                    onPressed: () => gameViewModel.changeDirection(Direction.left),
                  ),
                  const SizedBox(width: 60), // Space for down button
                  _buildDirectionButton(
                    icon: Icons.keyboard_arrow_right,
                    direction: Direction.right,
                    onPressed: () => gameViewModel.changeDirection(Direction.right),
                  ),
                ],
              ),
              
              // Down button
              _buildDirectionButton(
                icon: Icons.keyboard_arrow_down,
                direction: Direction.down,
                onPressed: () => gameViewModel.changeDirection(Direction.down),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds a directional control button
  Widget _buildDirectionButton({
    required IconData icon,
    required Direction direction,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 60,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Icon(
          icon,
          size: 30,
        ),
      ),
    );
  }
}

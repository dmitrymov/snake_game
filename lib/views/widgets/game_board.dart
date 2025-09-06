import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/game_viewmodel.dart';
import '../../models/position.dart';

/// Widget that renders the Snake game board
class GameBoard extends StatelessWidget {
  const GameBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameViewModel>(
      builder: (context, gameViewModel, child) {
        final gameState = gameViewModel.gameState;
        final cellSize = _calculateCellSize(context, gameState.boardWidth, gameState.boardHeight);

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 2),
            color: Colors.black,
          ),
          child: SizedBox(
            width: cellSize * gameState.boardWidth,
            height: cellSize * gameState.boardHeight,
            child: Stack(
              children: [
                // Render obstacles first (under snake)
                ...gameState.obstacles.map((pos) => _buildObstacle(pos, cellSize)),

                // Render snake body
                ...gameState.snake.body.map((position) => _buildSnakeSegment(
                      position,
                      cellSize,
                      isHead: position == gameState.snake.head,
                    )),

                // Render food
                if (gameState.food != null)
                  _buildFood(gameState.food!.position, cellSize),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Calculates the appropriate cell size based on screen size
  double _calculateCellSize(BuildContext context, int boardWidth, int boardHeight) {
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width * 0.9;
    final maxHeight = screenSize.height * 0.6;

    final cellWidth = maxWidth / boardWidth;
    final cellHeight = maxHeight / boardHeight;

    return (cellWidth < cellHeight ? cellWidth : cellHeight).floorToDouble();
  }

  /// Builds an obstacle cell
  Widget _buildObstacle(Position position, double cellSize) {
    return Positioned(
      left: position.x * cellSize,
      top: position.y * cellSize,
      child: Container(
        width: cellSize,
        height: cellSize,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.grey[600]!),
        ),
      ),
    );
  }

  /// Builds a snake segment widget
  Widget _buildSnakeSegment(Position position, double cellSize, {required bool isHead}) {
    return Positioned(
      left: position.x * cellSize,
      top: position.y * cellSize,
      child: Container(
        width: cellSize,
        height: cellSize,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isHead ? Colors.lightGreen : Colors.green,
          borderRadius: BorderRadius.circular(4),
          border: isHead ? Border.all(color: Colors.white, width: 1) : null,
        ),
      ),
    );
  }

  /// Builds a food widget with spawn animation
  Widget _buildFood(Position position, double cellSize) {
    return Positioned(
      left: position.x * cellSize,
      top: position.y * cellSize,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('food_${position.x}_${position.y}'),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Container(
          width: cellSize,
          height: cellSize,
          margin: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.redAccent, blurRadius: 6, spreadRadius: 0.5),
            ],
          ),
        ),
      ),
    );
  }
}

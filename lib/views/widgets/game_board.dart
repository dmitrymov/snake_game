import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flame/game.dart';
import '../../viewmodels/game_viewmodel.dart';
import '../../flame/snake_flame_game.dart';

/// Widget that renders the Snake game board using Flame for high-performance drawing
class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  SnakeFlameGame? _game;

  @override
  void initState() {
    super.initState();
    final vm = Provider.of<GameViewModel>(context, listen: false);
    _game = SnakeFlameGame(vm);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameViewModel>(
      builder: (context, vm, _) {
        final s = vm.gameState;
        final cellSize = _calculateCellSize(context, s.boardWidth, s.boardHeight);
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 2),
            color: Colors.black,
          ),
          child: SizedBox(
            width: cellSize * s.boardWidth,
            height: cellSize * s.boardHeight,
            child: GameWidget(game: _game!),
          ),
        );
      },
    );
  }

  /// Calculates the appropriate cell size based on screen size
  double _calculateCellSize(BuildContext context, int boardWidth, int boardHeight) {
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width * 0.95;
    final maxHeight = screenSize.height * 0.88;

    final cellWidth = maxWidth / boardWidth;
    final cellHeight = maxHeight / boardHeight;

    return (cellWidth < cellHeight ? cellWidth : cellHeight).floorToDouble();
  }
}

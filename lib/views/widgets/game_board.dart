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
        return Container(
          decoration: BoxDecoration(
            // Full-screen game area background
            color: Colors.black,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: GameWidget(game: _game!),
              );
            },
          ),
        );
      },
    );
  }
}

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
  bool _sizedForThisReady = false;
  bool _wasReady = false;
  double? _lastSizedWidth;
  double? _lastSizedHeight;

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
          color: Colors.transparent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Size the board grid once per Ready state, right before starting a game.
              return Consumer<GameViewModel>(
                builder: (context, vm, _) {
                  // Reset sizing flag when we re-enter Ready state
                  if (vm.isReady && !_wasReady) {
                    _sizedForThisReady = false;
                    _lastSizedWidth = null;
                    _lastSizedHeight = null;
                  }
                  _wasReady = vm.isReady;

                  if (vm.isReady) {
                    final cw = constraints.maxWidth;
                    final ch = constraints.maxHeight;
                    final constraintsChanged = (_lastSizedWidth != cw) || (_lastSizedHeight != ch);
                    if (!_sizedForThisReady || constraintsChanged) {
                      final desiredCellPx = 28.0;
                      final wCells = (cw / desiredCellPx).floor().clamp(6, 80).toInt();
                      final hCells = (ch / desiredCellPx).floor().clamp(6, 80).toInt();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        vm.updateBoardSizeIfNeeded(wCells, hCells);
                      });
                      _sizedForThisReady = true;
                      _lastSizedWidth = cw;
                      _lastSizedHeight = ch;
                    }
                  }

                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: GameWidget(
                      key: ValueKey('game-${constraints.maxWidth}x${constraints.maxHeight}-${Theme.of(context).brightness}-${MediaQuery.of(context).orientation}'),
                      game: _game!,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

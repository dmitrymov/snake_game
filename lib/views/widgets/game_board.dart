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
  Brightness? _lastBrightness;

  @override
  void initState() {
    super.initState();
    final vm = Provider.of<GameViewModel>(context, listen: false);
    _game = SnakeFlameGame(vm);
  }

  @override
  Widget build(BuildContext context) {
    // Only watch the "ready" flag; avoid rebuilding the board every tick.
    final isReady = context.select<GameViewModel, bool>((vm) => vm.isReady);

    return Container(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Reset sizing flag when we re-enter Ready state.
          if (isReady && !_wasReady) {
            _sizedForThisReady = false;
            _lastSizedWidth = null;
            _lastSizedHeight = null;
          }
          _wasReady = isReady;

          if (isReady) {
            final cw = constraints.maxWidth;
            final ch = constraints.maxHeight;
            final constraintsChanged = (_lastSizedWidth != cw) || (_lastSizedHeight != ch);
            if (!_sizedForThisReady || constraintsChanged) {
              final desiredCellPx = 28.0;
              final wCells = (cw / desiredCellPx).floor().clamp(6, 80).toInt();
              final hCells = (ch / desiredCellPx).floor().clamp(6, 80).toInt();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                context.read<GameViewModel>().updateBoardSizeIfNeeded(wCells, hCells);
              });
              _sizedForThisReady = true;
              _lastSizedWidth = cw;
              _lastSizedHeight = ch;
            }
          }

          // Recreate the widget only when brightness changes (prevents theme artifacts
          // while avoiding rebuilds on every game tick).
          final brightness = Theme.of(context).brightness;
          final brightnessChanged = _lastBrightness != brightness;
          _lastBrightness = brightness;

          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: GameWidget(
              key: brightnessChanged
                  ? ValueKey('game-${constraints.maxWidth}x${constraints.maxHeight}-$brightness-${MediaQuery.of(context).orientation}')
                  : null,
              game: _game!,
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../viewmodels/game_viewmodel.dart';
import '../models/direction.dart';
import 'widgets/game_board.dart';
import 'widgets/game_info.dart';
import 'widgets/game_actions.dart';
import 'widgets/game_controls.dart';
import 'widgets/game_over_overlay.dart';
import 'settings_screen.dart';

/// Main game screen that orchestrates all game components
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final FocusNode _focusNode = FocusNode();

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    // Request focus for keyboard input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const _ToolbarStats(),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Dynamic pause/resume and reset controls in the toolbar
          Consumer<GameViewModel>(
            builder: (context, vm, _) {
              final buttons = <Widget>[];
              final isDark = Theme.of(context).brightness == Brightness.dark;

              Widget actionBtn({required IconData icon, required String tip, required VoidCallback onPressed, bool filledTonal = false}) {
                final btn = isDark && filledTonal
                    ? IconButton.filledTonal(onPressed: onPressed, tooltip: tip, icon: Icon(icon))
                    : IconButton(onPressed: onPressed, tooltip: tip, icon: Icon(icon));
                return _Bouncy(child: btn);
              }

              if (vm.isPlaying) {
                buttons.add(actionBtn(icon: Icons.pause, tip: 'Pause', onPressed: vm.pauseGame, filledTonal: true));
              } else if (vm.isPaused) {
                buttons.add(actionBtn(icon: Icons.play_arrow, tip: 'Resume', onPressed: vm.resumeGame, filledTonal: true));
              }

              if (!vm.isReady) {
                buttons.add(actionBtn(icon: Icons.refresh, tip: 'Reset', onPressed: vm.resetGame, filledTonal: true));
              }

              return Row(mainAxisSize: MainAxisSize.min, children: buttons);
            },
          ),

          // Settings action (kept standard)
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Focus(
            focusNode: _focusNode,
            onKeyEvent: _handleKeyEvent,
            child: GestureDetector(
              onTap: _handleTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    

                    
                    // Game board (fills available space)
                    Expanded(
                      child: _isAndroid
                          ? GestureDetector(
                              onPanEnd: _handleSwipe,
                              child: const GameBoard(),
                            )
                          : const GameBoard(),
                    ),

                    const SizedBox(height: 12),

                    // Game action buttons (below the board)
                    const GameActions(),

                    const SizedBox(height: 8),

                    // Game controls (hidden on Android; use swipe gestures instead)
                    if (!_isAndroid) const GameControls(),


                    // Instructions
                    // Container(
                    //   padding: const EdgeInsets.all(12),
                    //   decoration: BoxDecoration(
                    //     color: Colors.blue[50],
                    //     borderRadius: BorderRadius.circular(8),
                    //   ),
                    //   // child: Text(
                    //   //   _isAndroid
                    //   //       ? 'Swipe anywhere on the board to change direction\nEat red food to grow and increase your score!'
                    //   //       : 'Use arrow keys or buttons to control the snake\nEat red food to grow and increase your score!',
                    //   //   textAlign: TextAlign.center,
                    //   //   style: const TextStyle(
                    //   //     fontSize: 14,
                    //   //     color: Colors.blue,
                    //   //   ),
                    //   // ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Consumer<GameViewModel>(
              builder: (context, vm, _) {
                return vm.isGameOver
                    ? const GameOverOverlay(key: ValueKey('gameover'))
                    : const SizedBox.shrink(key: ValueKey('nogameover'));
              },
            ),
          ),

          // Resume countdown overlay
          Consumer<GameViewModel>(
            builder: (context, vm, _) {
              final c = vm.resumeCountdown;
              if (c == null) return const SizedBox.shrink();
              return Positioned.fill(
                child: Container(
                  color: Colors.black38,
                  child: Center(
                    child: Text(
                      '$c',
                      style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),

          // Tap-to-start hint overlay on mobile when ready
          Consumer<GameViewModel>(
            builder: (context, vm, _) {
              if (!_isMobile || !vm.isReady) return const SizedBox.shrink();
              return Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.touch_app, color: Colors.white70),
                          SizedBox(width: 8),
                          Text(
                            'Tap to start',
                            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.dx.abs() > velocity.dy.abs()) {
      // Horizontal swipe
      if (velocity.dx > 0) {
        Provider.of<GameViewModel>(context, listen: false).changeDirection(Direction.right);
      } else {
        Provider.of<GameViewModel>(context, listen: false).changeDirection(Direction.left);
      }
    } else {
      // Vertical swipe
      if (velocity.dy > 0) {
        Provider.of<GameViewModel>(context, listen: false).changeDirection(Direction.down);
      } else {
        Provider.of<GameViewModel>(context, listen: false).changeDirection(Direction.up);
      }
    }
  }

  /// Handles keyboard input for snake direction control
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final gameViewModel = Provider.of<GameViewModel>(context, listen: false);
      
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          gameViewModel.changeDirection(Direction.up);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowDown:
          gameViewModel.changeDirection(Direction.down);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowLeft:
          gameViewModel.changeDirection(Direction.left);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
          gameViewModel.changeDirection(Direction.right);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.space:
          if (gameViewModel.isPlaying) {
            gameViewModel.pauseGame();
          } else if (gameViewModel.isPaused) {
            gameViewModel.resumeGame();
          } else if (gameViewModel.isReady) {
            gameViewModel.startNewGame();
          }
          return KeyEventResult.handled;
      }
    }
    
    return KeyEventResult.ignored;
  }

  void _handleTap() {
    // On mobile, start the game on tap when ready
    final vm = Provider.of<GameViewModel>(context, listen: false);
    if (_isMobile && vm.isReady) {
      vm.startNewGame();
      return;
    }
    // Keep keyboard focus for desktop/web
    _focusNode.requestFocus();
  }
}

class _ToolbarStats extends StatelessWidget {
  const _ToolbarStats({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 15);
    final iconColor = Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    return Consumer<GameViewModel>(
      builder: (context, vm, _) {
        String status;
        if (vm.isPlaying) {
          status = 'Play';
        } else if (vm.isPaused) {
          status = 'Pause';
        } else if (vm.isGameOver) {
          status = 'Over';
        } else {
          status = 'Ready';
        }
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _mini(icon: Icons.star, value: vm.score.toString(), color: Colors.orange, style: textStyle),
              const SizedBox(width: 10),
              _mini(icon: Icons.emoji_events, value: vm.highScore.toString(), color: Colors.purple, style: textStyle),
              const SizedBox(width: 10),
              _mini(icon: Icons.straighten, value: vm.snakeLength.toString(), color: Colors.green, style: textStyle),
              const SizedBox(width: 10),
              Icon(Icons.circle, size: 8, color: iconColor.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(status, style: textStyle),
            ],
          ),
        );
      },
    );
  }

  Widget _mini({required IconData icon, required String value, required Color color, TextStyle? style}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(value, style: style?.copyWith(color: color)),
      ],
    );
  }
}

class _Bouncy extends StatefulWidget {
  const _Bouncy({required this.child});
  final Widget child;

  @override
  State<_Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<_Bouncy> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.9),
      onPointerUp: (_) => setState(() => _scale = 1.0),
      onPointerCancel: (_) => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

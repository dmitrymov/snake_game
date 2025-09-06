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
        title: const Text(
          'Snake Game',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
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
              onTap: () => _focusNode.requestFocus(),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
                      const SizedBox(height: 20),
                      
                      // Game board (swipe to change direction on Android)
                      Center(
                        child: _isAndroid
                            ? GestureDetector(
                                onPanEnd: _handleSwipe,
                                child: const GameBoard(),
                              )
                            : const GameBoard(),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Game action buttons
                      const GameActions(),
                      
                      const SizedBox(height: 20),
                      
                      // Game controls (hidden on Android; use swipe gestures instead)
                      if (!_isAndroid) const GameControls(),
                      
                      const SizedBox(height: 16),
                                            // Game information display
                      const GameInfo(),
                      // Instructions
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // child: Text(
                        //   _isAndroid
                        //       ? 'Swipe anywhere on the board to change direction\nEat red food to grow and increase your score!'
                        //       : 'Use arrow keys or buttons to control the snake\nEat red food to grow and increase your score!',
                        //   textAlign: TextAlign.center,
                        //   style: const TextStyle(
                        //     fontSize: 14,
                        //     color: Colors.blue,
                        //   ),
                        // ),
                      ),
                    ],
                  ),
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
}

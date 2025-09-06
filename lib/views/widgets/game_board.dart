import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/game_viewmodel.dart';
import '../../models/position.dart';
import '../../models/direction.dart';

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

                // Head overlay (eyes, tongue)
                _buildHeadOverlay(
                  head: gameState.snake.head,
                  cellSize: cellSize,
                  direction: gameState.snake.direction,
                  showTongue: gameViewModel.isPlaying,
                ),
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

  /// Builds a food widget with spawn animation and continuous pulse
  Widget _buildFood(Position position, double cellSize) {
    return Positioned(
      left: position.x * cellSize,
      top: position.y * cellSize,
      child: _PulsingFood(
        key: ValueKey('food_${position.x}_${position.y}'),
        cellSize: cellSize,
      ),
    );
  }

  /// Overlay painter for the head (eyes, tongue)
  Widget _buildHeadOverlay({
    required Position head,
    required double cellSize,
    required Direction direction,
    required bool showTongue,
  }) {
    return Positioned(
      left: head.x * cellSize,
      top: head.y * cellSize,
      child: SizedBox(
        width: cellSize,
        height: cellSize,
        child: CustomPaint(
          painter: _HeadDetailPainter(direction: direction, showTongue: showTongue),
        ),
      ),
    );
  }
}

class _HeadDetailPainter extends CustomPainter {
  _HeadDetailPainter({required this.direction, required this.showTongue});

  final Direction direction;
  final bool showTongue;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);

    // Compute forward vector based on direction
    Offset forward;
    Offset right;
    switch (direction) {
      case Direction.up:
        forward = const Offset(0, -1);
        right = const Offset(1, 0);
        break;
      case Direction.down:
        forward = const Offset(0, 1);
        right = const Offset(-1, 0);
        break;
      case Direction.left:
        forward = const Offset(-1, 0);
        right = const Offset(0, -1);
        break;
      case Direction.right:
        forward = const Offset(1, 0);
        right = const Offset(0, 1);
        break;
    }

    // Eyes positions toward the facing side
    final eyeOffsetForward = cell * 0.20;
    final eyeOffsetLateral = cell * 0.16;
    final eyeRadius = cell * 0.10;
    final pupilRadius = cell * 0.05;

    final eyeCenter1 = center + forward * eyeOffsetForward + right * eyeOffsetLateral;
    final eyeCenter2 = center + forward * eyeOffsetForward - right * eyeOffsetLateral;

    final eyePaint = Paint()..color = const Color(0xFFFFFFFF);
    final pupilPaint = Paint()..color = const Color(0xFF000000);

    canvas.drawCircle(eyeCenter1, eyeRadius, eyePaint);
    canvas.drawCircle(eyeCenter2, eyeRadius, eyePaint);

    // Pupils offset slightly more in forward direction
    final pupilForwardOffset = cell * 0.05;
    canvas.drawCircle(eyeCenter1 + forward * pupilForwardOffset, pupilRadius, pupilPaint);
    canvas.drawCircle(eyeCenter2 + forward * pupilForwardOffset, pupilRadius, pupilPaint);

    // Tongue - small triangle pointing forward
    if (showTongue) {
      final tongueLength = cell * 0.18;
      final tongueWidth = cell * 0.12;
      final tip = center + forward * (cell * 0.5);
      final baseLeft = tip - forward * tongueLength + right * (tongueWidth / 2);
      final baseRight = tip - forward * tongueLength - right * (tongueWidth / 2);

      final tonguePath = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(baseLeft.dx, baseLeft.dy)
        ..lineTo(baseRight.dx, baseRight.dy)
        ..close();
      final tonguePaint = Paint()..color = const Color(0xFFE53935);
      canvas.drawPath(tonguePath, tonguePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeadDetailPainter oldDelegate) {
    return oldDelegate.direction != direction || oldDelegate.showTongue != showTongue;
  }
}

class _PulsingFood extends StatefulWidget {
  const _PulsingFood({super.key, required this.cellSize});
  final double cellSize;

  @override
  State<_PulsingFood> createState() => _PulsingFoodState();
}

class _PulsingFoodState extends State<_PulsingFood> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Spawn animation: 0 -> 1, then pulse around 1.0 with 0.9..1.1 range
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      builder: (context, spawn, _) {
        return AnimatedBuilder(
          animation: _curve,
          builder: (context, __) {
            final pulse = 0.9 + 0.2 * _curve.value; // 0.9 .. 1.1
            final scale = (spawn.clamp(0.0, 1.0)) * pulse;
            return Opacity(
              opacity: spawn.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.cellSize,
                  height: widget.cellSize,
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
          },
        );
      },
    );
  }
}

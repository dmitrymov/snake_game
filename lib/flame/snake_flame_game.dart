import 'dart:ui';
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:vector_math/vector_math.dart' as v;
import 'package:flutter/material.dart';
import '../models/position.dart';
import '../models/direction.dart';
import '../viewmodels/game_viewmodel.dart';

class SnakeFlameGame extends Game {
  SnakeFlameGame(this.vm) {
    _scheduleNextBlink();
  }

  final GameViewModel vm;
  double _time = 0.0; // seconds, for food pulse
  final math.Random _rng = math.Random();
  double _blinkUntil = -1.0; // sec
  double _nextBlinkAt = 2.0; // sec

  @override
  void render(Canvas canvas) {
    final s = vm.gameState;
    final sz = size.toSize();

    final cell = _cellSize(sz, s.boardWidth, s.boardHeight);
    final boardW = cell * s.boardWidth;
    final boardH = cell * s.boardHeight;

    // Clear to black (board background)
    final bg = Paint()..color = const Color(0xFF000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, boardW, boardH), bg);

    final now = DateTime.now().millisecondsSinceEpoch;

    // Obstacles
    final obPaint = Paint()
      ..color = const Color(0xFF424242)
      ..style = PaintingStyle.fill;
    for (final pos in s.obstacles) {
      final r = Rect.fromLTWH(pos.x * cell, pos.y * cell, cell, cell).deflate(1);
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
      canvas.drawRRect(rr, obPaint);
    }

    // Snake body
    final head = s.snake.head;
    for (final seg in s.snake.body) {
      final isHead = seg == head;
      final segPaint = Paint()
        ..color = isHead ? const Color(0xFF8BC34A) : const Color(0xFF4CAF50);
      final r = Rect.fromLTWH(seg.x * cell, seg.y * cell, cell, cell).deflate(1);
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));
      canvas.drawRRect(rr, segPaint);
    }

    // Head eyes and tongue
    _drawHeadDetail(canvas, head, s.snake.direction, cell);

    // Floating score popups
    for (final pop in vm.scorePopups) {
      final t = ((now - pop.createdAtMs) / pop.durationMs).clamp(0.0, 1.0);
      final base = Offset((pop.x + 0.5) * cell, (pop.y + 0.5) * cell);
      final pt = base.translate(0, -cell * 0.8 * t);
      final alpha = (255 * (1.0 - t)).toInt();
      _drawText(canvas, '+${pop.value}', pt, Colors.orange.withAlpha(alpha), fontSize: cell * 0.5);
    }

    // Food (pulse 0.9..1.1 around base)
    if (s.food != null) {
      final f = s.food!.position;
      final center = Offset((f.x + 0.5) * cell, (f.y + 0.5) * cell);
      final pulse = 0.9 + 0.2 * (0.5 * (1 + math.sin(_time * math.pi * 2 / 1.2)));
      final radius = cell * 0.42 * pulse;
      final foodPaint = Paint()..color = const Color(0xFFE53935);
      canvas.drawCircle(center, radius, foodPaint);
      // Glow
      final glow = Paint()
        ..shader = const RadialGradient(colors: [Color(0x55E53935), Colors.transparent])
            .createShader(Rect.fromCircle(center: center, radius: cell * 0.7));
      canvas.drawCircle(center, cell * 0.7, glow);
    }

    // Eat particles (drift & fade); progress based on creation time
    for (final p in vm.eatParticles) {
      final center = Offset((p.origin.x + 0.5) * cell, (p.origin.y + 0.5) * cell);
      final lifeMs = 250.0;
      final created = _createdAtMs(p);
      if (created == null) continue; // should not happen
      var t = ((now - created) / lifeMs).clamp(0.0, 1.0);
      final dist = cell * 0.6;
      final dx = math.cos(p.angle) * dist * t;
      final dy = math.sin(p.angle) * dist * t;
      final color = p.isRed ? const Color(0xFFE53935) : const Color(0xFF43A047);
      final alpha = (255 * (1.0 - t)).toInt();
      final paint = Paint()..color = color.withAlpha(alpha);
      final r = cell * (0.2 * (1.0 - 0.3 * t));
      canvas.drawCircle(center.translate(dx, dy), r, paint);
    }
  }

  @override
  void update(double dt) {
    _time += dt;
    if (_time >= _nextBlinkAt) {
      _blinkUntil = _time + 0.15; // 150ms blink
      _scheduleNextBlink();
    }
  }

  void _scheduleNextBlink() {
    _nextBlinkAt = _time + 6.0 + _rng.nextDouble() * 4.0; // 6..10s
  }

  // Utility
  // Not needed: Game already has a size Vector2; use size.toSize() when needed

  double _cellSize(Size size, int w, int h) {
    return math.min(size.width / w, size.height / h);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 16}) {
    final tp = TextPaint(
      style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold),
    );
    tp.render(canvas, text, v.Vector2(pos.dx, pos.dy));
  }

  void _drawHeadDetail(Canvas canvas, Position head, Direction direction, double cell) {
    final center = Offset((head.x + 0.5) * cell, (head.y + 0.5) * cell);
    late Offset forward;
    late Offset right;
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
    final eyeOffF = cell * 0.20;
    final eyeOffL = cell * 0.16;
    final baseEyeR = cell * 0.10;
    final pupilR = cell * 0.05;
    final blinkFactor = (_time <= _blinkUntil) ? 0.12 : 1.0;
    final eyeR = baseEyeR * blinkFactor;

    final eye1 = center + forward * eyeOffF + right * eyeOffL;
    final eye2 = center + forward * eyeOffF - right * eyeOffL;
    final eyePaint = Paint()..color = const Color(0xFFFFFFFF);
    final pupilPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawCircle(eye1, eyeR, eyePaint);
    canvas.drawCircle(eye2, eyeR, eyePaint);
    final pupilF = cell * 0.05;
    canvas.drawCircle(eye1 + forward * pupilF, pupilR, pupilPaint);
    canvas.drawCircle(eye2 + forward * pupilF, pupilR, pupilPaint);

    // Tongue only when playing
    // Tongue flick cadence: 0.16s visible every 0.8s
    final flickOn = vm.isPlaying && ((_time % 0.8) < 0.16);
    if (flickOn) {
      final len = cell * 0.18;
      final width = cell * 0.12;
      final tip = center + forward * (cell * 0.5);
      final baseL = tip - forward * len + right * (width / 2);
      final baseR = tip - forward * len - right * (width / 2);
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(baseL.dx, baseL.dy)
        ..lineTo(baseR.dx, baseR.dy)
        ..close();
      final paint = Paint()..color = const Color(0xFFE53935);
      canvas.drawPath(path, paint);
    }
  }

  int? _createdAtMs(dynamic p) {
    try {
      // Ignore if not available
      // We will add this field to particle model
      return (p as dynamic).createdAtMs as int?;
    } catch (_) {
      return null;
    }
  }
}


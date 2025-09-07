import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flame/text.dart';
import 'package:vector_math/vector_math.dart' as v;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/position.dart';
import '../models/direction.dart';
import '../models/food.dart';
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

  // Cached food images
  final Map<FoodKind, ui.Image?> _foodImgs = {};
  bool _loadingImages = false;

  @override
  void render(Canvas canvas) {
    final s = vm.gameState;
    final sz = size.toSize();

    // Square cells: compute board size to preserve aspect and center within canvas
    final cell = _cellSize(sz, s.boardWidth, s.boardHeight);
    final boardW = cell * s.boardWidth;
    final boardH = cell * s.boardHeight;
    final minC = cell;

    // Center the board within the canvas and draw only the board area background
    final dx = (sz.width - boardW) / 2.0;
    final dy = (sz.height - boardH) / 2.0;
    canvas.save();
    canvas.translate(dx, dy);

    final bg = Paint()..color = const Color(0xFF000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, boardW, boardH), bg);

    final now = DateTime.now().millisecondsSinceEpoch;

    // Obstacles
    final obPaint = Paint()
      ..color = const Color(0xFF424242)
      ..style = PaintingStyle.fill;
    for (final pos in s.obstacles) {
      final r = Rect.fromLTWH(pos.x * cell, pos.y * cell, cell, cell).deflate(1);
      final rr = RRect.fromRectAndRadius(r, Radius.circular(minC * 0.12));
      canvas.drawRRect(rr, obPaint);
    }

    // Snake body
    final head = s.snake.head;
    for (final seg in s.snake.body) {
      final isHead = seg == head;
      final segPaint = Paint()
        ..color = isHead ? const Color(0xFF8BC34A) : const Color(0xFF4CAF50);
      final r = Rect.fromLTWH(seg.x * cell, seg.y * cell, cell, cell).deflate(1);
      final rr = RRect.fromRectAndRadius(r, Radius.circular(minC * 0.18));
      canvas.drawRRect(rr, segPaint);
    }

    // Head eyes and tongue
    _drawHeadDetail(canvas, head, s.snake.direction, cell);

    // Floating score popups
    for (final pop in vm.scorePopups) {
      final t = ((now - pop.createdAtMs) / pop.durationMs).clamp(0.0, 1.0);
      final base = Offset((pop.x + 0.5) * cell, (pop.y + 0.5) * cell);
      final pt = base.translate(0, -minC * 0.8 * t);
      final alpha = (255 * (1.0 - t)).toInt();
      _drawText(canvas, '+${pop.value}', pt, Colors.orange.withAlpha(alpha), fontSize: minC * 0.5);
    }

    // Food (pulse 0.9..1.1 around base)
    if (s.food != null) {
      final food = s.food!;
      final f = food.position;
      final center = Offset((f.x + 0.5) * cell, (f.y + 0.5) * cell);
      final pulse = 0.9 + 0.2 * (0.5 * (1 + math.sin(_time * math.pi * 2 / 1.2)));
      final radius = minC * 0.42 * pulse;

      if (food.kind == FoodKind.bad) {
        // Draw bad food as gray circle
        final base = const Color(0xFF9E9E9E);
        final glowC = const Color(0x559E9E9E);
        final foodPaint = Paint()..color = base;
        canvas.drawCircle(center, radius, foodPaint);
        final glow = Paint()
          ..shader = RadialGradient(colors: [glowC, Colors.transparent])
              .createShader(Rect.fromCircle(center: center, radius: minC * 0.7));
        canvas.drawCircle(center, minC * 0.7, glow);
      } else {
        // Draw icon-based food
        final img = _getFoodImage(food.kind);
        if (img != null) {
          final size = radius * 2;
          final rect = Rect.fromCenter(center: center, width: size, height: size);
          paintImage(canvas: canvas, rect: rect, image: img, fit: BoxFit.contain, filterQuality: FilterQuality.high);
        } else {
          // Start loading images lazily and fallback to colored circle
          _maybeStartLoadImages();
          final base = (food.kind == FoodKind.pineapple)
              ? const Color(0xFFFFD54F)
              : const Color(0xFFE53935);
          final glowC = (food.kind == FoodKind.pineapple)
              ? const Color(0x66FFD54F)
              : const Color(0x55E53935);
          final foodPaint = Paint()..color = base;
          canvas.drawCircle(center, radius, foodPaint);
          final glow = Paint()
            ..shader = RadialGradient(colors: [glowC, Colors.transparent])
                .createShader(Rect.fromCircle(center: center, radius: minC * 0.7));
          canvas.drawCircle(center, minC * 0.7, glow);
        }
      }
    }

    // Eat particles (drift & fade); progress based on creation time
    for (final p in vm.eatParticles) {
      final center = Offset((p.origin.x + 0.5) * cell, (p.origin.y + 0.5) * cell);
      final lifeMs = 250.0;
      final created = _createdAtMs(p);
      if (created == null) continue; // should not happen
      var t = ((now - created) / lifeMs).clamp(0.0, 1.0);
      final dist = minC * 0.6;
      final dx = math.cos(p.angle) * dist * t;
      final dy = math.sin(p.angle) * dist * t;
      final color = p.isRed ? const Color(0xFFE53935) : const Color(0xFF43A047);
      final alpha = (255 * (1.0 - t)).toInt();
      // Particle color by kind
      Color cpart;
      if (p.kind == 1) {
        cpart = const Color(0xFFFFD54F); // golden
      } else if (p.kind == -1) {
        cpart = const Color(0xFF9E9E9E); // bad
      } else {
        cpart = color;
      }
      final paint = Paint()..color = cpart.withAlpha(alpha);
      final r = minC * (0.2 * (1.0 - 0.3 * t));
      canvas.drawCircle(center.translate(dx, dy), r, paint);
    }

    // Inner shadow for board separation (subtle)
    _drawInnerShadow(canvas, boardW, boardH);

    // Restore translation
    canvas.restore();
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

  void _drawInnerShadow(Canvas c, double w, double h) {
    final double s = math.max(4.0, math.min(w, h) * 0.02);
    final List<Color> colors = [const Color(0x33000000), const Color(0x00000000)];

    // Top
Paint pTop = Paint()
      ..shader = ui.Gradient.linear(const Offset(0, 0), Offset(0, s), colors);
    c.drawRect(Rect.fromLTWH(0, 0, w, s), pTop);

    // Bottom
Paint pBottom = Paint()
      ..shader = ui.Gradient.linear(Offset(0, h), Offset(0, h - s), colors);
    c.drawRect(Rect.fromLTWH(0, h - s, w, s), pBottom);

    // Left
Paint pLeft = Paint()
      ..shader = ui.Gradient.linear(const Offset(0, 0), Offset(s, 0), colors);
    c.drawRect(Rect.fromLTWH(0, 0, s, h), pLeft);

    // Right
Paint pRight = Paint()
      ..shader = ui.Gradient.linear(Offset(w, 0), Offset(w - s, 0), colors);
    c.drawRect(Rect.fromLTWH(w - s, 0, s, h), pRight);
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

Future<ui.Image> _loadAssetImage(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
}

extension _FoodAssets on FoodKind {
  String? get assetPath {
    switch (this) {
      case FoodKind.strawberry:
        return 'assets/strawberry.png';
      case FoodKind.banana:
        return 'assets/banana.png';
      case FoodKind.apple:
        return 'assets/apple.png';
      case FoodKind.pineapple:
        return 'assets/annanas.png';
      case FoodKind.bad:
        return null; // no icon
    }
  }
}

extension _FoodImages on SnakeFlameGame {
  ui.Image? _getFoodImage(FoodKind kind) {
    final img = _foodImgs[kind];
    if (img == null && !_loadingImages) {
      _maybeStartLoadImages();
    }
    return img;
  }

  void _maybeStartLoadImages() {
    if (_loadingImages) return;
    _loadingImages = true;
    // Kick off async loads without awaiting; images will appear on subsequent frames
    for (final kind in FoodKind.values) {
      final path = kind.assetPath;
      if (path == null) continue;
      _loadAssetImage(path).then((image) {
        _foodImgs[kind] = image;
      }).catchError((_) {}).whenComplete(() {
        _loadingImages = false;
      });
    }
  }
}


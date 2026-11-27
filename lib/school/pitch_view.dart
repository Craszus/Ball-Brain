import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/theme.dart';
import 'lessons.dart';

/// Hvor mye av omgivelsene som vises utenfor linjene (meter).
const _side = 4.0, _end = 3.0;

/// Regner mellom meter på banen og punkter på skjermen. Målet det angripes mot er øverst.
class PitchMap {
  PitchMap(this.from, this.size);

  final double from;
  final Size size;

  /// Banen vises fra x = [from] til bak målet.
  static double minX(double from) => from <= 0 ? -_end : from;
  static const maxX = 105 + _end;
  static const width = 68 + 2 * _side;

  /// Bredde delt på høyde.
  static double aspect(double from) => width / (maxX - minX(from));

  double get scale => size.width / width;

  Offset toScreen(Offset m) => Offset((m.dy + _side) * scale, (maxX - m.dx) * scale);

  Offset toMetres(Offset p) => Offset(maxX - p.dy / scale, p.dx / scale - _side);
}

/// Banen sett ovenfra med spillere, ball og fasit. [onTap] får trykket i meter og piksler.
/// Har oppgaven en pasning, spilles den av når fasiten vises. Trykk for å se den igjen.
class PitchView extends StatefulWidget {
  const PitchView({
    super.key,
    required this.situation,
    this.reveal = false,
    this.mark,
    this.picked,
    this.onTap,
  });

  final Situation situation;
  final bool reveal;

  /// Merket spilleren har satt (meter).
  final Offset? mark;

  /// Spilleren man har trykket på.
  final int? picked;
  final void Function(Offset metres, PitchMap map)? onTap;

  @override
  State<PitchView> createState() => _PitchViewState();
}

class _PitchViewState extends State<PitchView> with SingleTickerProviderStateMixin {
  late final _play =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  bool get _animates => widget.situation.shot != null && widget.situation.ball != null;

  @override
  void didUpdateWidget(PitchView old) {
    super.didUpdateWidget(old);
    if (!widget.reveal) {
      _play.value = 0;
    } else if (!old.reveal && _animates) {
      _play.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _play.dispose();
    super.dispose();
  }

  Situation get situation => widget.situation;

  @override
  Widget build(BuildContext context) => Center(
        child: AspectRatio(
          aspectRatio: PitchMap.aspect(situation.from),
          child: LayoutBuilder(builder: (context, c) {
            final map = PitchMap(situation.from, c.biggest);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                if (widget.reveal && _animates) {
                  _play.forward(from: 0);
                } else {
                  widget.onTap?.call(map.toMetres(d.localPosition), map);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AnimatedBuilder(
                  animation: _play,
                  builder: (_, _) => CustomPaint(
                    size: c.biggest,
                    painter: _PitchPainter(situation, widget.reveal, widget.mark, widget.picked,
                        Curves.easeInOut.transform(_play.value)),
                  ),
                ),
              ),
            );
          }),
        ),
      );
}

class _PitchPainter extends CustomPainter {
  _PitchPainter(this.s, this.reveal, this.mark, this.picked, this.t);

  final Situation s;
  final bool reveal;
  final Offset? mark;
  final int? picked;

  /// Hvor langt avspillingen har kommet (0–1).
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final map = PitchMap(s.from, size);
    final k = map.scale;
    Offset p(double x, double y) => map.toScreen(Offset(x, y));
    Rect area(Rect r) => Rect.fromPoints(p(r.left, r.top), p(r.right, r.bottom));

    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF1C6B3A));
    // klipte striper i gresset
    final stripe = Paint()..color = const Color(0xFF217842);
    for (var x = 0.0; x < 105; x += 21) {
      canvas.drawRect(area(Rect.fromLTRB(x, 0, x + 10.5, 68)), stripe);
    }

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, k * 0.3);
    canvas.drawRect(area(const Rect.fromLTRB(0, 0, 105, 68)), line);
    canvas.drawLine(p(52.5, 0), p(52.5, 68), line);
    canvas.drawCircle(p(52.5, 34), 9.15 * k, line);
    final dot = Paint()..color = Colors.white;
    canvas.drawCircle(p(52.5, 34), 0.45 * k, dot);
    for (final end in [0.0, 105.0]) {
      final d = end == 0 ? 1.0 : -1.0;
      canvas.drawRect(area(Rect.fromLTRB(math.min(end, end + d * 16.5), 13.84,
          math.max(end, end + d * 16.5), 54.16)), line);
      canvas.drawRect(area(Rect.fromLTRB(math.min(end, end + d * 5.5), 24.84,
          math.max(end, end + d * 5.5), 43.16)), line);
      canvas.drawCircle(p(end + d * 11, 34), 0.45 * k, dot);
      // buen utenfor straffefeltet
      canvas.drawArc(
          Rect.fromCircle(center: p(end + d * 11, 34), radius: 9.15 * k),
          (end == 0 ? -math.pi / 2 : math.pi / 2) - 0.93,
          1.86,
          false,
          line);
      canvas.drawRect(area(Rect.fromLTRB(math.min(end, end - d * 2.2), 30.34,
          math.max(end, end - d * 2.2), 37.66)), line);
    }
    for (final (x, y, a) in const [
      (105.0, 0.0, math.pi / 2),
      (105.0, 68.0, math.pi),
      (0.0, 0.0, 0.0),
      (0.0, 68.0, -math.pi / 2),
    ]) {
      canvas.drawArc(
          Rect.fromCircle(center: p(x, y), radius: 1.2 * k), a, math.pi / 2, false, line);
    }

    if (reveal) _paintAnswer(canvas, map, area);

    if (s.shot != null && s.ball != null) {
      _arrow(canvas, p(s.ball!.dx, s.ball!.dy), p(s.shot!.dx, s.shot!.dy), k);
    }

    final r = math.max(10.0, k * 2.3);
    for (var i = 0; i < s.players.length; i++) {
      final pl = s.players[i];
      final run = s.runs[i];
      final now = run == null ? pl.at : Offset.lerp(pl.at, run, t)!;
      final c = p(now.dx, now.dy);
      final color = switch (pl.side) {
        Side.blue => const Color(0xFF1F6FE0),
        Side.red => const Color(0xFFD0342C),
        Side.keeper => const Color(0xFF7B2FBF),
      };
      // rundt = blått lag, firkantet = rødt lag (ikke bare farge)
      final shape = pl.side == Side.blue
          ? (Path()..addOval(Rect.fromCircle(center: c, radius: r)))
          : (Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromCircle(center: c, radius: r * 0.92), Radius.circular(r * 0.28))));
      canvas.drawPath(shape, Paint()..color = color);
      final right = reveal && s.task is TapPlayer && (s.task as TapPlayer).isRight(i);
      canvas.drawPath(
          shape,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = right || picked == i ? 3.5 : 1.5
            ..color = right
                ? AppColors.goldLight
                : picked == i
                    ? Colors.redAccent
                    : Colors.white);
      final text = TextPainter(
        text: TextSpan(
            text: pl.label,
            style: TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white,
                fontSize: r * 1.05,
                fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, c - Offset(text.width / 2, text.height / 2));
    }

    if (s.ball != null) {
      // ligger ballen i en spiller, tegnes den ved føttene
      var at = p(s.ball!.dx, s.ball!.dy);
      if (s.players.any((pl) => (p(pl.x, pl.y) - at).distance < r)) {
        at += Offset(r * 0.95, r * 0.7);
      }
      if (s.shot != null && t > 0) {
        var end = p(s.shot!.dx, s.shot!.dy);
        for (var i = 0; i < s.players.length; i++) {
          final stop = s.runs[i] ?? s.players[i].at;
          if ((p(stop.dx, stop.dy) - end).distance < r) {
            end += Offset(r * 0.95, r * 0.7);
            break;
          }
        }
        at = Offset.lerp(at, end, t)!;
      }
      final br = math.max(5.0, k * 1.15);
      canvas.drawCircle(at, br, Paint()..color = Colors.white);
      canvas.drawCircle(
          at,
          br,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.black);
      canvas.drawCircle(at, br * 0.35, Paint()..color = Colors.black);
    }

    if (mark != null) {
      final at = p(mark!.dx, mark!.dy);
      canvas.drawCircle(at, 11, Paint()..color = AppColors.gold.withValues(alpha: 0.35));
      canvas.drawCircle(
          at,
          11,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = AppColors.goldLight);
      canvas.drawCircle(at, 3, Paint()..color = AppColors.goldLight);
    }
  }

  /// Fasiten tegnet på banen.
  void _paintAnswer(Canvas canvas, PitchMap map, Rect Function(Rect) area) {
    Offset p(double x, double y) => map.toScreen(Offset(x, y));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppColors.goldLight;
    final fill = Paint()..color = AppColors.gold.withValues(alpha: 0.35);
    switch (s.task) {
      case PlaceSpot(:final spots, :final tolerance):
        for (final spot in spots) {
          canvas.drawCircle(p(spot.dx, spot.dy), tolerance * map.scale, fill);
          canvas.drawCircle(p(spot.dx, spot.dy), tolerance * map.scale, stroke);
        }
      case PlaceArea(:final areas, :final except):
        for (final a in areas) {
          final path = Path()..addRect(area(a));
          if (except != null) {
            path
              ..fillType = PathFillType.evenOdd
              ..addRect(area(except));
          }
          canvas.drawPath(path, fill);
          canvas.drawPath(path, stroke);
        }
      default:
        break;
    }
    final x = s.line;
    if (x != null) {
      // stiplet offsidelinje tvers over banen
      for (var y = 0.0; y < 68; y += 4) {
        canvas.drawLine(p(x, y), p(x, math.min(68, y + 2.4)), stroke);
      }
    }
  }

  void _arrow(Canvas canvas, Offset a, Offset b, double k) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final length = (b - a).distance;
    if (length < 1) return;
    final dir = (b - a) / length;
    for (var d = k * 2; d < length; d += 12) {
      canvas.drawLine(a + dir * d, a + dir * math.min(length, d + 7), paint);
    }
    final side = Offset(-dir.dy, dir.dx);
    canvas.drawPath(
        Path()
          ..moveTo(b.dx, b.dy)
          ..lineTo((b - dir * 9 + side * 5).dx, (b - dir * 9 + side * 5).dy)
          ..moveTo(b.dx, b.dy)
          ..lineTo((b - dir * 9 - side * 5).dx, (b - dir * 9 - side * 5).dy),
        paint);
  }

  @override
  bool shouldRepaint(_PitchPainter old) =>
      old.s != s || old.reveal != reveal || old.mark != mark || old.picked != picked || old.t != t;
}

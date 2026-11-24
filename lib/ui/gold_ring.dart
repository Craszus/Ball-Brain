import 'dart:math' as math;

import 'package:flutter/material.dart';


enum RingMetal { gold, silver, bronze }

/// Tykk, blank gullring med glød, tynn indre linje og små gnister, slik som på mockupen.
/// Innholdet (avataren/trofeet) vises i en sirkel inni ringen.
class GoldRing extends StatelessWidget {
  const GoldRing({
    super.key,
    required this.size,
    required this.child,
    this.metal = RingMetal.gold,
    this.glow = true,
    this.sparkles = true,
  });

  final double size;
  final Widget child;
  final RingMetal metal;
  final bool glow;
  final bool sparkles;

  static List<Color> _colors(RingMetal m) => switch (m) {
        RingMetal.gold => const [
            Color(0xFFFFD84A),
            Color(0xFFF7BC0B),
            Color(0xFFE5A200),
            Color(0xFFF7BC0B),
            Color(0xFFFFD84A),
          ],
        RingMetal.silver => const [
            Color(0xFFFFFFFF),
            Color(0xFFD5DCE3),
            Color(0xFF8E9AA6),
            Color(0xFFD5DCE3),
            Color(0xFFFFFFFF),
          ],
        RingMetal.bronze => const [
            Color(0xFFFFC38A),
            Color(0xFFD98B3F),
            Color(0xFF9A5A22),
            Color(0xFFD98B3F),
            Color(0xFFFFC38A),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final decor = sparkles && size >= 48;
    final outer = decor ? 0.44 : 0.5; // ringens ytre radius (andel av size)
    final ring = size * (decor ? 0.036 : 0.06); // ringens tykkelse
    final inset = size * (0.5 - outer) + ring + size * 0.012;
    final colors = _colors(metal);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (glow)
            Padding(
              padding: EdgeInsets.all(size * (0.5 - outer)),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors[1].withValues(alpha: 0.35),
                      blurRadius: size * 0.09,
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(inset),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0A3326),
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
          IgnorePointer(
            child: CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(colors, outer, ring, decor),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.colors, this.outer, this.ring, this.decor);
  final List<Color> colors;
  final double outer;
  final double ring;
  final bool decor;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = size.center(Offset.zero);
    final r = s * outer - ring / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Selve ringen: jevn, lys gull med myk glans
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring
        ..shader = SweepGradient(
          startAngle: -math.pi * 0.75,
          endAngle: math.pi * 1.25,
          colors: colors,
        ).createShader(rect),
    );
    canvas.drawArc(
        rect,
        -math.pi * 0.9,
        math.pi * 0.5,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = ring * 0.3
          ..color = Colors.white.withValues(alpha: 0.45));

    if (!decor) return;

    // Tynne, delte buer utenfor ringen (som i mockupen)
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1, s * 0.006);
    void arc(double radius, double fromDeg, double sweepDeg, double alpha) {
      arcPaint.color = colors[1].withValues(alpha: alpha);
      canvas.drawArc(Rect.fromCircle(center: c, radius: radius),
          fromDeg * math.pi / 180, sweepDeg * math.pi / 180, false, arcPaint);
    }

    final ro = s * 0.475;
    arc(ro, -160, 95, 0.85);
    arc(ro, -52, 30, 0.45);
    arc(ro, 8, 40, 0.7);
    arc(ro, 62, 50, 0.5);
    arc(ro, 128, 62, 0.85);
    arc(ro, 200, 24, 0.5);
    final ri = s * 0.488;
    arc(ri, -120, 50, 0.4);
    arc(ri, 20, 70, 0.35);
    arc(ri, 150, 40, 0.4);

    // Kuler i ulik størrelse rundt ringen
    void dot(double deg, double radius, double d) {
      final a = deg * math.pi / 180;
      final p = c + Offset(math.cos(a), math.sin(a)) * (s * radius);
      final rad = s * d;
      canvas.drawCircle(
          p,
          rad * 2.4,
          Paint()
            ..shader = RadialGradient(colors: [
              colors[1].withValues(alpha: 0.55),
              colors[1].withValues(alpha: 0),
            ]).createShader(Rect.fromCircle(center: p, radius: rad * 2.4)));
      canvas.drawCircle(p, rad, Paint()..color = colors[0]);
    }

    dot(-128, 0.462, 0.013);
    dot(-146, 0.48, 0.006);
    dot(-8, 0.478, 0.011);
    dot(5, 0.47, 0.007);
    dot(172, 0.47, 0.013);
    dot(150, 0.482, 0.005);
    dot(62, 0.47, 0.016);
    dot(100, 0.472, 0.007);
    dot(-62, 0.482, 0.005);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.ring != ring || old.decor != decor || old.outer != outer;
}

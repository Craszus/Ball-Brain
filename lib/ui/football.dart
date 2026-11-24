import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import 'theme.dart';
import '../l10n/l10n.dart';

/// Stadion-bakgrunn: #0B3D2E med skrå gressstriper, prikkmønster (halvtone) som tones ut,
/// skrå mørke felt, svake banelinjer, lysglimt og vignett.
class PitchBackground extends StatelessWidget {
  const PitchBackground({super.key});

  @override
  Widget build(BuildContext context) => const RepaintBoundary(
        child: SizedBox.expand(child: CustomPaint(painter: _PitchPainter())),
      );
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = AppColors.pitch);

    // Skrå klippestriper
    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.rotate(-0.42);
    final diag = math.sqrt(w * w + h * h);
    const band = 96.0;
    final n = (diag / band).ceil();
    final lightStripe = Paint()..color = Colors.white.withValues(alpha: 0.032);
    final darkStripe = Paint()..color = Colors.black.withValues(alpha: 0.085);
    for (var i = -n; i <= n; i++) {
      canvas.drawRect(Rect.fromLTWH(i * band, -diag, band, diag * 2),
          i.isEven ? lightStripe : darkStripe);
    }
    canvas.restore();

    // Gress-tekstur (små strå)
    final rnd = math.Random(11);
    final blade = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final count = (w * h / 700).round();
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * w;
      final y = rnd.nextDouble() * h;
      blade.color = (rnd.nextBool() ? Colors.white : Colors.black)
          .withValues(alpha: 0.03 + rnd.nextDouble() * 0.03);
      canvas.drawLine(Offset(x, y), Offset(x + 1.5, y - 3.5), blade);
    }

    // Skrå mørke felt (nede til venstre og oppe til høyre)
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.46)
        ..lineTo(w * 0.62, h)
        ..lineTo(0, h)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Colors.black.withValues(alpha: 0.58), Colors.transparent],
        ).createShader(rect),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.38, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h * 0.34)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.black.withValues(alpha: 0.42), Colors.transparent],
        ).createShader(rect),
    );

    // Banelinjer: svak sirkelbue og skrå strek, som på stadionbildet
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;
    canvas.drawCircle(Offset(-w * 0.28, h * 0.46), w * 0.68, line);
    canvas.drawLine(Offset(0, h * 0.80), Offset(w * 0.55, h * 0.64),
        line..color = Colors.white.withValues(alpha: 0.06));

    // Prikkmønster (halvtone) som tones ut fra hjørnene
    final dot = Paint();
    void dots(Offset c, double r, double a) {
      const gap = 13.0;
      for (var y = c.dy - r; y <= c.dy + r; y += gap) {
        for (var x = c.dx - r; x <= c.dx + r; x += gap) {
          final d = (Offset(x, y) - c).distance;
          if (d > r) continue;
          final t = 1 - d / r;
          dot.color = Colors.white.withValues(alpha: a * t * t);
          canvas.drawCircle(Offset(x, y), 0.6 + 1.7 * t, dot);
        }
      }
    }

    dots(Offset(w, h * 0.04), w * 0.70, 0.55);
    dots(Offset(0, h * 0.10), w * 0.42, 0.34);
    dots(Offset(w, h * 0.84), w * 0.55, 0.42);

    // Lysglimt fra flomlys øverst
    final glow = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    for (final p in [
      Offset(w * 0.82, h * 0.012),
      Offset(w * 0.90, h * 0.035),
      Offset(w * 0.12, h * 0.02),
    ]) {
      canvas.drawCircle(p, 3.2, glow..color = Colors.white.withValues(alpha: 0.35));
    }

    // Vignett
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.15),
          radius: 1.15,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.42)],
          stops: const [0.5, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Logomerke: fotball (venstre) og gullhjerne (høyre). Bildet har gjennomsiktig bakgrunn.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.width = 150});
  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/brand/logo_mark.png',
        width: width,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
}

/// Scaffold med banebakgrunn og gjennomsiktig toppfelt.
class PitchScaffold extends StatelessWidget {
  const PitchScaffold({super.key, this.title, this.actions, required this.body});

  final String? title;
  final List<Widget>? actions;
  final Widget body;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          const Positioned.fill(child: PitchBackground()),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: title == null
                ? null
                : AppBar(title: Text(title!.toUpperCase()), actions: actions),
            body: SafeArea(child: body),
          ),
        ],
      );
}

/// Gullpille til poengsum (gullgradient som nivåkortet).
class ScoreChip extends StatelessWidget {
  const ScoreChip(this.points, {super.key});
  final int points;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.goldLighter),
          ),
          child: Text('$points p',
              style: const TextStyle(
                  color: AppColors.ink, fontWeight: FontWeight.w900)),
        ),
      );
}

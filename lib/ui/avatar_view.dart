import 'package:flutter/material.dart';

import '../services/profile.dart';
import 'gold_ring.dart';
import 'theme.dart';

/// Tegnet spiller-avatar med lys, skygge og glans: hudfarge, frisyre og drakt
/// med mønster og nummer.
class AvatarView extends StatelessWidget {
  const AvatarView(this.avatar, {super.key, this.size = 96});

  final Avatar avatar;
  final double size;

  @override
  Widget build(BuildContext context) {
    final art = avatar.art;
    return GoldRing(
      size: size,
      child: art != null
          ? Image.asset(art,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  CustomPaint(painter: _AvatarPainter(avatar)))
          : CustomPaint(painter: _AvatarPainter(avatar)),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.a);
  final Avatar a;

  static Color _l(Color c, double t) => Color.lerp(c, Colors.white, t)!;
  static Color _d(Color c, double t) => Color.lerp(c, Colors.black, t)!;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final skin = skinTones[a.skin];
    final hair = hairColors[a.hairColor];
    final kit = kits[a.kit];
    final circle = Rect.fromLTWH(0, 0, s, s);
    Offset p(double x, double y) => Offset(s * x, s * y);

    // Bakgrunn: stadionlys bak spilleren
    canvas.drawCircle(
      p(0.5, 0.5),
      s / 2,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.35),
          radius: 0.95,
          colors: [Color(0xFF3FBF73), AppColors.grass, AppColors.pitch],
          stops: [0, 0.4, 1],
        ).createShader(circle),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(circle.deflate(s * 0.02)));

    // Hår bak hodet / bak skuldrene
    final hairPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_l(hair, 0.22), hair, _d(hair, 0.35)],
      ).createShader(circle);
    if (a.hairStyle == 1) {
      final back = Path()
        ..moveTo(s * 0.3, s * 0.32)
        ..cubicTo(s * 0.2, s * 0.5, s * 0.2, s * 0.68, s * 0.27, s * 0.8)
        ..lineTo(s * 0.73, s * 0.8)
        ..cubicTo(s * 0.8, s * 0.68, s * 0.8, s * 0.5, s * 0.7, s * 0.32)
        ..close();
      canvas.drawPath(back, hairPaint);
    }

    // Hals
    final neck = RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.43, s * 0.5, s * 0.14, s * 0.15),
        Radius.circular(s * 0.05));
    canvas.drawRRect(
        neck,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_d(skin, 0.22), skin, _d(skin, 0.3)],
          ).createShader(neck.outerRect));

    // Drakt: brede skuldre med skygge
    final body = Path()
      ..moveTo(0, s)
      ..lineTo(s * 0.03, s * 0.78)
      ..cubicTo(s * 0.05, s * 0.67, s * 0.2, s * 0.63, s * 0.34, s * 0.6)
      ..lineTo(s * 0.66, s * 0.6)
      ..cubicTo(s * 0.8, s * 0.63, s * 0.95, s * 0.67, s * 0.97, s * 0.78)
      ..lineTo(s, s)
      ..close();
    canvas.drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_l(kit.primary, 0.18), kit.primary, _d(kit.primary, 0.3)],
          ).createShader(circle));
    canvas.save();
    canvas.clipPath(body);
    final sec = Paint()..color = kit.secondary;
    switch (a.pattern) {
      case 1: // striper
        for (var x = 0.12; x < 1.0; x += 0.2) {
          canvas.drawRect(Rect.fromLTWH(s * x, s * 0.55, s * 0.09, s * 0.5), sec);
        }
      case 2: // ringer
        for (var y = 0.72; y < 1.0; y += 0.13) {
          canvas.drawRect(Rect.fromLTWH(0, s * y, s, s * 0.06), sec);
        }
      case 3: // halvdelt
        canvas.drawRect(Rect.fromLTWH(s * 0.5, s * 0.55, s * 0.5, s * 0.5), sec);
    }
    // Skygge og glans over drakten
    canvas.drawRect(
        circle,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withValues(alpha: 0.14),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.26),
            ],
            stops: const [0, 0.5, 1],
          ).createShader(circle));
    final fold = Paint()
      ..color = Colors.black.withValues(alpha: 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.02
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(s * 0.2, s * 0.72)
          ..quadraticBezierTo(s * 0.26, s * 0.84, s * 0.22, s * 0.98),
        fold);
    canvas.drawPath(
        Path()
          ..moveTo(s * 0.8, s * 0.72)
          ..quadraticBezierTo(s * 0.74, s * 0.84, s * 0.78, s * 0.98),
        fold);
    canvas.restore();

    // V-krage med hud i åpningen
    final v = Path()
      ..moveTo(s * 0.37, s * 0.6)
      ..quadraticBezierTo(s * 0.5, s * 0.64, s * 0.63, s * 0.6)
      ..lineTo(s * 0.55, s * 0.71)
      ..lineTo(s * 0.5, s * 0.74)
      ..lineTo(s * 0.45, s * 0.71)
      ..close();
    canvas.drawPath(v, Paint()..color = _d(skin, 0.25));
    canvas.drawPath(
      v,
      Paint()
        ..color = kit.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.032
        ..strokeJoin = StrokeJoin.round,
    );

    // Draktnummer, preget
    final lum = kit.primary.computeLuminance();
    final numColor = lum > 0.5 ? AppColors.ink : Colors.white;
    void number(Offset o, Color c) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${a.number}',
          style: TextStyle(
              fontSize: s * 0.17, fontWeight: FontWeight.w900, color: c),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }

    if (a.pattern != 0) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: p(0.5, 0.88), width: s * 0.3, height: s * 0.19),
              Radius.circular(s * 0.04)),
          Paint()..color = kit.primary.withValues(alpha: 0.9));
    }
    number(p(0.5, 0.885), Colors.black.withValues(alpha: 0.3));
    number(p(0.5, 0.88), numColor);

    // Ører
    for (final x in [0.315, 0.685]) {
      canvas.drawOval(
          Rect.fromCenter(center: p(x, 0.42), width: s * 0.06, height: s * 0.09),
          Paint()..color = _d(skin, 0.12));
    }

    // Hode med lys fra øverst til venstre
    final headRect =
        Rect.fromCenter(center: p(0.5, 0.4), width: s * 0.37, height: s * 0.42);
    canvas.drawOval(
        headRect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.45),
            radius: 1.0,
            colors: [_l(skin, 0.18), skin, _d(skin, 0.22)],
            stops: const [0, 0.55, 1],
          ).createShader(headRect));
    // Hakeskygge mot halsen
    canvas.drawOval(
        Rect.fromCenter(center: p(0.5, 0.6), width: s * 0.2, height: s * 0.05),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.15)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.015));

    // Hår foran
    switch (a.hairStyle) {
      case 0: // Kort
      case 1: // Langt
        final cap = Path()
          ..moveTo(s * 0.31, s * 0.43)
          ..cubicTo(s * 0.27, s * 0.2, s * 0.42, s * 0.14, s * 0.52, s * 0.15)
          ..cubicTo(s * 0.64, s * 0.15, s * 0.74, s * 0.22, s * 0.69, s * 0.43)
          ..cubicTo(s * 0.67, s * 0.34, s * 0.6, s * 0.29, s * 0.5, s * 0.29)
          ..cubicTo(s * 0.42, s * 0.3, s * 0.35, s * 0.35, s * 0.31, s * 0.43)
          ..close();
        canvas.drawPath(cap, hairPaint);
      case 2: // Snauet
        final cap = Path()
          ..moveTo(s * 0.32, s * 0.4)
          ..cubicTo(s * 0.3, s * 0.2, s * 0.42, s * 0.2, s * 0.5, s * 0.2)
          ..cubicTo(s * 0.6, s * 0.2, s * 0.7, s * 0.22, s * 0.68, s * 0.4)
          ..cubicTo(s * 0.64, s * 0.31, s * 0.58, s * 0.3, s * 0.5, s * 0.3)
          ..cubicTo(s * 0.42, s * 0.3, s * 0.36, s * 0.32, s * 0.32, s * 0.4)
          ..close();
        canvas.drawPath(cap, Paint()..color = hair.withValues(alpha: 0.85));
      case 3: // Krøll
        const puffs = [
          [0.34, 0.27, 0.075],
          [0.43, 0.2, 0.08],
          [0.55, 0.19, 0.08],
          [0.65, 0.26, 0.075],
          [0.7, 0.35, 0.05],
          [0.3, 0.36, 0.05],
          [0.5, 0.25, 0.08],
        ];
        for (final c in puffs) {
          canvas.drawCircle(p(c[0], c[1]), s * c[2], hairPaint);
        }
      case 4: // Hanekam
        final mo = Path()
          ..moveTo(s * 0.43, s * 0.3)
          ..cubicTo(s * 0.4, s * 0.14, s * 0.46, s * 0.08, s * 0.5, s * 0.08)
          ..cubicTo(s * 0.55, s * 0.08, s * 0.61, s * 0.14, s * 0.57, s * 0.3)
          ..close();
        canvas.drawPath(mo, hairPaint);
        canvas.drawPath(
            Path()
              ..moveTo(s * 0.32, s * 0.38)
              ..cubicTo(s * 0.32, s * 0.24, s * 0.68, s * 0.24, s * 0.68, s * 0.38)
              ..cubicTo(s * 0.64, s * 0.3, s * 0.36, s * 0.3, s * 0.32, s * 0.38)
              ..close(),
            Paint()..color = hair.withValues(alpha: 0.5));
    }
    // Hårglans
    if (a.hairStyle != 2) {
      canvas.drawPath(
          Path()
            ..moveTo(s * 0.4, s * 0.2)
            ..quadraticBezierTo(s * 0.48, s * 0.16, s * 0.58, s * 0.19),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.015
            ..strokeCap = StrokeCap.round);
    }

    // Øyenbryn
    final brow = Paint()
      ..color = _d(hair, 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.02
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(s * 0.37, s * 0.375)
          ..quadraticBezierTo(s * 0.42, s * 0.36, s * 0.46, s * 0.375),
        brow);
    canvas.drawPath(
        Path()
          ..moveTo(s * 0.54, s * 0.375)
          ..quadraticBezierTo(s * 0.58, s * 0.36, s * 0.63, s * 0.375),
        brow);

    // Øyne: hvite, iris, pupill og glimt
    for (final x in [0.415, 0.585]) {
      canvas.drawOval(
          Rect.fromCenter(center: p(x, 0.42), width: s * 0.075, height: s * 0.06),
          Paint()..color = Colors.white);
      canvas.drawCircle(
          p(x, 0.42), s * 0.026, Paint()..color = const Color(0xFF4A2F1B));
      canvas.drawCircle(
          p(x, 0.42), s * 0.014, Paint()..color = const Color(0xFF111111));
      canvas.drawCircle(
          p(x - 0.008, 0.412), s * 0.007, Paint()..color = Colors.white);
    }

    // Nese
    canvas.drawPath(
        Path()
          ..moveTo(s * 0.5, s * 0.43)
          ..quadraticBezierTo(s * 0.475, s * 0.49, s * 0.5, s * 0.49)
          ..quadraticBezierTo(s * 0.52, s * 0.49, s * 0.52, s * 0.485),
        Paint()
          ..color = _d(skin, 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.01
          ..strokeCap = StrokeCap.round);

    // Kinn
    for (final x in [0.385, 0.615]) {
      canvas.drawCircle(
          p(x, 0.49),
          s * 0.035,
          Paint()
            ..color = const Color(0xFFE2574C).withValues(alpha: 0.18)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.012));
    }

    // Smil med tenner
    final mouth = Path()
      ..moveTo(s * 0.43, s * 0.525)
      ..quadraticBezierTo(s * 0.5, s * 0.6, s * 0.57, s * 0.525)
      ..quadraticBezierTo(s * 0.5, s * 0.54, s * 0.43, s * 0.525)
      ..close();
    canvas.drawPath(mouth, Paint()..color = const Color(0xFF8E2C2C));
    canvas.save();
    canvas.clipPath(mouth);
    canvas.drawRect(Rect.fromLTWH(s * 0.43, s * 0.52, s * 0.14, s * 0.024),
        Paint()..color = Colors.white);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter old) =>
      old.a.skin != a.skin ||
      old.a.hairStyle != a.hairStyle ||
      old.a.hairColor != a.hairColor ||
      old.a.kit != a.kit ||
      old.a.pattern != a.pattern ||
      old.a.number != a.number ||
      old.a.art != a.art;
}

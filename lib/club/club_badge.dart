import 'package:flutter/material.dart';

import 'club_api.dart';

/// Klubbfargene man kan velge mellom (indeksen lagres på serveren).
const clubColors = [
  Color(0xFF1565C0), // blå
  Color(0xFFFFFFFF), // hvit
  Color(0xFFC62828), // rød
  Color(0xFF2E7D32), // grønn
  Color(0xFFF5B301), // gul
  Color(0xFF111111), // svart
  Color(0xFF6A1B9A), // lilla
  Color(0xFFEF6C00), // oransje
];

/// Antall skjoldmønstre. De fra [freeEmblems] og oppover krever Ball Brain Pro.
const clubEmblems = 8;
const freeEmblems = 4;

/// Eget klubbskjold (ingen ekte klubblogoer): ensfarget, midtstripe, skråbånd, delt,
/// og i Pro tverrbånd, vinkel, firedelt og kors.
class ClubBadge extends StatelessWidget {
  const ClubBadge(this.club, {super.key, this.size = 56});

  final ClubInfo club;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = club.name.characters.take(1).toString().toUpperCase();
    return SizedBox(
      width: size,
      height: size * 1.12,
      child: CustomPaint(
        painter: _ShieldPainter(clubColors[club.color1 % clubColors.length],
            clubColors[club.color2 % clubColors.length], club.emblem),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: size * 0.1),
            child: Text(letter,
                style: TextStyle(
                    fontSize: size * 0.46,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: const [Shadow(color: Colors.black87, blurRadius: 6)])),
          ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  _ShieldPainter(this.a, this.b, this.emblem);
  final Color a;
  final Color b;
  final int emblem;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final shield = Path()
      ..moveTo(w * 0.06, h * 0.05)
      ..lineTo(w * 0.94, h * 0.05)
      ..lineTo(w * 0.94, h * 0.5)
      ..quadraticBezierTo(w * 0.9, h * 0.82, w * 0.5, h * 0.97)
      ..quadraticBezierTo(w * 0.1, h * 0.82, w * 0.06, h * 0.5)
      ..close();
    canvas.save();
    canvas.clipPath(shield);
    canvas.drawRect(Offset.zero & s, Paint()..color = a);
    final second = Paint()..color = b;
    switch (emblem) {
      case 1:
        canvas.drawRect(Rect.fromLTWH(w * 0.35, 0, w * 0.3, h), second);
      case 2:
        canvas.drawPath(
            Path()
              ..moveTo(0, h * 0.7)
              ..lineTo(w, h * 0.05)
              ..lineTo(w, h * 0.35)
              ..lineTo(0, h)
              ..close(),
            second);
      case 3:
        canvas.drawRect(Rect.fromLTWH(w * 0.5, 0, w * 0.5, h), second);
      case 4: // tverrbånd
        canvas.drawRect(Rect.fromLTWH(0, h * 0.33, w, h * 0.28), second);
      case 5: // vinkel
        canvas.drawPath(
            Path()
              ..moveTo(0, h * 0.72)
              ..lineTo(w * 0.5, h * 0.36)
              ..lineTo(w, h * 0.72)
              ..lineTo(w, h * 0.95)
              ..lineTo(w * 0.5, h * 0.6)
              ..lineTo(0, h * 0.95)
              ..close(),
            second);
      case 6: // firedelt
        canvas.drawRect(Rect.fromLTWH(w * 0.5, 0, w * 0.5, h * 0.5), second);
        canvas.drawRect(Rect.fromLTWH(0, h * 0.5, w * 0.5, h * 0.5), second);
      case 7: // kors
        canvas.drawRect(Rect.fromLTWH(w * 0.4, 0, w * 0.2, h), second);
        canvas.drawRect(Rect.fromLTWH(0, h * 0.34, w, h * 0.2), second);
    }
    canvas.restore();
    canvas.drawPath(
        shield,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.06
          ..color = emblem == 0 ? b : const Color(0xFFF5B301));
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.a != a || old.b != b || old.emblem != emblem;
}

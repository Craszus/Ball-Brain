import 'package:flutter/material.dart' hide Text;

import '../ui/theme.dart';
import '../l10n/l10n.dart';

/// Nål som peker med spissen nederst i midten. Brukes med Marker(alignment: topCenter).
class MapPin extends StatelessWidget {
  const MapPin({super.key, required this.color, this.label});

  final Color color;
  final String? label;

  static const width = 72.0;
  static const height = 84.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (label != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: AppColors.tile,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Text(label!,
                  style: TextStyle(
                      color: color == AppColors.gold ? AppColors.gold : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900)),
            ),
          CustomPaint(size: const Size(34, 46), painter: _PinPainter(color)),
        ],
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  _PinPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = w / 2;
    final path = Path()
      ..moveTo(w / 2, h)
      ..cubicTo(w * 0.12, h * 0.66, 0, h * 0.5, 0, r)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r), clockwise: true)
      ..cubicTo(w, h * 0.5, w * 0.88, h * 0.66, w / 2, h)
      ..close();
    canvas.drawShadow(path, Colors.black, 4, true);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = AppColors.ink);
    canvas.drawCircle(Offset(w / 2, r), r * 0.38, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(covariant _PinPainter old) => old.color != color;
}

/// Rund-firkantet kartknapp: 56 px, kortfarge, gullkant, gull ikon.
class MapButton extends StatelessWidget {
  const MapButton({super.key, required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip ?? '',
        child: Material(
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
          elevation: 6,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(icon, color: AppColors.gold, size: 30),
            ),
          ),
        ),
      );
}

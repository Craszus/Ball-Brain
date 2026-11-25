import 'package:flutter/material.dart';

/// Pro-rammene rundt avataren (indeks 0 = ingen ramme).
const proFrames = <(String, List<Color>)>[
  ('Ingen', []),
  ('Diamant', [Color(0xFFB3E5FC), Color(0xFF29B6F6), Color(0xFFE1F5FE)]),
  ('Ild', [Color(0xFFFFD54F), Color(0xFFFF6D00), Color(0xFFD50000)]),
  ('Smaragd', [Color(0xFFB9F6CA), Color(0xFF00C853), Color(0xFF004D40)]),
  ('Kongelig', [Color(0xFFE1BEE7), Color(0xFF8E24AA), Color(0xFF311B92)]),
];

class ProFrame extends StatelessWidget {
  const ProFrame({super.key, required this.frame, required this.child});

  final int frame;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (frame <= 0 || frame >= proFrames.length) return child;
    final colors = proFrames[frame].$2;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [...colors, colors.first]),
        boxShadow: [BoxShadow(color: colors[1].withValues(alpha: 0.6), blurRadius: 10)],
      ),
      child: child,
    );
  }
}

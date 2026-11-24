import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import '../services/levels.dart';
import 'level_card.dart' show LevelShield;
import 'theme.dart';
import '../l10n/l10n.dart';

/// Fullskjerms nivåopp-feiring med konfetti og et nivåmerke som spretter inn.
class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({super.key, required this.info, required this.onClose});

  final LevelInfo info;
  final VoidCallback onClose;

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..forward();
  late final List<_Piece> _pieces = _makePieces();

  static List<_Piece> _makePieces() {
    final rnd = math.Random(7);
    // Kun paletten fra briefen (ingen lilla/blått/rosa): gull, hvit og grønt.
    const colors = [
      AppColors.gold,
      AppColors.goldLight,
      AppColors.goldLighter,
      Colors.white,
      AppColors.grass,
    ];
    return List.generate(
      90,
      (_) => _Piece(
        x: rnd.nextDouble(),
        delay: rnd.nextDouble() * 0.35,
        speed: 0.7 + rnd.nextDouble() * 0.6,
        size: 6 + rnd.nextDouble() * 8,
        phase: rnd.nextDouble() * math.pi * 2,
        spin: (rnd.nextDouble() - 0.5) * 14,
        color: colors[rnd.nextInt(colors.length)],
      ),
    );
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onClose,
      child: Stack(
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 0.92),
              duration: const Duration(milliseconds: 300),
              builder: (_, v, _) =>
                  ColoredBox(color: Colors.black.withValues(alpha: v)),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confetti,
                builder: (_, _) => CustomPaint(
                    painter: _ConfettiPainter(_pieces, _confetti.value)),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('NIVÅ OPP!',
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: AppColors.gold)),
                  const SizedBox(height: 20),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.55),
                                blurRadius: 60,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        LevelShield(level: info.level, width: 150),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(info.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Du er nå nivå ${info.level}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: widget.onClose,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(200, 52)),
                    child: const Text('Fortsett'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.phase,
    required this.spin,
    required this.color,
  });
  final double x, delay, speed, size, phase, spin;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);
  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final prog = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (prog <= 0 || prog >= 1) continue;
      final y = (-0.05 + prog * p.speed * 1.25) * size.height;
      final x = (p.x + math.sin(prog * 7 + p.phase) * 0.05) * size.width;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(prog * p.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.55),
          const Radius.circular(2),
        ),
        Paint()..color = p.color,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

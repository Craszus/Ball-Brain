import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';

/// Varselet på «Kamper»-knappen: dommeren holder opp et gult kort med antall utfordringer,
/// og knappen pulserer i gull. Vises bare når [count] er over null.
class ChallengeAlert extends StatefulWidget {
  const ChallengeAlert({super.key, required this.count, required this.child});

  final int count;

  /// Knappen varselet ligger rundt.
  final Widget child;

  @override
  State<ChallengeAlert> createState() => _ChallengeAlertState();
}

class _ChallengeAlertState extends State<ChallengeAlert> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run();
  }

  @override
  void didUpdateWidget(ChallengeAlert old) {
    super.didUpdateWidget(old);
    _run();
  }

  /// Animerer bare når det er noe å si fra om (og telefonen tillater animasjoner).
  void _run() {
    final animate = widget.count > 0 && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_c.isAnimating) {
      _c.repeat();
    } else if (!animate) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        final glow = (math.sin(t * 2 * math.pi) + 1) / 2;
        // kortet vifter kort, og holdes så stille
        final wave = t < 0.5 ? math.sin(t * 8 * math.pi) * (0.5 - t) : 0.0;
        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.passthrough,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.30 + 0.55 * glow),
                    blurRadius: 8 + 14 * glow,
                    spreadRadius: 1 + 2 * glow,
                  ),
                ],
              ),
              child: child,
            ),
            Positioned(
              right: 44,
              top: -6,
              bottom: -2,
              child: IgnorePointer(
                child: Center(
                  child: Transform.rotate(
                    angle: 0.18 + wave,
                    alignment: Alignment.bottomCenter,
                    child: _YellowCard(widget.count),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _YellowCard extends StatelessWidget {
  const _YellowCard(this.count);
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$count utfordringer'.tr,
        child: Container(
          width: 32,
          height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF176), Color(0xFFFFD600), Color(0xFFF9A825)],
            ),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(2, 4))
            ],
          ),
          child: ExcludeSemantics(
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2A1A00))),
          ),
        ),
      );
}

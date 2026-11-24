import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import 'theme.dart';

/// «3 PÅ RAD!»: vises når spilleren har minst [from] riktige svar på rad.
/// Bare en feiring – gir ingen ekstra poeng.
class StreakBadge extends StatelessWidget {
  const StreakBadge(this.streak, {super.key, this.from = 3});

  final int streak;
  final int from;

  @override
  Widget build(BuildContext context) {
    final show = streak >= from;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
      child: !show
          ? const SizedBox(key: ValueKey('none'), height: 0)
          : Padding(
              key: ValueKey(streak),
              padding: const EdgeInsets.only(top: 6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: AppColors.gold, size: 18),
                      const SizedBox(width: 4),
                      Text('$streak PÅ RAD!',
                          style: const TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 13,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

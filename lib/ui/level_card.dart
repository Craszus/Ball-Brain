import 'package:flutter/material.dart' hide Text;

import '../services/levels.dart';
import 'theme.dart';
import '../l10n/l10n.dart';

/// Nivåkortet på hovedmenyen: alltid gull, alltid med LVL-skjold, XP-bar og % til høyre.
class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.xp, this.fromXp, this.dark = false});
  final int xp;

  /// Mørk variant (kortfarge #145A42 med gullkant) brukt på avatarskjermen.
  final bool dark;

  /// Hvis satt, fylles baren fra denne XP-verdien (og fra 0 ved nivåskifte).
  final int? fromXp;

  @override
  Widget build(BuildContext context) {
    final info = levelFor(xp);
    final progress = info.progress.clamp(0.0, 1.0);
    double begin = 0;
    if (fromXp != null) {
      final old = levelFor(fromXp!);
      begin = old.level == info.level ? old.progress.clamp(0.0, 1.0) : 0;
    }
    final onCard = dark ? Colors.white : AppColors.ink;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: dark ? null : AppColors.goldGradient,
        color: dark ? AppColors.card : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: dark ? AppColors.gold : AppColors.goldLighter, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          if (!dark)
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.25),
              blurRadius: 24,
            ),
        ],
      ),
      child: Row(
        children: [
          LevelShield(level: info.level, width: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onCard,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.isMax
                      ? '$xp XP · høyeste nivå'
                      : '${info.xpIntoLevel} / ${info.xpForNext} XP',
                  style: TextStyle(
                    color: dark ? AppColors.textSecondary : AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _XpTrack(progress: progress, begin: begin, dark: dark),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _XpTrack extends StatelessWidget {
  const _XpTrack({required this.progress, this.begin = 0, this.dark = false});
  final double progress;
  final double begin;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: progress),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) {
        final pct = (progress * 100).round();
        return Container(
          height: 24,
          decoration: BoxDecoration(
            color: dark ? Colors.black38 : const Color(0xFF6B4A00),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: dark
                    ? AppColors.gold.withValues(alpha: 0.35)
                    : AppColors.ink.withValues(alpha: 0.35)),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: v.clamp(0.02, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.goldLighter, AppColors.goldLight],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    '$pct%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Nivåskjold: ett eget skjold per nivå (1–10), fra enkelt gult til strålende gull
/// med vinger og krone. Nivåtallet legges oppå i skjoldets midte.
class LevelShield extends StatelessWidget {
  const LevelShield({super.key, required this.level, this.width = 64});
  final int level;
  final double width;

  // (senter-forskyvning ned som andel av høyden, tekststørrelse som andel av bredden)
  static const _layout = <int, (double, double)>{
    1: (0.0, 1.0),
    2: (0.0, 1.0),
    3: (0.0, 1.0),
    4: (0.03, 0.95),
    5: (0.03, 0.9),
    6: (0.0, 0.85),
    7: (0.07, 0.62),
    8: (0.06, 0.6),
    9: (0.07, 0.58),
    10: (0.05, 0.56),
  };

  @override
  Widget build(BuildContext context) {
    final lv = level.clamp(1, 10);
    final (dy, k) = _layout[lv]!;
    final h = width * 1.1;
    return SizedBox(
      width: width,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/shields/lvl_${lv.toString().padLeft(2, '0')}.png',
            width: width,
            height: h,
            fit: BoxFit.contain,
          ),
          Transform.translate(
            offset: Offset(0, h * dy),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('LVL',
                    style: TextStyle(
                        color: AppColors.ink,
                        fontSize: width * 0.2 * k,
                        fontWeight: FontWeight.w900,
                        height: 1)),
                Text('$level',
                    style: TextStyle(
                        color: AppColors.ink,
                        fontSize: width * 0.5 * k,
                        fontWeight: FontWeight.w900,
                        height: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

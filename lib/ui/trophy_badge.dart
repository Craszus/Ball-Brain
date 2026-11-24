import 'package:flutter/material.dart';

import 'gold_ring.dart';
import 'theme.dart';

enum TrophyTier { bronze, silver, gold }

RingMetal _metal(TrophyTier t) => switch (t) {
      TrophyTier.bronze => RingMetal.bronze,
      TrophyTier.silver => RingMetal.silver,
      TrophyTier.gold => RingMetal.gold,
    };

/// Trofé: Pixar-lignende bilde i en blank metallring (bronse/sølv/gull).
/// Ikke opptjent: svart-hvitt og nedtonet, med lås.
class TrophyBadge extends StatelessWidget {
  const TrophyBadge({
    super.key,
    required this.tier,
    required this.asset,
    this.earned = true,
    this.size = 72,
  });

  final TrophyTier tier;
  final String asset;
  final bool earned;
  final double size;

  static const _gray = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 0.55, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    Widget img = Image.asset(asset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.emoji_events, color: AppColors.gold));
    if (!earned) img = ColorFiltered(colorFilter: _gray, child: img);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: earned ? 1 : 0.8,
            child: GoldRing(
              size: size,
              metal: _metal(tier),
              glow: earned,
              sparkles: earned,
              child: img,
            ),
          ),
          if (!earned)
            Container(
              padding: EdgeInsets.all(size * 0.07),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xCC0A3326)),
              child: Icon(Icons.lock, size: size * 0.2, color: Colors.white70),
            ),
        ],
      ),
    );
  }
}

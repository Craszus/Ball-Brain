/// Poengberegning for Ball Brain.
///
/// Riktig svar gir +2 poeng, feil svar gir −1 poeng. (Geografi har egne avstandstrinn,
/// se `geoXp`.) Poengene er XP, men man faller aldri under nivået man har nådd.
class Scoring {
  static const correctPoints = 2;
  static const wrongPoints = -1;

  static int pointsFor({
    required bool correct,
    int difficulty = 1,
    Duration elapsed = Duration.zero,
  }) =>
      correct ? correctPoints : wrongPoints;
}

/// «+2» / «−1» (med ekte minustegn).
String signed(int n) => n >= 0 ? '+$n' : '\u2212${-n}';

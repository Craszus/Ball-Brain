/// XP = totalt antall poeng. De to første nivåene går raskt, deretter blir kurven stadig
/// brattere, og «Legende» (nivå 10) krever 15 000 XP. Etter det kan man samle
/// poeng uendelig, men nivået blir stående på Legende.
class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.title,
    required this.xpIntoLevel,
    required this.xpForNext,
    this.isMax = false,
  });

  final int level;
  final String title;
  final int xpIntoLevel;
  final int xpForNext; // XP fra starten av nivået til neste nivå (0 på høyeste nivå)
  final bool isMax;

  double get progress => isMax ? 1 : (xpForNext == 0 ? 0 : xpIntoLevel / xpForNext);
}

const _titles = [
  'Benkesliter',
  'Innbytter',
  'Rotasjonsspiller',
  'Fast på laget',
  'Midtbanegeneral',
  'Lagkaptein',
  'Stjernespiller',
  'Landslagsspiller',
  'Verdensstjerne',
  'Legende',
];

/// Total XP som kreves for å nå hvert nivå (nivå 1 = 0).
const levelThresholds = <int>[
  0, // 1  Benkesliter
  50, // 2  Innbytter       (ca. 4 runder)
  120, // 3  Rotasjonsspiller
  250, // 4
  500, // 5
  1000, // 6
  2000, // 7
  4000, // 8
  7500, // 9
  15000, // 10 Legende
];

int get maxLevel => levelThresholds.length;

/// Sant hvis XP-økningen gir et høyere nivå.
bool leveledUp(int xpBefore, int xpAfter) =>
    levelFor(xpAfter).level > levelFor(xpBefore).level;

int xpAtLevel(int level) => levelThresholds[(level - 1).clamp(0, maxLevel - 1)];

LevelInfo levelFor(int xp) {
  var level = 1;
  while (level < maxLevel && xp >= levelThresholds[level]) {
    level++;
  }
  final title = _titles[level - 1];
  if (level == maxLevel) {
    return LevelInfo(
      level: level,
      title: title,
      xpIntoLevel: xp - levelThresholds.last,
      xpForNext: 0,
      isMax: true,
    );
  }
  final start = levelThresholds[level - 1];
  return LevelInfo(
    level: level,
    title: title,
    xpIntoLevel: xp - start,
    xpForNext: levelThresholds[level] - start,
  );
}

/// Ny XP-sum etter en runde. Poeng kan bli negative, men man faller aldri under starten
/// av nivået man allerede har nådd.
int applyPoints(int totalBefore, int points) {
  final floor = xpAtLevel(levelFor(totalBefore).level);
  final after = totalBefore + points;
  return after < floor ? floor : after;
}

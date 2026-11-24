import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../ui/trophy_badge.dart';
import 'levels.dart';

/// Statistikk for én spillmodus.
class ModeStat {
  const ModeStat({this.games = 0, this.best = 0, this.perfects = 0});
  final int games;
  final int best;
  final int perfects;

  ModeStat add(int points, bool perfect) => ModeStat(
        games: games + 1,
        best: points > best ? points : best,
        perfects: perfects + (perfect ? 1 : 0),
      );

  Map<String, int> toJson() => {'g': games, 'b': best, 'p': perfects};
  static ModeStat fromJson(Map<String, dynamic> j) => ModeStat(
      games: (j['g'] as num?)?.toInt() ?? 0,
      best: (j['b'] as num?)?.toInt() ?? 0,
      perfects: (j['p'] as num?)?.toInt() ?? 0);
}

/// Lokal statistikk (lagres på enheten). Flyttes til Supabase når
/// innlogging er på plass.
class Stats {
  const Stats({
    this.bestRules = 0,
    this.bestSort = 0,
    this.games = 0,
    this.totalPoints = 0,
    this.modes = const {},
    this.pvpGames = 0,
    this.pvpWins = 0,
    this.pvpStreak = 0,
    this.pvpBestStreak = 0,
  });

  final int bestRules;
  final int bestSort;
  final int games;
  final int totalPoints;

  /// Per modus: rules_quiz, image_sort, geo, photo_mixed, photo_player,
  /// photo_goalkeeper, photo_country, photo_stadium.
  final Map<String, ModeStat> modes;

  // 1v1: antall oppgjør og seiere (låser opp PVP-troféene).
  final int pvpGames;
  final int pvpWins;
  final int pvpStreak;
  final int pvpBestStreak;

  ModeStat mode(String m) => modes[m] ?? const ModeStat();
  int get perfects => modes.values.fold(0, (a, m) => a + m.perfects);
  int get photoGames => modes.entries
      .where((e) => e.key.startsWith('photo_'))
      .fold(0, (a, e) => a + e.value.games);

  Stats withResult(String mode, int points, {bool perfect = false}) => Stats(
        bestRules: mode == 'rules_quiz' && points > bestRules ? points : bestRules,
        bestSort: mode == 'image_sort' && points > bestSort ? points : bestSort,
        games: games + 1,
        totalPoints: applyPoints(totalPoints, points),
        modes: {...modes, mode: this.mode(mode).add(points, perfect)},
        pvpGames: pvpGames,
        pvpWins: pvpWins,
        pvpStreak: pvpStreak,
        pvpBestStreak: pvpBestStreak,
      );

  /// Registrerer et ferdig 1v1-oppgjør.
  Stats withPvp({required bool won}) => Stats(
        bestRules: bestRules,
        bestSort: bestSort,
        games: games,
        totalPoints: totalPoints,
        modes: modes,
        pvpGames: pvpGames + 1,
        pvpWins: pvpWins + (won ? 1 : 0),
        pvpStreak: won ? pvpStreak + 1 : 0,
        pvpBestStreak:
            won && pvpStreak + 1 > pvpBestStreak ? pvpStreak + 1 : pvpBestStreak,
      );
}

enum TrophyGroup { general, levels, rules, sort, photo, geo, pvp }

class Trophy {
  const Trophy(this.id, this.title, this.description, this.tier, this.group, this.earned);
  final String id; // = filnavn i assets/trophies/
  final String title;
  final String description;
  final TrophyTier tier;
  final TrophyGroup group;
  final bool Function(Stats) earned;
  String get asset => 'assets/trophies/$id.png';
}

const groupTitles = {
  TrophyGroup.general: 'Generelt',
  TrophyGroup.levels: 'Nivåer',
  TrophyGroup.rules: 'Regler-quiz',
  TrophyGroup.sort: 'Sorter rekkefølgen',
  TrophyGroup.photo: 'Gjett fra bilde',
  TrophyGroup.geo: 'Geografi',
  TrophyGroup.pvp: '1v1',
};

const _g = TrophyGroup.general;
const _b = TrophyTier.bronze;
const _s = TrophyTier.silver;
const _gold = TrophyTier.gold;

final trophies = <Trophy>[
  Trophy('first_game', 'Første kamp', 'Spill din første runde', _b, _g, (s) => s.games >= 1),
  Trophy('regular_10', 'Fast gjest', 'Spill 10 runder', _s, _g, (s) => s.games >= 10),
  Trophy('veteran_50', 'Veteran', 'Spill 50 runder', _gold, _g, (s) => s.games >= 50),
  Trophy('marathon_200', 'Maratonløper', 'Spill 200 runder', _gold, _g, (s) => s.games >= 200),
  Trophy('points_100', 'Hundrelappen', 'Samle 100 poeng totalt', _b, _g, (s) => s.totalPoints >= 100),
  Trophy('points_1000', 'Ballkjenner', 'Samle 1 000 poeng totalt', _s, _g, (s) => s.totalPoints >= 1000),
  Trophy('perfect_any', 'Perfekt runde', 'Svar riktig på alt i én runde', _gold, _g,
      (s) => s.perfects >= 1),
  Trophy('allrounder', 'Allrounder', 'Spill alle fire spillmodiene', _s, _g,
      (s) => ['rules_quiz', 'image_sort', 'geo'].every((m) => s.mode(m).games > 0) && s.photoGames > 0),
  Trophy('lvl_5', 'Kaptein', 'Nå nivå 5', _s, TrophyGroup.levels,
      (s) => levelFor(s.totalPoints).level >= 5),
  Trophy('lvl_9', 'Verdensstjerne', 'Nå nivå 9', _gold, TrophyGroup.levels,
      (s) => levelFor(s.totalPoints).level >= 9),
  Trophy('lvl_10', 'Legende', 'Nå nivå 10', _gold, TrophyGroup.levels,
      (s) => levelFor(s.totalPoints).level >= 10),
  Trophy('rules_10', 'Dommerlærling', '10 poeng i én regler-runde', _b, TrophyGroup.rules,
      (s) => s.bestRules >= 10),
  Trophy('rules_16', 'Regelekspert', '16 poeng i én regler-runde', _s, TrophyGroup.rules,
      (s) => s.bestRules >= 16),
  Trophy('rules_perfect', 'Ingen kort', 'Alt riktig i regler-quizen', _gold, TrophyGroup.rules,
      (s) => s.mode('rules_quiz').perfects >= 1),
  Trophy('sort_10', 'Pallplass', '10 poeng i én sorteringsrunde', _b, TrophyGroup.sort,
      (s) => s.bestSort >= 10),
  Trophy('sort_12', 'Tidslinje-mester', '12 poeng i én sorteringsrunde', _s, TrophyGroup.sort,
      (s) => s.bestSort >= 12),
  Trophy('sort_perfect', 'Historiker', 'Alt riktig i sorteringen', _gold, TrophyGroup.sort,
      (s) => s.mode('image_sort').perfects >= 1),
  Trophy('photo_20', 'Skarpt blikk', 'Spill 20 bilderunder', _b, TrophyGroup.photo,
      (s) => s.photoGames >= 20),
  Trophy('photo_players', 'Spillerspeider', '14 poeng i «Gjett spilleren»', _s, TrophyGroup.photo,
      (s) => s.mode('photo_player').best >= 14),
  Trophy('photo_keepers', 'Keepergrep', '14 poeng i «Målvakter»', _gold, TrophyGroup.photo,
      (s) => s.mode('photo_goalkeeper').best >= 14),
  Trophy('photo_countries', 'Globetrotter', '14 poeng i «Hvilket land?»', _s, TrophyGroup.photo,
      (s) => s.mode('photo_country').best >= 14),
  Trophy('photo_stadiums', 'Stadionkjenner', '14 poeng i «Gjett stadionet»', _s, TrophyGroup.photo,
      (s) => s.mode('photo_stadium').best >= 14),
  Trophy('geo_10', 'Rekognosering', '10 poeng i én geografi-runde', _b, TrophyGroup.geo,
      (s) => s.mode('geo').best >= 10),
  Trophy('geo_30', 'Kartleser', '30 poeng i én geografi-runde', _s, TrophyGroup.geo,
      (s) => s.mode('geo').best >= 30),
  Trophy('geo_50', 'Kartmester', '50 poeng i én geografi-runde', _gold, TrophyGroup.geo,
      (s) => s.mode('geo').best >= 50),
  Trophy('geo_perfect', 'Blink i blinkskuddet', 'Full pott i geografi-runden', _gold,
      TrophyGroup.geo, (s) => s.mode('geo').perfects >= 1),
  Trophy('pvp_first', 'Kampklar', 'Spill ditt første 1v1', _b, TrophyGroup.pvp,
      (s) => s.pvpGames >= 1),
  Trophy('pvp_win', 'Første seier', 'Vinn et 1v1-oppgjør', _s, TrophyGroup.pvp,
      (s) => s.pvpWins >= 1),
  Trophy('pvp_10', 'Gladiator', 'Vinn 10 oppgjør', _s, TrophyGroup.pvp, (s) => s.pvpWins >= 10),
  Trophy('pvp_streak', 'På en rekke', 'Vinn 3 oppgjør på rad', _gold, TrophyGroup.pvp,
      (s) => s.pvpBestStreak >= 3),
  Trophy('pvp_king', 'Kongen av banen', 'Vinn 25 oppgjør', _gold, TrophyGroup.pvp,
      (s) => s.pvpWins >= 25),
];

class StatsController extends Notifier<Stats> {
  @override
  Stats build() {
    Future.microtask(_load);
    return const Stats();
  }

  static const _keys = [
    'bestRules', 'bestSort', 'games', 'totalPoints', 'modes',
    'pvpGames', 'pvpWins', 'pvpStreak', 'pvpBestStreak',
  ];

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      state = Stats(
        bestRules: p.getInt('bestRules') ?? 0,
        bestSort: p.getInt('bestSort') ?? 0,
        games: p.getInt('games') ?? 0,
        totalPoints: p.getInt('totalPoints') ?? 0,
        modes: _decodeModes(p.getString('modes')),
        pvpGames: p.getInt('pvpGames') ?? 0,
        pvpWins: p.getInt('pvpWins') ?? 0,
        pvpStreak: p.getInt('pvpStreak') ?? 0,
        pvpBestStreak: p.getInt('pvpBestStreak') ?? 0,
      );
    } catch (_) {}
  }

  static Map<String, ModeStat> _decodeModes(String? raw) {
    if (raw == null) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in m.entries)
          e.key: ModeStat.fromJson(e.value as Map<String, dynamic>)
      };
    } catch (_) {
      return {};
    }
  }

  /// Nullstiller all fremgang på enheten (brukes fra innstillinger).
  Future<void> reset() async {
    state = const Stats();
    try {
      final p = await SharedPreferences.getInstance();
      for (final k in _keys) {
        await p.remove(k);
      }
    } catch (_) {}
  }

  /// Registrerer en ferdig runde. [max] er høyeste mulige poengsum i runden;
  /// full pott gir «perfekt runde». Returnerer true hvis spilleren gikk opp et nivå.
  Future<bool> record(String mode, int points, {int? max}) async {
    final before = state.totalPoints;
    state = state.withResult(mode, points, perfect: max != null && points >= max);
    final up = leveledUp(before, state.totalPoints);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('bestRules', state.bestRules);
      await p.setInt('bestSort', state.bestSort);
      await p.setInt('games', state.games);
      await p.setInt('totalPoints', state.totalPoints);
      await p.setString(
          'modes',
          jsonEncode({
            for (final e in state.modes.entries) e.key: e.value.toJson()
          }));
    } catch (_) {}
    return up;
  }

  /// Registrerer et ferdig 1v1-oppgjør (brukes når 1v1 er på plass).
  Future<void> recordPvp({required bool won}) async {
    state = state.withPvp(won: won);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('pvpGames', state.pvpGames);
      await p.setInt('pvpWins', state.pvpWins);
      await p.setInt('pvpStreak', state.pvpStreak);
      await p.setInt('pvpBestStreak', state.pvpBestStreak);
    } catch (_) {}
  }
}

final statsProvider =
    NotifierProvider<StatsController, Stats>(StatsController.new);

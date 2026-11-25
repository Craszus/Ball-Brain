import 'package:shared_preferences/shared_preferences.dart';

import 'pro.dart';

/// Belønnet reklame, samme ramme som i Logica: frivillig, samtykke første gang, dagsgrenser og
/// av/på i Innstillinger. Annonsen er en TESTANNONSE (ingen ekte annonser, ingen data til noen);
/// belønningen er dobbel XP, som bare teller på enheten og ikke på rangeringene.
///
/// FØR PUBLISERING I BUTIKK: sett [adMode] til `off`, eller koble på en ekte leverandør med
/// samtykkeløsning og aldersregler og oppdater personvernteksten.
const String adMode = 'test'; // 'off' | 'test'

/// Høyst så mange annonser pr. dag.
const adDailyLimit = 3;

/// Høyst så mye bonus-XP fra annonser pr. dag.
const adDailyXp = 60;

/// Annonsen tilbys bare etter hver så mange runder med poeng.
const adEveryRounds = 3;

/// Lengden på testannonsen i sekunder.
const adSeconds = 5;

class Ads {
  static const _consent = 'ads.consent'; // 'yes' | 'no' | mangler = ikke spurt
  static const _day = 'ads.day';
  static const _count = 'ads.count';
  static const _xp = 'ads.xp';
  static const _rounds = 'ads.rounds'; // runder siden forrige tilbud

  static String _today(DateTime? now) {
    final d = now ?? DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  static Future<String?> consent() async =>
      (await SharedPreferences.getInstance()).getString(_consent);

  static Future<void> setConsent(bool yes) async =>
      (await SharedPreferences.getInstance()).setString(_consent, yes ? 'yes' : 'no');

  static Future<int> watchedToday([DateTime? now]) async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_day) == _today(now) ? p.getInt(_count) ?? 0 : 0;
  }

  static Future<int> bonusLeft([DateTime? now]) async {
    final p = await SharedPreferences.getInstance();
    final used = p.getString(_day) == _today(now) ? p.getInt(_xp) ?? 0 : 0;
    return used >= adDailyXp ? 0 : adDailyXp - used;
  }

  /// Kalles én gang etter hver runde. Gir bonusen som skal tilbys nå, eller 0 for ingen annonse.
  static Future<int> offer(int score, [DateTime? now]) async {
    if (score <= 0 || !await available(now)) return 0;
    try {
      final p = await SharedPreferences.getInstance();
      final rounds = (p.getInt(_rounds) ?? 0) + 1;
      await p.setInt(_rounds, rounds >= adEveryRounds ? 0 : rounds);
      if (rounds < adEveryRounds) return 0;
      final left = await bonusLeft(now);
      return score < left ? score : left;
    } catch (_) {
      return 0;
    }
  }

  /// Er det lov å vise en annonse nå?
  static Future<bool> available([DateTime? now]) async {
    if (adMode == 'off') return false;
    try {
      return !await isProActive() &&
          await consent() != 'no' &&
          await watchedToday(now) < adDailyLimit &&
          await bonusLeft(now) > 0;
    } catch (_) {
      return false;
    }
  }

  static Future<void> recordWatched(int xp, [DateTime? now]) async {
    final n = await watchedToday(now) + 1;
    final used = adDailyXp - await bonusLeft(now);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_xp, used + xp);
    await p.setString(_day, _today(now));
    await p.setInt(_count, n);
  }
}

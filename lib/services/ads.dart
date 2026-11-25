import 'package:shared_preferences/shared_preferences.dart';

/// Belønnet reklame, samme ramme som i Logica: frivillig, samtykke første gang, dagsgrense og
/// av/på i Innstillinger. Annonsen er en TESTANNONSE (ingen ekte annonser, ingen data til noen);
/// belønningen er dobbel XP, som bare teller på enheten og ikke på rangeringene.
///
/// FØR PUBLISERING I BUTIKK: sett [adMode] til `off`, eller koble på en ekte leverandør med
/// samtykkeløsning og aldersregler og oppdater personvernteksten.
const String adMode = 'test'; // 'off' | 'test'

/// Høyst så mange annonser pr. dag.
const adDailyLimit = 13;

/// Lengden på testannonsen i sekunder.
const adSeconds = 5;

class Ads {
  static const _consent = 'ads.consent'; // 'yes' | 'no' | mangler = ikke spurt
  static const _day = 'ads.day';
  static const _count = 'ads.count';

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

  /// Skal det tilbys en annonse nå?
  static Future<bool> available([DateTime? now]) async {
    if (adMode == 'off') return false;
    try {
      return await consent() != 'no' && await watchedToday(now) < adDailyLimit;
    } catch (_) {
      return false;
    }
  }

  static Future<void> recordWatched([DateTime? now]) async {
    final n = await watchedToday(now) + 1;
    final p = await SharedPreferences.getInstance();
    await p.setString(_day, _today(now));
    await p.setInt(_count, n);
  }
}

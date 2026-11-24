import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resultatet av [pickFresh]: de valgte elementene og den oppdaterte «sett»-mengden.
typedef FreshPick<T> = ({List<T> picked, Set<String> seen});

/// Velger [n] elementer fra [pool] og tar først de som ikke er vist før ([seen]).
///
/// Når det er for få uviste igjen, tas alle de uviste, resten fylles opp med
/// tilfeldige av de viste, og «sett»-listen for denne puljen nullstilles (en ny runde
/// gjennom alt starter). Med [spread] (f.eks. kategori) blandes valget jevnt på tvers
/// av gruppene i stedet for helt tilfeldig.
///
/// Ren funksjon uten lagring, så den kan testes med en fast [rng].
FreshPick<T> pickFresh<T>(
  List<T> pool,
  int n,
  String Function(T) key,
  Set<String> seen,
  math.Random rng, {
  String Function(T)? spread,
}) {
  final fresh = [for (final p in pool) if (!seen.contains(key(p))) p];
  if (fresh.length >= n) {
    final picked = _spreadPick(fresh, n, rng, spread);
    return (picked: picked, seen: {...seen, ...picked.map(key)});
  }
  final picked = [..._spreadPick(fresh, fresh.length, rng, spread)];
  final rest = [for (final p in pool) if (seen.contains(key(p))) p];
  picked.addAll(_spreadPick(rest, math.min(n - picked.length, rest.length), rng, spread));
  final poolKeys = pool.map(key).toSet();
  return (
    picked: picked,
    seen: {...seen.where((k) => !poolKeys.contains(k)), ...picked.map(key)},
  );
}

/// [n] tilfeldige fra [items]; med [spread] annenhver gruppe (rundgang) så ingen
/// gruppe dominerer.
List<T> _spreadPick<T>(List<T> items, int n, math.Random rng, String Function(T)? spread) {
  final shuffled = [...items]..shuffle(rng);
  if (spread == null || n <= 0) return shuffled.take(n).toList();
  final groups = <String, List<T>>{};
  for (final i in shuffled) {
    groups.putIfAbsent(spread(i), () => []).add(i);
  }
  final order = groups.keys.toList()..shuffle(rng);
  final out = <T>[];
  for (var round = 0; out.length < n; round++) {
    var added = false;
    for (final g in order) {
      final list = groups[g]!;
      if (round < list.length && out.length < n) {
        out.add(list[round]);
        added = true;
      }
    }
    if (!added) break;
  }
  return out;
}

/// Husker lokalt (shared_preferences) hvilke spørsmål og bilder som er vist, så de
/// ikke kommer igjen før alt i puljen er brukt. Én liste per «bøtte» (spillmodus).
class SeenHistory {
  SeenHistory({math.Random? rng}) : _rng = rng ?? math.Random();

  final math.Random _rng;

  static String _prefKey(String bucket) => 'seen.$bucket';

  Future<List<T>> pick<T>(
    String bucket,
    List<T> pool,
    int n,
    String Function(T) key, {
    String Function(T)? spread,
  }) async {
    SharedPreferences? prefs;
    var seen = <String>{};
    try {
      prefs = await SharedPreferences.getInstance();
      seen = (prefs.getStringList(_prefKey(bucket)) ?? const []).toSet();
    } catch (_) {
      prefs = null; // uten lagring: helt tilfeldig, men fortsatt uten duplikater i runden
    }
    final result = pickFresh(pool, n, key, seen, _rng, spread: spread);
    try {
      await prefs?.setStringList(_prefKey(bucket), result.seen.toList());
    } catch (_) {}
    return result.picked;
  }
}

final seenHistoryProvider = Provider<SeenHistory>((ref) => SeenHistory());

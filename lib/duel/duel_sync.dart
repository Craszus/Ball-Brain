import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/stats.dart';
import 'duel_api.dart';

const _recordedKey = 'duel.recorded';

/// Kamper som allerede er telt i statistikken (så de ikke telles to ganger).
Future<Set<String>> recordedDuels() async {
  try {
    return (await SharedPreferences.getInstance()).getStringList(_recordedKey)?.toSet() ?? {};
  } catch (_) {
    return {};
  }
}

/// Teller ett ferdig oppgjør i statistikken (og troféene), bare én gang pr. kamp.
Future<void> recordDuelResult(WidgetRef ref, String id, String? result) async {
  if (result == null) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getStringList(_recordedKey) ?? [];
    if (done.contains(id)) return;
    // Behold de siste 200, mer trengs ikke (listen på serveren dekker 14 dager)
    final next = [...done, id];
    await prefs.setStringList(
        _recordedKey, next.length > 200 ? next.sublist(next.length - 200) : next);
    await ref.read(statsProvider.notifier).recordPvp(won: result == 'win');
  } catch (_) {}
}

/// Teller alle ferdige kamper i [items] som ikke er telt ennå (utfordringer kan bli ferdige
/// mens appen er lukket).
Future<void> recordFinished(WidgetRef ref, List<DuelListItem> items) async {
  for (final i in items) {
    if (i.isFinished) await recordDuelResult(ref, i.id, i.result);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'duel_api.dart';

const acceptsChallengesKey = 'settings.challenges';

/// Om venner kan utfordre meg til 1v1 (på som standard). Lagres på enheten og på serveren.
class ChallengesNotifier extends Notifier<bool> {
  @override
  bool build() {
    Future.microtask(_load);
    return true;
  }

  Future<void> _load() async {
    try {
      final v = (await SharedPreferences.getInstance()).getBool(acceptsChallengesKey);
      if (v != null) state = v;
    } catch (_) {}
  }

  Future<void> set(bool on) async {
    state = on;
    try {
      await (await SharedPreferences.getInstance()).setBool(acceptsChallengesKey, on);
    } catch (_) {}
    await DuelApi.setAcceptsChallenges(on);
  }
}

final acceptsChallengesProvider =
    NotifierProvider<ChallengesNotifier, bool>(ChallengesNotifier.new);

/// Leser det lagrede valget uten Riverpod (brukes ved oppstart).
Future<bool> readAcceptsChallenges() async {
  try {
    return (await SharedPreferences.getInstance()).getBool(acceptsChallengesKey) ?? true;
  } catch (_) {
    return true;
  }
}

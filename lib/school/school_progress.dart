import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lessons.dart';

/// Stempler i Fotballskolen. Lagres bare på telefonen og gir verken XP eller poeng.
class SchoolProgress {
  const SchoolProgress({this.done = const {}, this.perfect = const {}, this.missed = const {}});

  /// Oppgaver (spørsmålsteksten) man har bommet på, til «Dagens tre».
  final Set<String> missed;

  /// Leksjoner man har fullført.
  final Set<String> done;

  /// Leksjoner der alt har vært riktig på første forsøk («fløytemerke»).
  final Set<String> perfect;
}

class SchoolController extends Notifier<SchoolProgress> {
  @override
  SchoolProgress build() {
    Future.microtask(_load);
    return const SchoolProgress();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      state = SchoolProgress(
        done: {...?p.getStringList('school.done'), ...state.done},
        perfect: {...?p.getStringList('school.perfect'), ...state.perfect},
        missed: {...?p.getStringList('school.missed'), ...state.missed},
      );
    } catch (_) {}
  }

  /// Husker bom, og glemmer dem igjen når de besvares riktig på første forsøk.
  Future<void> answered(String prompt, {required bool right}) async {
    final missed = {...state.missed};
    if (right ? !missed.remove(prompt) : !missed.add(prompt)) return;
    state = SchoolProgress(done: state.done, perfect: state.perfect, missed: missed);
    try {
      (await SharedPreferences.getInstance()).setStringList('school.missed', missed.toList());
    } catch (_) {}
  }

  Future<void> finish(String id, {required bool perfect}) async {
    state = SchoolProgress(
      done: {...state.done, id},
      perfect: {...state.perfect, if (perfect) id},
      missed: state.missed,
    );
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList('school.done',
          {...?p.getStringList('school.done'), ...state.done}.toList());
      await p.setStringList('school.perfect',
          {...?p.getStringList('school.perfect'), ...state.perfect}.toList());
    } catch (_) {}
  }
}

/// «Dagens tre»: tre oppgaver fra leksjoner man har tatt – bom først, ellers
/// et utvalg som skifter hver dag.
List<Situation> dailyThree(SchoolProgress progress, int day) {
  final rng = math.Random(day);
  final all = [for (final l in lessons) ...l.situations];
  final missed = [for (final s in all) if (progress.missed.contains(s.prompt)) s]..shuffle(rng);
  final rest = [
    for (final l in lessons)
      if (progress.done.contains(l.id))
        for (final s in l.situations)
          if (!progress.missed.contains(s.prompt)) s
  ]..shuffle(rng);
  return [...missed, ...rest].take(3).toList();
}

final schoolProvider =
    NotifierProvider<SchoolController, SchoolProgress>(SchoolController.new);

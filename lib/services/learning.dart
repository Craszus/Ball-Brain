import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/question.dart';

/// Hva jeg kan og ikke kan: riktige/besvarte pr. tema, og spørsmålene jeg har bommet på.
/// Lagres bare på telefonen. Samles for alle, så statistikken er der hvis man får Pro.
class TopicScore {
  const TopicScore(this.correct, this.total);
  final int correct;
  final int total;
  double get share => total == 0 ? 0 : correct / total;
}

class Learning {
  const Learning({this.topics = const {}, this.missed = const []});

  final Map<String, TopicScore> topics;

  /// [Question.uid] for spørsmål jeg har bommet på og ikke svart riktig på siden.
  final List<String> missed;

  /// Så mange bom huskes (de eldste faller ut).
  static const maxMissed = 200;

  Learning answered(Question q, bool correct) {
    final topic = q.era;
    final old = topics[topic] ?? const TopicScore(0, 0);
    final list = [
      for (final id in missed)
        if (id != q.uid) id,
      if (!correct) q.uid,
    ];
    return Learning(
      topics: {
        ...topics,
        ?topic: TopicScore(old.correct + (correct ? 1 : 0), old.total + 1),
      },
      missed: list.length > maxMissed ? list.sublist(list.length - maxMissed) : list,
    );
  }
}

class LearningController extends Notifier<Learning> {
  static const _topics = 'learn.topics';
  static const _missed = 'learn.missed';

  late Future<void> _ready;

  /// Ferdig når det lagrede er lest inn.
  Future<void> get ready => _ready;

  @override
  Learning build() {
    _ready = Future.microtask(_load);
    return const Learning();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = jsonDecode(p.getString(_topics) ?? '{}') as Map<String, dynamic>;
      state = Learning(
        topics: {
          for (final e in raw.entries)
            e.key: TopicScore((e.value as List)[0] as int, (e.value as List)[1] as int),
        },
        missed: p.getStringList(_missed) ?? const [],
      );
    } catch (_) {}
  }

  Future<void> record(Question q, bool correct) async {
    await _ready;
    state = state.answered(q, correct);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          _topics,
          jsonEncode({
            for (final e in state.topics.entries) e.key: [e.value.correct, e.value.total],
          }));
      await p.setStringList(_missed, state.missed);
    } catch (_) {}
  }

  Future<void> reset() async {
    await _ready;
    state = const Learning();
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_topics);
      await p.remove(_missed);
    } catch (_) {}
  }
}

final learningProvider =
    NotifierProvider<LearningController, Learning>(LearningController.new);

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/question_repository.dart';
import '../models/question.dart';
import '../services/cloud.dart';
import '../services/feedback.dart';
import '../services/scoring.dart';
import '../services/seen_history.dart';
import '../services/stats.dart';

/// Antall spørsmål i en regler-runde.
const quizLength = 10;

/// Verdi for [quizEraProvider] som betyr «Dagens utfordring».
const dailyChallenge = '__daily__';

/// Rekkefølge i en runde: lettest først, så stadig vanskeligere (stabil sortering).
List<Question> easyToHard(List<Question> qs) {
  final indexed = [for (var i = 0; i < qs.length; i++) (i, qs[i])];
  indexed.sort((a, b) {
    final d = a.$2.difficulty.compareTo(b.$2.difficulty);
    return d != 0 ? d : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// Dagens utfordring: de samme spørsmålene (og samme rekkefølge på svarene) for alle
/// samme dag, blandet fra alle temaer.
List<Question> dailyQuestions(List<Question> all, DateTime day) {
  final rng = math.Random(day.year * 10000 + day.month * 100 + day.day);
  final sorted = [...all]..sort((a, b) => a.uid.compareTo(b.uid));
  final picked = pickFresh(sorted, quizLength, (q) => q.uid, const <String>{}, rng,
          spread: (q) => q.era ?? '')
      .picked;
  return [for (final q in easyToHard(picked)) q.withShuffledOptions(rng)];
}

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {
    client = null; // Supabase ikke initialisert → offline-modus
  }
  return QuestionRepository(client);
});

class QuizState {
  const QuizState({
    this.questions = const [],
    this.index = 0,
    this.score = 0,
    this.lastAnswerCorrect,
    this.loading = true,
    this.saved = false,
    this.streak = 0,
  });

  final List<Question> questions;
  final int index;
  final int score;
  final bool? lastAnswerCorrect;
  final bool loading;
  final bool saved;

  /// Riktige svar på rad akkurat nå (vises som «3 PÅ RAD!», gir ikke ekstra poeng).
  final int streak;

  bool get finished => !loading && index >= questions.length;
  Question? get current => finished || loading ? null : questions[index];

  QuizState copyWith({
    List<Question>? questions,
    int? index,
    int? score,
    bool? lastAnswerCorrect,
    bool? loading,
    bool? saved,
    int? streak,
  }) =>
      QuizState(
        questions: questions ?? this.questions,
        index: index ?? this.index,
        score: score ?? this.score,
        lastAnswerCorrect: lastAnswerCorrect,
        loading: loading ?? this.loading,
        saved: saved ?? this.saved,
        streak: streak ?? this.streak,
      );
}

class QuizController extends Notifier<QuizState> {
  final _stopwatch = Stopwatch();
  final _answers = <Map<String, Object?>>[];

  @override
  QuizState build() {
    Future.microtask(start);
    return const QuizState();
  }

  Future<void> start() async {
    _answers.clear();
    state = const QuizState();
    final era = ref.read(quizEraProvider);
    final repo = ref.read(questionRepositoryProvider);
    final List<Question> questions;
    if (era == dailyChallenge) {
      questions = dailyQuestions(await repo.fetchQuestions(limit: 100000), DateTime.now());
    } else {
      // Hele puljen hentes, og uviste spørsmål velges først (huskes mellom rundene).
      final all = await repo.fetchQuestions(era: era, limit: 100000);
      final picked = await ref.read(seenHistoryProvider).pick(
          'rules_quiz', all, quizLength, (q) => q.uid,
          spread: era == null ? (Question q) => q.era ?? '' : null);
      final rng = math.Random();
      questions = [for (final q in easyToHard(picked)) q.withShuffledOptions(rng)];
    }
    state = QuizState(questions: questions, loading: false);
    _stopwatch
      ..reset()
      ..start();
  }

  Future<void> answer(Object answer) async {
    final q = state.current;
    if (q == null) return;
    final correct = q.isCorrect(answer);
    if (answer is int && answer >= 0 && answer < q.options.length) {
      _answers.add({'key': q.key, 'answer': q.options[answer]});
    }
    ref.read(feedbackProvider).play(correct ? Effect.correct : Effect.wrong);
    final points = Scoring.pointsFor(
      correct: correct,
      difficulty: q.difficulty,
      elapsed: _stopwatch.elapsed,
    );
    state = state.copyWith(
      index: state.index + 1,
      score: state.score + points,
      lastAnswerCorrect: correct,
      streak: correct ? state.streak + 1 : 0,
    );
    _stopwatch
      ..reset()
      ..start();
    if (state.finished) {
      ref
          .read(statsProvider.notifier)
          .record('rules_quiz', state.score,
              max: state.questions.length * Scoring.correctPoints)
          .then((up) => Future.delayed(
              const Duration(milliseconds: 500),
              () => ref
                  .read(feedbackProvider)
                  .play(up ? Effect.levelUp : Effect.finish)));
      // Serveren regner ut poengene fra svarene (se supabase/validate_rounds.sql)
      final saved = await Cloud.submitRound('rules_quiz', List.of(_answers));
      state = state.copyWith(saved: saved);
    }
  }
}

final quizControllerProvider =
    NotifierProvider<QuizController, QuizState>(QuizController.new);

/// Valgt tema for regler-quizen (null = alle, [dailyChallenge] = dagens utfordring).
class QuizEraNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? era) => state = era;
}

final quizEraProvider =
    NotifierProvider<QuizEraNotifier, String?>(QuizEraNotifier.new);

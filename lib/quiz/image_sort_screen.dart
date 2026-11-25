import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/question.dart';
import '../services/scoring.dart';
import '../profile_screen.dart' show ResultPanel;
import '../services/cloud.dart';
import '../services/feedback.dart';
import '../services/seen_history.dart';
import '../services/stats.dart';
import '../ui/football.dart';
import '../ui/icon_tile.dart';
import '../ui/theme.dart';
import 'quiz_controller.dart';
import '../l10n/l10n.dart';

/// Antall sorteringsoppgaver per runde.
const sortQuestions = 10;

/// Sorter rekkefølgen: dra elementene i riktig rekkefølge og sjekk svaret.
class ImageSortScreen extends ConsumerStatefulWidget {
  const ImageSortScreen({super.key});

  @override
  ConsumerState<ImageSortScreen> createState() => _ImageSortScreenState();
}

class _ImageSortScreenState extends ConsumerState<ImageSortScreen> {
  List<Question>? _questions;
  int _index = 0;
  int _score = 0;
  final _answers = <Map<String, Object?>>[];
  late List<int> _order; // indekser i brukerens nåværende rekkefølge
  bool? _lastCorrect;
  bool _revealed = false; // fasiten vises før neste oppgave
  DateTime _checkedAt = DateTime.now();
  final _stopwatch = Stopwatch();
  final _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _questions = null;
      _index = 0;
      _score = 0;
      _answers.clear();
      _lastCorrect = null;
      _revealed = false;
    });
    final all = await ref
        .read(questionRepositoryProvider)
        .fetchQuestions(type: QuestionType.imageSort, limit: 100000);
    // Oppgaver som ikke er vist før kommer først (huskes lokalt mellom rundene).
    final qs = await ref
        .read(seenHistoryProvider)
        .pick('image_sort', all, sortQuestions, (q) => q.uid);
    if (!mounted) return;
    setState(() => _questions = qs);
    _startQuestion();
  }

  void _startQuestion() {
    final qs = _questions!;
    if (_index < qs.length) {
      // Stokk startrekkefølgen hver gang (men aldri slik at den allerede er riktig).
      final q = qs[_index];
      do {
        _order = List.generate(q.options.length, (i) => i)..shuffle(_rnd);
      } while (q.options.length > 1 && q.isCorrect(_order));
    }
    _stopwatch
      ..reset()
      ..start();
  }

  void _check() {
    if (_revealed) return;
    final q = _questions![_index];
    final correct = q.isCorrect(_order);
    _answers.add({'key': q.key, 'answer': [for (final i in _order) q.options[i]]});
    ref.read(feedbackProvider).play(correct ? Effect.correct : Effect.wrong);
    final points = Scoring.pointsFor(
      correct: correct,
      difficulty: q.difficulty,
      elapsed: _stopwatch.elapsed,
    );
    setState(() {
      _score += points;
      _lastCorrect = correct;
      _revealed = true;
      _checkedAt = DateTime.now();
      if (!correct) _order = [for (final i in q.correct as List) (i as num).toInt()];
    });
    // siste oppgave: lagre med en gang, i tilfelle man går ut mens fasiten vises
    if (_index == _questions!.length - 1) {
      ref
          .read(statsProvider.notifier)
          .record('image_sort', _score,
              max: _questions!.length * Scoring.correctPoints)
          .then((up) => Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  ref
                      .read(feedbackProvider)
                      .play(up ? Effect.levelUp : Effect.finish);
                }
              }));
      Cloud.submitRound('image_sort', List.of(_answers));
    }
  }

  void _next() {
    // et dobbelttrykk på «Sjekk rekkefølge» skal ikke hoppe over fasiten
    if (DateTime.now().difference(_checkedAt) < const Duration(milliseconds: 600)) return;
    setState(() {
      _revealed = false;
      _lastCorrect = null;
      _index++;
      if (_index < _questions!.length) _startQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final qs = _questions;
    return PitchScaffold(
      title: 'Sorter rekkefølgen',
      actions: [ScoreChip(_score)],
      body: qs == null
          ? const Center(child: CircularProgressIndicator())
          : _index >= qs.length
              ? ResultPanel(
                  score: _score,
                  note: 'Du har sortert alle oppgavene.',
                  onAgain: _load)
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: _question(context, qs[_index], qs.length),
                ),
    );
  }

  Widget _question(BuildContext context, Question q, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _index / total,
            minHeight: 8,
            backgroundColor: Colors.white12,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 8,
          children: [
            Text('OPPGAVE ${_index + 1} AV $total',
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.7))),
            if (_lastCorrect != null)
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_lastCorrect! ? 'RIKTIG!' : 'RIKTIG REKKEFØLGE:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _lastCorrect! ? AppColors.grass : AppColors.gold)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(q.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, height: 1.25)),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ReorderableListView(
            buildDefaultDragHandles: false,
            onReorderItem: (oldIndex, newIndex) {
              if (_revealed) return;
              setState(() {
                _order.insert(newIndex, _order.removeAt(oldIndex));
              });
            },
            children: [
              for (var pos = 0; pos < _order.length; pos++)
                // Dra i hele kortet (rask berøring), ikke bare håndtaket.
                ReorderableDragStartListener(
                  key: ValueKey(_order[pos]),
                  index: pos,
                  enabled: !_revealed,
                  child: Card(
                    color: _revealed ? const Color(0xFF1F6B3A) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          IconTile(
                            size: 42,
                            radius: 12,
                            child: Text('${pos + 1}',
                                style: const TextStyle(fontSize: 20)),
                          ),
                          Expanded(
                            child: Text(q.options[_order[pos]],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 16)),
                          ),
                          Icon(_revealed ? Icons.check : Icons.drag_handle, color: AppColors.gold),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
            onPressed: _revealed ? _next : _check,
            child: Text(_revealed ? 'Neste' : 'Sjekk rekkefølge')),
      ],
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../quiz/quiz_controller.dart';
import '../quiz/rules_quiz_screen.dart';
import '../services/feedback.dart';
import '../services/stats.dart';
import '../ui/football.dart';
import '../ui/theme.dart';
import 'lessons.dart';
import 'comic_screen.dart';
import 'pitch_view.dart';
import 'school_progress.dart';

/// Leksjonen «Dagens tre» gir ikke stempel.
const dailyThreeId = 'daily3';

/// «Fotballskolen – Forstå spillet»: velg leksjon.
class SchoolScreen extends ConsumerWidget {
  const SchoolScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(schoolProvider);
    final daily = dailyThree(progress, StatsController.dayNumber(DateTime.now()));
    return PitchScaffold(
      title: 'Fotballskolen',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          const Text('Forstå spillet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.gold)),
          const SizedBox(height: 4),
          const Text('Ingen XP eller poeng. Bare læring, i ditt eget tempo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (daily.isNotEmpty)
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => LessonScreen(
                      lesson: Lesson(dailyThreeId, 'Dagens tre', '', '',
                          'Repetisjon med mellomrom gjør at kunnskapen sitter lenger.', daily)))),
              icon: const Icon(Icons.refresh),
              label: const Text('Dagens tre'),
            ),
          if (daily.isNotEmpty) const SizedBox(height: 6),
          for (var i = 0; i < lessons.length; i++)
            Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.symmetric(vertical: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.gold),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: AppColors.gold,
                  child: Text('${i + 1}',
                      style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900)),
                ),
                title: Text(lessons[i].title,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                subtitle: Text(lessons[i].subtitle),
                trailing: progress.perfect.contains(lessons[i].id)
                    ? const Icon(Icons.sports, color: AppColors.goldLight, size: 30)
                    : progress.done.contains(lessons[i].id)
                        ? const Icon(Icons.check_circle, color: AppColors.gold, size: 28)
                        : const Icon(Icons.chevron_right, color: AppColors.gold),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => LessonScreen(lesson: lessons[i]))),
              ),
            ),
          const SizedBox(height: 10),
          const Text('Forenklet forklart, og ikke offisiell dommeropplæring.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Én leksjon: svar først, få forklaringen etterpå. Ingen tid og ingen straff.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  int _index = 0;
  bool? _right; // null = ikke svart ennå
  Offset? _mark;
  int? _pickedPlayer;
  int? _pickedOption;
  final _missed = <int>{}; // feil på første forsøk
  final _orders = <int, List<int>>{}; // rekkefølgen på svarene pr. oppgave

  Situation get _s => widget.lesson.situations[_index];

  void _answer(bool right) {
    ref.read(feedbackProvider).play(right ? Effect.correct : Effect.wrong);
    if (!_missed.contains(_index)) {
      ref.read(schoolProvider.notifier).answered(_s.prompt, right: right);
    }
    setState(() {
      _right = right;
      if (!right) _missed.add(_index);
    });
  }

  void _clear() {
    _right = null;
    _mark = null;
    _pickedPlayer = null;
    _pickedOption = null;
  }

  void _next() {
    setState(() {
      _clear();
      _index++;
    });
    if (_index >= widget.lesson.situations.length) {
      if (widget.lesson.id != dailyThreeId) {
        ref.read(schoolProvider.notifier).finish(widget.lesson.id, perfect: _missed.isEmpty);
      }
      ref.read(feedbackProvider).play(Effect.finish);
    }
  }

  void _tapPitch(Offset metres, PitchMap map) {
    if (_right != null) return;
    final task = _s.task;
    if (task is TapPlayer) {
      // nærmeste spiller innen rekkevidde for en finger
      int? best;
      var bestDistance = math.max(30.0, map.scale * 4);
      for (var i = 0; i < _s.players.length; i++) {
        final d = (map.toScreen(_s.players[i].at) - map.toScreen(metres)).distance;
        if (d < bestDistance) {
          best = i;
          bestDistance = d;
        }
      }
      if (best == null) return;
      _pickedPlayer = best;
      _answer(task.isRight(best));
    } else if (task is! Choose) {
      setState(() => _mark = metres);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.lesson.situations.length;
    return PitchScaffold(
      title: widget.lesson.title,
      body: _index >= total ? _finished() : _situation(total),
    );
  }

  Widget _situation(int total) => LayoutBuilder(builder: (context, c) {
        final short = c.maxHeight < 600;
        final head = <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_index + (_right == null ? 0 : 1)) / total,
              minHeight: 8,
              backgroundColor: Colors.black38,
              color: AppColors.gold,
            ),
          ),
          SizedBox(height: short ? 6 : 10),
          Text(_s.prompt,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: short ? 16 : 19, fontWeight: FontWeight.w900, height: 1.2)),
          SizedBox(height: short ? 6 : 10),
        ];
        final pitch = _s.comic != null && _right != null
            ? _comicTeaser(_s.comic!)
            : !_s.pitch
            ? const Center(child: Icon(Icons.sports_soccer, color: AppColors.gold, size: 96))
            : PitchView(
                key: ValueKey('${widget.lesson.id}-$_index'),
                situation: _s,
                reveal: _right != null,
                mark: _mark,
                picked: _right == false ? _pickedPlayer : null,
                onTap: _tapPitch,
              );
        final padding = EdgeInsets.fromLTRB(14, short ? 8 : 14, 14, short ? 8 : 14);
        // Veldig stor tekst eller liggende mobil: da må man kunne rulle.
        if (c.maxHeight < 440 * MediaQuery.textScalerOf(context).scale(1)) {
          return ListView(padding: padding, children: [
            ...head,
            SizedBox(height: _s.pitch || _s.comic != null && _right != null ? 280 : 120, child: pitch),
            const SizedBox(height: 8),
            ..._bottom(short, null),
          ]);
        }
        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...head,
              Expanded(child: pitch),
              SizedBox(height: short ? 6 : 10),
              ..._bottom(short, c.maxHeight * 0.3),
            ],
          ),
        );
      });

  /// Svarene før man har svart, og forklaringen etterpå.
  List<Widget> _bottom(bool short, double? maxExplain) {
    final task = _s.task;
    if (_right == null) {
      return [
        if (task is Choose) _options(task, short),
        if (task is TapPlayer) _hint('Trykk på en spiller på banen'),
        if (task is PlaceSpot || task is PlaceLine || task is PlaceArea) ...[
          if (_mark == null) _hint('Trykk på banen for å sette merket'),
          if (_mark != null)
            FilledButton(
                onPressed: () => _answer(markIsRight(task, _mark!)),
                child: const Text('Bekreft merket')),
        ],
      ];
    }
    final explanation = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_right! ? 'Riktig!' : 'Ikke helt.',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _right! ? AppColors.goldLight : Colors.redAccent)),
        if (task is Choose && !_right!)
          Text('${'Riktig svar:'.tr} ${task.options[task.correct].tr}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(_s.explain, style: const TextStyle(height: 1.3)),
        if (_s.pitch && _s.shot != null)
          const Text('Trykk på banen for å se pasningen igjen.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        if (_s.tip != null) ...[
          const SizedBox(height: 8),
          Text(_s.tipTitle ?? '',
              style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900)),
          Text(_s.tip!, style: const TextStyle(color: AppColors.textSecondary, height: 1.3)),
        ],
      ],
    );
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _right! ? AppColors.gold : Colors.redAccent),
        ),
        child: maxExplain == null
            ? explanation
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxExplain),
                child: SingleChildScrollView(child: explanation),
              ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        if (!_right!) ...[
          Expanded(
            child: OutlinedButton(
                onPressed: () => setState(_clear), child: const Text('Prøv igjen')),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(child: FilledButton(onPressed: _next, child: const Text('Neste'))),
      ]),
    ];
  }

  /// Første rute som smakebit; trykk for hele tegneserien.
  Widget _comicTeaser(Comic comic) => Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: GestureDetector(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => ComicScreen(comic: comic))),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold, width: 2),
                image: DecorationImage(image: AssetImage(comic.panels.first.image), fit: BoxFit.cover),
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.all(6),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => ComicScreen(comic: comic))),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Se tegneserien'),
              ),
            ),
          ),
        ),
      );

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800)),
      );

  /// Ja/nei står side om side, lengre svar under hverandre.
  Widget _options(Choose task, bool short) {
    // ja/nei står fast, ellers stokkes svarene
    final order = _orders.putIfAbsent(_index, () {
      final list = [for (var i = 0; i < task.options.length; i++) i];
      if (task.options.length > 2) list.shuffle();
      return list;
    });
    Widget option(int i) => Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.symmetric(vertical: short ? 2 : 4),
          color: _pickedOption == i ? AppColors.gold.withValues(alpha: 0.3) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.gold),
          ),
          child: InkWell(
            onTap: () {
              _pickedOption = i;
              _answer(i == task.correct);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: short ? 8 : 12),
              child: Text(task.options[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: short ? 14 : 16,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        );
    if (task.options.length == 2) {
      return Row(children: [
        Expanded(child: option(order[0])),
        const SizedBox(width: 8),
        Expanded(child: option(order[1])),
      ]);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final i in order) option(i)],
    );
  }

  Widget _finished() {
    final perfect = _missed.isEmpty;
    final total = widget.lesson.situations.length;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(perfect ? Icons.sports : Icons.check_circle, color: AppColors.gold, size: 80),
        const SizedBox(height: 12),
        const Text('Leksjonen er fullført!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(
            perfect
                ? 'Alt riktig på første forsøk. Du får fløytemerket!'
                : '${total - _missed.length} ${'av'.tr} $total ${'riktige på første forsøk.'.tr}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Text('Visste du at?',
                  style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(widget.lesson.fact,
                  textAlign: TextAlign.center, style: const TextStyle(height: 1.35)),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
            onPressed: () => Navigator.of(context).pop(), child: const Text('Til leksjonene')),
        const SizedBox(height: 8),
        OutlinedButton(
            onPressed: () {
              ref.read(quizEraProvider.notifier).set('Regler');
              ref.invalidate(quizControllerProvider);
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const RulesQuizScreen()));
            },
            child: const Text('Test deg i quizen')),
        const SizedBox(height: 8),
        TextButton(
            onPressed: () => setState(() {
                  _clear();
                  _index = 0;
                  _missed.clear();
                  _orders.clear();
                }),
            child: const Text('Ta leksjonen på nytt')),
      ],
    );
  }
}

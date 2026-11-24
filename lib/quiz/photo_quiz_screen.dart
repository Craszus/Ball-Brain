import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../media/media.dart';
import '../profile_screen.dart' show ResultPanel;
import '../services/cloud.dart';
import '../services/feedback.dart';
import '../services/scoring.dart';
import '../services/seen_history.dart';
import '../services/stats.dart';
import '../ui/credited_photo.dart';
import '../ui/football.dart';
import '../ui/streak_badge.dart';
import '../ui/theme.dart';
import '../l10n/l10n.dart';

const photoQuestions = 10;

enum PhotoMode { mixed, player, goalkeeper, country, stadium }

class _PhotoQuestion {
  _PhotoQuestion(this.item, this.prompt, this.labels, this.correct, this.qtype);
  final MediaItem item;

  /// Hva som spørres om (til serverens fasit): 'name', 'country' eller 'club'.
  final String qtype;
  final String prompt;
  final List<String> labels; // 4 alternativer
  final int correct;
}

/// «Gjett spilleren», «Målvakter», «Hvilket land?» og «Gjett stadionet»: se bildet og velg riktig.
class PhotoQuizScreen extends ConsumerStatefulWidget {
  const PhotoQuizScreen({super.key, this.mode = PhotoMode.mixed});
  final PhotoMode mode;

  @override
  ConsumerState<PhotoQuizScreen> createState() => _PhotoQuizScreenState();
}

class _PhotoQuizScreenState extends ConsumerState<PhotoQuizScreen> {
  List<_PhotoQuestion>? _questions;
  int _index = 0;
  int _score = 0;
  int _streak = 0; // riktige på rad (bare visning)
  int? _picked; // valgt alternativ (indeks) mens vi viser fasit
  final _answers = <Map<String, Object?>>[];
  final _stopwatch = Stopwatch();
  Timer? _next;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _next?.cancel();
    super.dispose();
  }

  final _rnd = math.Random();

  _PhotoQuestion _nameQuestion(MediaItem item, List<MediaItem> pool, String prompt) {
    // Bare spillere av samme kjønn som svaralternativer (ellers blir det for lett).
    var others = pool.where((o) => o.id != item.id && o.female == item.female).toList();
    if (others.length < 3) others = pool.where((o) => o.id != item.id).toList();
    others.shuffle(_rnd);
    final opts = [item, ...others.take(3)]..shuffle(_rnd);
    return _PhotoQuestion(item, prompt, [for (final o in opts) o.name],
        opts.indexWhere((o) => o.id == item.id), 'name');
  }

  /// Fire alternativer der [right] er riktig og resten hentes fra [candidates]
  /// (de første i lista foretrekkes, f.eks. klubber fra samme land).
  _PhotoQuestion _labelQuestion(
      MediaItem item, String prompt, String right, List<String> candidates, String qtype) {
    final wrong = <String>[];
    for (final c in candidates) {
      if (c.isNotEmpty && c != right && !wrong.contains(c)) wrong.add(c);
      if (wrong.length == 3) break;
    }
    final labels = [right, ...wrong]..shuffle(_rnd);
    return _PhotoQuestion(item, prompt, labels, labels.indexOf(right), qtype);
  }

  _PhotoQuestion _countryQuestion(MediaItem item, List<MediaItem> players) {
    final countries = players.map((p) => p.nationality).toSet().toList()..shuffle(_rnd);
    return _labelQuestion(
        item, 'Hvilket land kommer spilleren fra?', item.nationality, countries, 'country');
  }

  /// Variasjon for stadionbilder: navnet, landet eller hjemmeklubben.
  _PhotoQuestion _stadiumQuestion(MediaItem s, List<MediaItem> stadiums) {
    final roll = _rnd.nextInt(10);
    if (roll < 2) {
      final countries = stadiums.map((o) => o.country).toSet().toList()..shuffle(_rnd);
      return _labelQuestion(
          s, 'I hvilket land ligger dette stadionet?', s.country, countries, 'country');
    }
    if (roll < 4 && s.hasClearClub) {
      final clubs = stadiums.where((o) => o.hasClearClub && o.id != s.id).toList()
        ..shuffle(_rnd);
      // Klubber fra samme land først, så blir det ikke for lett.
      clubs.sort((a, b) => (a.country == s.country ? 0 : 1)
          .compareTo(b.country == s.country ? 0 : 1));
      return _labelQuestion(
          s, 'Hvilket lag har hjemmebane her?', s.club, [for (final c in clubs) c.club], 'club');
    }
    return _nameQuestion(s, stadiums, 'Hvilket stadion er dette?');
  }

  _PhotoQuestion _playerQuestion(
      MediaItem p, List<MediaItem> players, List<MediaItem> keepers) {
    final roll = _rnd.nextInt(3);
    if (roll == 0) return _countryQuestion(p, players);
    if (p.goalkeeper && roll == 1) {
      return _nameQuestion(p, keepers, 'Hvilken målvakt er dette?');
    }
    return _nameQuestion(p, players, 'Hvem er dette?');
  }

  /// Bildene som ikke er vist før kommer først (huskes lokalt mellom rundene).
  Future<List<MediaItem>> _fresh(List<MediaItem> pool) => ref
      .read(seenHistoryProvider)
      .pick('photo', pool, photoQuestions, (i) => '${i.kind.name}:${i.id}');

  Future<void> _load() async {
    setState(() {
      _questions = null;
      _index = 0;
      _score = 0;
      _streak = 0;
      _picked = null;
      _answers.clear();
    });
    final m = widget.mode;
    final needPlayers = m != PhotoMode.stadium;
    final needStadiums = m == PhotoMode.stadium || m == PhotoMode.mixed;
    final players = needPlayers ? await loadPlayers() : <MediaItem>[];
    final stadiums = needStadiums ? await loadStadiums() : <MediaItem>[];
    final keepers = players.where((p) => p.goalkeeper).toList();
    final qs = <_PhotoQuestion>[];
    switch (m) {
      case PhotoMode.player:
        for (final p in await _fresh(players)) {
          qs.add(_nameQuestion(p, players, 'Hvem er dette?'));
        }
      case PhotoMode.goalkeeper:
        for (final p in await _fresh(keepers)) {
          qs.add(_nameQuestion(p, keepers, 'Hvilken målvakt er dette?'));
        }
      case PhotoMode.country:
        for (final p in await _fresh(players)) {
          qs.add(_countryQuestion(p, players));
        }
      case PhotoMode.stadium:
        for (final s in await _fresh(stadiums)) {
          qs.add(_stadiumQuestion(s, stadiums));
        }
      case PhotoMode.mixed:
        for (final item in await _fresh([...players, ...stadiums])) {
          qs.add(item.kind == MediaKind.stadium
              ? _stadiumQuestion(item, stadiums)
              : _playerQuestion(item, players, keepers));
        }
    }
    if (!mounted) return;
    setState(() => _questions = qs);
    _stopwatch
      ..reset()
      ..start();
  }

  void _answer(int i) {
    if (_picked != null) return;
    final q = _questions![_index];
    final correct = i == q.correct;
    _answers.add({
      'item': '${q.item.kind.name}:${q.item.id}',
      'q': q.qtype,
      'answer': q.labels[i],
    });
    ref.read(feedbackProvider).play(correct ? Effect.correct : Effect.wrong);
    final points = Scoring.pointsFor(
        correct: correct, difficulty: 1, elapsed: _stopwatch.elapsed);
    setState(() {
      _picked = i;
      _score += points;
      _streak = correct ? _streak + 1 : 0;
    });
    _next = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _index++;
        _picked = null;
      });
      if (_index < _questions!.length) {
        _stopwatch
          ..reset()
          ..start();
      } else {
        Cloud.submitPhoto('photo_${widget.mode.name}', List.of(_answers));
        ref.read(statsProvider.notifier).record('photo_${widget.mode.name}', _score,
            max: photoQuestions * Scoring.correctPoints).then((up) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ref.read(feedbackProvider).play(up ? Effect.levelUp : Effect.finish);
            }
          });
        });
      }
    });
  }

  String get _title => switch (widget.mode) {
        PhotoMode.player => 'Gjett spilleren',
        PhotoMode.goalkeeper => 'Målvakter',
        PhotoMode.country => 'Hvilket land?',
        PhotoMode.stadium => 'Gjett stadionet',
        PhotoMode.mixed => 'Gjett fra bilde',
      };

  @override
  Widget build(BuildContext context) {
    final qs = _questions;
    return PitchScaffold(
      title: _title,
      actions: [ScoreChip(_score)],
      body: qs == null
          ? const Center(child: CircularProgressIndicator())
          : qs.isEmpty
              ? const Center(child: Text('Ingen bilder funnet.'))
              : _index >= qs.length
                  ? ResultPanel(
                      score: _score,
                      note: 'Du har gjettet alle bildene.',
                      onAgain: _load)
                  : _question(qs[_index], qs.length),
    );
  }

  Widget _question(_PhotoQuestion q, int total) {
    final isPlayer = q.item.kind == MediaKind.player;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _index / total,
            minHeight: 8,
            backgroundColor: Colors.black38,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 8),
        Text('BILDE ${_index + 1} AV $total',
            style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary)),
        StreakBadge(_streak),
        const SizedBox(height: 12),
        Text(q.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        CreditedPhoto(
          key: ValueKey(q.item.id),
          photo: q.item.photo,
          height: isPlayer ? 300 : 220,
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < q.labels.length; i++) _option(q, i),
      ],
    );
  }

  Widget _option(_PhotoQuestion q, int i) {
    final answered = _picked != null;
    final isRight = i == q.correct;
    final isPicked = _picked == i;
    Color border = AppColors.gold;
    Color? fill;
    if (answered && isRight) {
      border = AppColors.grass;
      fill = AppColors.grass.withValues(alpha: 0.35);
    } else if (answered && isPicked) {
      border = Colors.redAccent;
      fill = Colors.redAccent.withValues(alpha: 0.3);
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      color: fill,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border, width: answered && (isRight || isPicked) ? 2 : 1),
      ),
      child: InkWell(
        onTap: answered ? null : () => _answer(i),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Text(q.labels[i],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

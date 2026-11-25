import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../services/stats.dart';
import '../ui/answer_button.dart';
import '../ui/football.dart';
import '../ui/theme.dart';
import 'club_api.dart';
import 'club_badge.dart';

String clockText(int ms) {
  final s = (ms / 1000).ceil().clamp(0, 1 << 30);
  if (s >= 3600) return '${s ~/ 3600} t ${(s % 3600) ~/ 60} min';
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Statuslinjen for en kamp (brukes i listen og på kampskjermen).
String clubGameStatus(ClubGame g) {
  switch (g.status) {
    case 'invited':
      return g.away.mine && !g.home.mine ? 'Dere er utfordret!' : 'Venter på svar';
    case 'declined':
      return 'Avslått';
    case 'cancelled':
      return 'Trukket';
    case 'expired':
      return 'Utløpt uten svar';
    case 'finished':
      if (g.winner == null) return 'Uavgjort';
      return 'Vinner: ${g.winner == g.home.id ? g.home.name : g.away.name}';
  }
  final now = g.nowMs;
  if (now < g.kickoffMs) return 'Avspark om ${clockText(g.kickoffMs - now)}';
  if (now < g.endsMs) return 'Kampen pågår: ${clockText(g.endsMs - now)} igjen';
  return 'Teller opp …';
}

/// Én klubbkamp: lagoppstilling, påmelding, nedtelling, stilling og resultat.
class ClubGameScreen extends StatefulWidget {
  const ClubGameScreen({super.key, required this.gameId, this.load = ClubApi.games});

  final String gameId;
  final Future<List<ClubGame>> Function() load;

  @override
  State<ClubGameScreen> createState() => _ClubGameScreenState();
}

class _ClubGameScreenState extends State<ClubGameScreen> {
  ClubGame? _game;
  bool _loading = true;
  Timer? _tick;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    _load();
    // Nedtellingen tegnes hvert sekund; stillingen hentes hvert tredje.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (++_ticks % 3 == 0 && !(_game?.over ?? false)) _load();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final games = await widget.load();
      if (!mounted) return;
      setState(() {
        _game = games.where((g) => g.id == widget.gameId).firstOrNull ?? _game;
        _loading = false;
      });
      _record();
    } on ClubError {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Teller en ferdig kamp jeg spilte i, én gang (pokalene for klubbkamp).
  void _record() {
    final g = _game;
    if (g == null || g.status != 'finished') return;
    final me = g.players.where((p) => p.isMe).firstOrNull;
    if (me == null) return;
    try {
      final stats = ProviderScope.containerOf(context, listen: false).read(statsProvider.notifier);
      stats.bump('clubPlayed', once: 'club-play-${g.id}').then((_) {
        if (g.winner == me.club) stats.bump('clubWins', once: 'club-win-${g.id}');
      });
    } catch (_) {}
  }

  Future<void> _act(Future<void> Function() action) async {
    try {
      await action();
    } on ClubError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(clubError(e.key))));
      }
    }
    await _load();
  }

  Future<void> _play(ClubGame g) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => ClubPlayScreen(gameId: g.id)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final g = _game;
    return PitchScaffold(
      title: 'Klubbkamp'.tr,
      body: g == null
          ? Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Kunne ikke nå serveren. Sjekk nettet.'))
          : ListView(padding: const EdgeInsets.all(16), children: [
              _scoreBoard(g),
              const SizedBox(height: 8),
              Text(clubGameStatus(g),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.gold)),
              Text('${g.size} mot ${g.size} · frist ${g.windowMin} min',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ..._actions(g),
              _team(g, g.home),
              _team(g, g.away),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                    'Lagkameratene får forskjellige spørsmål. 10 sekunder pr. spørsmål. '
                    'Størst samlet pott vinner.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ]),
    );
  }

  Widget _scoreBoard(ClubGame g) {
    Widget side(ClubInfo c) => Expanded(
          child: Column(children: [
            ClubBadge(c, size: 56),
            const SizedBox(height: 4),
            Text(c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('${g.pot(c.id)}',
                style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: g.winner == c.id ? AppColors.gold : Colors.white)),
          ]),
        );
    return Row(children: [side(g.home), const Text('–'), side(g.away)]);
  }

  List<Widget> _actions(ClubGame g) {
    final out = <Widget>[];
    void add(Widget w) => out.add(Padding(padding: const EdgeInsets.only(bottom: 8), child: w));
    if (g.invited && g.away.mine) {
      add(FilledButton(
          onPressed: () => _act(() => ClubApi.respond(g.id, true)),
          child: const Text('Godta utfordringen')));
      add(OutlinedButton(
          onPressed: () => _act(() => ClubApi.respond(g.id, false)), child: const Text('Avslå')));
    }
    if (g.canPlay) {
      add(FilledButton.icon(
          onPressed: () => _play(g),
          icon: const Icon(Icons.sports_soccer),
          label: const Text('Spill nå')));
    }
    final open = !g.over && g.nowMs < g.endsMs;
    if (open && g.me == null) {
      for (final c in [g.home, g.away]) {
        final joinable = c.mine &&
            g.team(c.id).length < g.size &&
            (g.status == 'accepted' || c.id == g.home.id);
        if (joinable) {
          add(FilledButton(
              onPressed: () => _act(() => ClubApi.join(g.id, c.id)),
              child: Text('Bli med på laget til ${c.name}')));
        }
      }
    }
    if (open && g.me != null && g.me!.answered == 0 && g.nowMs < g.kickoffMs) {
      add(TextButton(
          onPressed: () => _act(() => ClubApi.leave(g.id)), child: const Text('Meld meg av')));
    }
    if (g.invited && g.home.mine) {
      add(TextButton(
          onPressed: () => _act(() => ClubApi.cancel(g.id)),
          child: const Text('Trekk utfordringen')));
    }
    return out;
  }

  Widget _team(ClubGame g, ClubInfo club) {
    final players = g.team(club.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(club.name,
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.gold)),
          for (var i = 0; i < g.size; i++)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: i < players.length
                  ? Row(children: [
                      Expanded(
                          child: Text(
                              players[i].isMe
                                  ? '${players[i].name} (${'Deg'.tr})'
                                  : players[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)),
                      Text('${players[i].answered}/10',
                          style: const TextStyle(color: AppColors.textSecondary)),
                      SizedBox(
                        width: 56,
                        child: Text('${players[i].score}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ])
                  : const Text('Ledig plass',
                      style: TextStyle(color: AppColors.textSecondary)),
            ),
        ]),
      ),
    );
  }
}

/// Mine ti spørsmål, ett om gangen, 10 sekunder på hvert. Serveren tar tiden.
class ClubPlayScreen extends StatefulWidget {
  const ClubPlayScreen(
      {super.key, required this.gameId, this.next = ClubApi.next, this.answer = ClubApi.answer});

  final String gameId;
  final Future<ClubQuestion?> Function(String) next;
  final Future<ClubAnswer> Function(String, int, String?) answer;

  @override
  State<ClubPlayScreen> createState() => _ClubPlayScreenState();
}

class _ClubPlayScreenState extends State<ClubPlayScreen> {
  ClubQuestion? _q;
  ClubAnswer? _result;
  String? _picked;
  int _score = 0;
  bool _done = false;
  String? _error;
  DateTime _deadline = DateTime.now();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _next();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int get _leftMs => _deadline.difference(DateTime.now()).inMilliseconds.clamp(0, 10000);

  Future<void> _next() async {
    try {
      final q = await widget.next(widget.gameId);
      if (!mounted) return;
      setState(() {
        _q = q;
        _result = null;
        _picked = null;
        _done = q == null;
      });
      if (q == null) return;
      _deadline = DateTime.now().add(Duration(milliseconds: q.remainingMs));
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) return;
        if (_picked == null && _leftMs == 0) {
          _send(null);
        } else {
          setState(() {});
        }
      });
    } on ClubError catch (e) {
      if (mounted) setState(() => _error = clubError(e.key));
    }
  }

  Future<void> _send(String? option) async {
    final q = _q;
    if (q == null || _picked != null) return;
    _ticker?.cancel();
    setState(() => _picked = option ?? '');
    try {
      final r = await widget.answer(widget.gameId, q.idx, option);
      if (!mounted) return;
      setState(() {
        _result = r;
        _score += r.points;
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) await _next();
    } on ClubError catch (e) {
      if (mounted) setState(() => _error = clubError(e.key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _q;
    return PitchScaffold(
      title: 'Klubbkamp'.tr,
      actions: [ScoreChip(_score)],
      body: _error != null || _done
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error ?? 'Ferdig! Du ga laget $_score poeng.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  FilledButton(
                      onPressed: () => Navigator.pop(context), child: const Text('Til kampen')),
                ]),
              ),
            )
          : q == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.all(20), children: [
                  LinearProgressIndicator(
                    value: _picked == null ? _leftMs / 10000 : 0,
                    minHeight: 8,
                    backgroundColor: Colors.black38,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 8),
                  Text('SPØRSMÅL ${q.idx + 1} AV ${q.total}',
                      style: const TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(q.prompt,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900, height: 1.25)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < q.options.length; i++)
                    AnswerButton(
                      letter: String.fromCharCode(65 + i),
                      label: q.options[i],
                      onTap: () => _send(q.options[i]),
                    ),
                  if (_result != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                          _result!.correct
                              ? 'Riktig! +${_result!.points}'
                              : 'Riktig svar: ${_result!.right.tr}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _result!.correct ? AppColors.gold : Colors.white)),
                    ),
                ]),
    );
  }
}

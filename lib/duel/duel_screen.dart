import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../groups_view.dart' show GroupsView;
import '../l10n/l10n.dart';
import '../services/feedback.dart';
import '../services/profile.dart';
import '../ui/football.dart';
import '../ui/gold_button.dart';
import '../ui/icon_tile.dart';
import '../ui/theme.dart';
import 'duel_api.dart';
import 'duel_history.dart';
import 'duel_sync.dart';

const _secondsPerQuestion = 15;

enum _Phase { menu, joining, lobby, countdown, play, waitOpp, done }

String duelError(String key) => switch (key) {
      'not_found' => 'Fant ingen kamp med den koden.',
      'own_duel' => 'Du kan ikke bli med i din egen kamp.',
      'daily_limit' => 'Du har spilt maks antall oppgjør i dag.',
      'no_profile' => 'Lagre profilen din først.',
      'cancelled' => 'Kampen ble avbrutt.',
      'self' => 'Du kan ikke utfordre deg selv.',
      'not_shared' => 'Dere må være i samme gruppe for å utfordre.',
      'not_accepting' => 'Spilleren tar ikke imot utfordringer.',
      'too_many' => 'Du har allerede fem åpne utfordringer.',
      'already' => 'Du har allerede en åpen utfordring til denne spilleren.',
      'already_played' => 'Du har allerede spilt denne utfordringen.',
      _ => 'Krever internett. Sjekk nettet og prøv igjen.',
    };

/// 1v1: to spillere får de samme ti spørsmålene. Serveren styrer tid, poeng og vinner.
class DuelScreen extends ConsumerStatefulWidget {
  const DuelScreen({super.key});

  @override
  ConsumerState<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends ConsumerState<DuelScreen> {
  _Phase _phase = _Phase.menu;
  int _tab = 0; // 0 = 1v1, 1 = klubbkamp
  DuelSummary? _d;
  List<DuelQuestion> _qs = const [];
  int _qi = 0;
  String? _picked; // valgt tekst ('' = tiden gikk ut)
  DuelAnswerResult? _result;
  int _myScore = 0;
  DateTime _qStart = DateTime.now();
  int _remainingMs = _secondsPerQuestion * 1000;
  bool _answering = false;
  List<DuelListItem> _items = const [];
  Timer? _listTimer;

  Timer? _ticker;
  Timer? _poll;
  void Function()? _unwatch;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadList();
    // Utfordringer kan komme eller bli ferdige mens menyen er åpen
    _listTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_phase == _Phase.menu) _loadList();
    });
  }

  @override
  void dispose() {
    _listTimer?.cancel();
    _stopAll();
    super.dispose();
  }

  Future<void> _loadList() async {
    try {
      final items = await DuelApi.myDuels();
      if (!mounted) return;
      setState(() => _items = items);
      await recordFinished(ref, items);
    } on DuelError {
      // uten nett: ingen liste
    }
  }

  Future<void> _playChallenge(DuelListItem item) async {
    await _begin(() => DuelApi.startMine(item.id));
  }

  Future<void> _removeChallenge(DuelListItem item, {bool decline = false}) async {
    if (decline) {
      await DuelApi.decline(item.id);
    } else {
      await DuelApi.remove(item.id);
    }
    await _loadList();
  }

  void _stopAll() {
    _ticker?.cancel();
    _poll?.cancel();
    _unwatch?.call();
    _ticker = _poll = null;
    _unwatch = null;
  }

  void _toMenu([String? errorKey]) {
    _stopAll();
    if (!mounted) return;
    setState(() {
      _phase = _Phase.menu;
      _d = null;
      _qs = const [];
      _qi = 0;
      _picked = null;
      _result = null;
      _myScore = 0;
      _answering = false;
    });
    if (errorKey != null) _snack(duelError(errorKey));
    _loadList();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // --- Starte og vente ----------------------------------------------------

  Future<void> _begin(Future<DuelSummary> Function() find) async {
    setState(() => _phase = _Phase.joining);
    try {
      await _enter(await find());
    } on DuelError catch (e) {
      _toMenu(e.key);
    }
  }

  Future<void> _askCode() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bli med med kode'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 5,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: 'Kode'.tr),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Avbryt')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Bli med')),
        ],
      ),
    );
    if (code == null || code.isEmpty || !mounted) return;
    _begin(() => DuelApi.join(code));
  }

  Future<void> _enter(DuelSummary d) async {
    _d = d;
    _unwatch?.call();
    _unwatch = DuelApi.watch(d.id, _refresh);
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
    if (d.isActive) {
      await _countdown(d);
    } else if (d.isFinished) {
      setState(() => _phase = _Phase.done);
    } else {
      setState(() => _phase = _Phase.lobby);
    }
  }

  Future<void> _countdown(DuelSummary d) async {
    try {
      final qs = await DuelApi.questions(d.id);
      if (!mounted) return;
      setState(() {
        _d = d;
        _qs = qs;
        _myScore = d.me.score;
        _phase = _Phase.countdown;
      });
    } on DuelError catch (e) {
      _toMenu(e.key);
      return;
    }
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final dd = _d;
      if (dd == null || !mounted) return;
      if (dd.msUntilStart() <= 0) {
        _ticker?.cancel();
        // Gjenopptatt kamp: fortsett på første ubesvarte spørsmål; tiden går fra forrige svar + 1 s
        final i = dd.me.answered;
        final late = -dd.msUntilStart() - (i > 0 ? 1000 : 0);
        if (i >= _qs.length) {
          setState(() => _phase = _Phase.waitOpp);
        } else {
          _showQuestion(i,
              startedAt: DateTime.now().subtract(Duration(milliseconds: late > 0 ? late : 0)));
        }
      } else {
        setState(() {});
      }
    });
  }

  /// Henter siste status (kalles av Realtime og hvert 2. sekund).
  Future<void> _refresh() async {
    final d0 = _d;
    if (d0 == null || _refreshing || !mounted) return;
    _refreshing = true;
    try {
      final d = await DuelApi.get(d0.id);
      if (!mounted) return;
      if (d.status == 'cancelled') {
        _toMenu('cancelled');
        return;
      }
      final before = _phase;
      setState(() => _d = d);
      if (before == _Phase.lobby && d.isActive) {
        await _countdown(d);
      } else if ((before == _Phase.waitOpp || before == _Phase.play) && d.isFinished) {
        _finish();
      }
    } on DuelError {
      // midlertidig nettfeil: prøver igjen ved neste runde
    } finally {
      _refreshing = false;
    }
  }

  // --- Spill ----------------------------------------------------------------

  void _showQuestion(int i, {DateTime? startedAt}) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.play;
      _qi = i;
      _picked = null;
      _result = null;
      _answering = false;
      _qStart = startedAt ?? DateTime.now();
      _remainingMs = _secondsPerQuestion * 1000;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _answering) return;
      final left = _secondsPerQuestion * 1000 - DateTime.now().difference(_qStart).inMilliseconds;
      if (left <= 0) {
        _answer(null);
      } else {
        setState(() => _remainingMs = left);
      }
    });
  }

  Future<void> _answer(String? text) async {
    final d = _d;
    if (d == null || _answering || _qi >= _qs.length) return;
    _answering = true;
    _ticker?.cancel();
    setState(() {
      _picked = text ?? '';
      _remainingMs = text == null ? 0 : _remainingMs;
    });
    DuelAnswerResult? r;
    final pause = Future.delayed(const Duration(milliseconds: 1000));
    for (var attempt = 0; attempt < 3 && r == null; attempt++) {
      try {
        r = await DuelApi.answer(d.id, _qi, text);
      } on DuelError catch (e) {
        if (e.key == 'offline' && attempt < 2) {
          await Future.delayed(const Duration(seconds: 1));
        } else {
          _toMenu(e.key == 'offline' ? 'offline' : 'cancelled');
          return;
        }
      }
    }
    if (r == null || !mounted) return;
    ref.read(feedbackProvider).play(r.correct ? Effect.correct : Effect.wrong);
    setState(() {
      _result = r;
      _myScore += r!.points;
    });
    await pause;
    if (!mounted) return;
    if (_qi + 1 < _qs.length) {
      _showQuestion(_qi + 1);
    } else {
      setState(() => _phase = _Phase.waitOpp);
      _refresh();
    }
  }

  void _finish() {
    _ticker?.cancel();
    final d = _d;
    if (d == null) return;
    if (_phase != _Phase.done) {
      recordDuelResult(ref, d.id, d.result);
      ref.read(feedbackProvider).play(d.result == 'win' ? Effect.levelUp : Effect.finish);
    }
    setState(() => _phase = _Phase.done);
  }

  // --- Avslutte ---------------------------------------------------------------

  Future<void> _confirmLeave() async {
    if (_phase == _Phase.lobby) {
      final id = _d?.id;
      if (id != null) await DuelApi.cancel(id);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forlate kampen?'),
        content: const Text('Du taper hvis du går ut.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Forlat')),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  // --- Bygg ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final canLeave = _phase == _Phase.menu ||
        _phase == _Phase.done ||
        _phase == _Phase.joining ||
        (_phase == _Phase.waitOpp && (_d?.isChallenge ?? false));
    return PopScope(
      canPop: canLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: PitchScaffold(
        title: 'Kamper',
        actions: _phase == _Phase.play ? [ScoreChip(_myScore)] : null,
        body: switch (_phase) {
          _Phase.menu => _tabs(),
          _Phase.joining => const Center(child: CircularProgressIndicator()),
          _Phase.lobby => _lobby(),
          _Phase.countdown => _countdownView(),
          _Phase.play => _play(),
          _Phase.waitOpp => _waiting(),
          _Phase.done => _doneView(),
        },
      ),
    );
  }

  Widget _tabs() => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            segments: const [
              ButtonSegment(value: 0, icon: Icon(Icons.sports_mma), label: Text('1v1')),
              ButtonSegment(value: 1, icon: Icon(Icons.shield_outlined), label: Text('Klubbkamp')),
            ],
            selected: {_tab},
            onSelectionChanged: (v) => setState(() => _tab = v.first),
          ),
        ),
        Expanded(child: _tab == 0 ? _menu() : const GroupsView()),
      ]);

  Widget _menu() {
    final rules = const [
      '10 spørsmål, 15 sekunder per spørsmål. Begge får de samme spørsmålene.',
      'Riktig svar gir 10 poeng, pluss opptil 5 for fart. Feil svar og tom tid gir 0.',
      'Høyest poengsum vinner. Likt? Da vinner den som var raskest.',
      'Du må være på nett.',
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ..._challengeSection(),
        const Text('Utfordre en annen spiller',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final r in rules)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('•  ', style: TextStyle(color: AppColors.gold)),
                    Expanded(child: Text(r, style: const TextStyle(height: 1.3))),
                  ]),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        GoldButton(label: 'Finn motstander', onPressed: () => _begin(DuelApi.find)),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _begin(DuelApi.createPrivate),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Utfordre en venn'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _askCode,
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Bli med med kode'),
        ),
      ],
    );
  }

  List<Widget> _challengeSection() {
    if (_items.isEmpty) return const [];
    // Her vises bare det som pågår; ferdige kamper oppsummeres i ett kort.
    final open = _items.where((i) => !i.isFinished).take(8).toList();
    return [
      if (open.isNotEmpty) ...[
        const Text('Utfordringer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.gold)),
        const SizedBox(height: 6),
        for (final i in open) _challengeTile(i),
      ],
      LastOpponentCard(items: _items, onOpenHistory: _openHistory),
      const SizedBox(height: 18),
    ];
  }

  void _openHistory() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) =>
          DuelHistoryScreen(items: _items, onRemove: _removeChallenge, reload: () => _items),
    ));
  }

  Widget _challengeTile(DuelListItem i) {
    final String title;
    String? sub;
    final actions = <Widget>[];
    Widget btn(String label, VoidCallback onTap, {bool filled = false}) => filled
        ? FilledButton(onPressed: onTap, child: Text(label))
        : TextButton(onPressed: onTap, child: Text(label));

    if (i.isDeclined) {
      title = '${i.opponent} avslo utfordringen.';
      actions.add(btn('Fjern', () => _removeChallenge(i)));
    } else if (i.needsMyAnswer) {
      title = '${i.opponent} utfordrer deg';
      final left = i.timeLeft();
      if (left != null) sub = 'Utløper om ${left.inHours.clamp(0, 48)} t';
      actions
        ..add(btn('Avslå', () => _removeChallenge(i, decline: true)))
        ..add(btn('Spill', () => _playChallenge(i), filled: true));
    } else if (!i.myDone) {
      title = 'Din tur mot ${i.opponent}';
      actions
        ..add(btn('Avslutt', () => _removeChallenge(i)))
        ..add(btn('Spill', () => _playChallenge(i), filled: true));
    } else {
      title = 'Venter på ${i.opponent}';
      sub = '${i.myScore} poeng';
      actions.add(btn('Avslutt', () => _removeChallenge(i)));
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (sub != null)
            Text(sub, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
        ]),
      ),
    );
  }

  Widget _lobby() {
    final code = _d?.code;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text('Leter etter en motstander …',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          if (code != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Text(code,
                      style: const TextStyle(
                          fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 8)),
                  const SizedBox(height: 6),
                  const Text('Del koden med vennen din. Kampen starter når vedkommende blir med.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary)),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: '${'Utfordring i Ball Brain! Kode'.tr}: $code'));
                      _snack('Kopiert');
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Kopier'),
                  ),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton(onPressed: _confirmLeave, child: const Text('Avbryt')),
        ]),
      ),
    );
  }

  Widget _countdownView() {
    final d = _d!;
    final secs = (d.msUntilStart() / 1000).ceil().clamp(0, 9);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Mot ${d.opp?.name ?? ''}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        const Text('Kampen starter om', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Text('$secs',
            style: const TextStyle(fontSize: 96, fontWeight: FontWeight.w900, color: AppColors.gold)),
      ]),
    );
  }

  Widget _scoreBox(String name, int score, String sub, {bool me = false}) => Expanded(
        child: Card(
          color: me ? AppColors.gold.withValues(alpha: 0.18) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: me ? AppColors.gold : AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Column(children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              Text('$score',
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.gold)),
              Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
        ),
      );

  Widget _play() {
    final q = _qs[_qi];
    final d = _d!;
    final opp = d.opp;
    final profile = ref.watch(profileProvider);
    final right = _result?.right;
    final left = _remainingMs / (_secondsPerQuestion * 1000);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          _scoreBox(profile.name.isEmpty ? 'Deg'.tr : profile.name, _myScore,
              '$_qi/${_qs.length}',
              me: true),
          const SizedBox(width: 8),
          _scoreBox(opp?.name ?? '', opp?.score ?? 0, '${opp?.answered ?? 0}/${_qs.length}'),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: left.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.black38,
            color: _remainingMs < 5000 ? Colors.redAccent : AppColors.gold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${'Spørsmål'.tr.toUpperCase()} ${_qi + 1}/${_qs.length}'
          '${q.era != null ? '  ·  ${q.era!.tr.toUpperCase()}' : ''}',
          style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(q.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.25)),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < q.options.length; i++)
          _Option(
            letter: String.fromCharCode(65 + i),
            label: q.options[i],
            state: _optionState(q.options[i], right),
            onTap: _answering ? null : () => _answer(q.options[i]),
          ),
      ],
    );
  }

  _OptionState _optionState(String option, String? right) {
    if (right == null) return _picked == null ? _OptionState.idle : _OptionState.pending;
    if (option == right) return _OptionState.right;
    if (option == _picked) return _OptionState.wrong;
    return _OptionState.dim;
  }

  Widget _waiting() {
    final opp = _d?.opp;
    if (_d?.isChallenge ?? false) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$_myScore',
                style:
                    const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: AppColors.gold)),
            const Text('poeng', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Text('Resultatet kommer når ${opp?.name ?? ''} har spilt.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            GoldButton(label: 'Tilbake til 1v1', onPressed: _toMenu),
          ]),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_myScore',
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: AppColors.gold)),
          const Text('poeng', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Venter på motstanderen …',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('${opp?.name ?? ''}  ${opp?.answered ?? 0}/${_qs.length}',
              style: const TextStyle(color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _doneView() {
    final d = _d;
    final result = d?.result;
    final (title, note, color) = switch (result) {
      'win' => ('SEIER!', 'Du vant duellen', AppColors.gold),
      'loss' => ('TAP', 'Du tapte denne gangen', Colors.redAccent),
      'draw' => ('UAVGJORT', 'Likt resultat', Colors.white),
      _ => ('FERDIG', 'Kampen er avsluttet', Colors.white),
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(note, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 20),
          if (d != null)
            Row(children: [
              _scoreBox(d.me.name, d.me.score, '${d.me.correct} ${'riktige'.tr}', me: true),
              const SizedBox(width: 8),
              _scoreBox(d.opp?.name ?? '', d.opp?.score ?? 0, '${d.opp?.correct ?? 0} ${'riktige'.tr}'),
            ]),
          const SizedBox(height: 24),
          GoldButton(label: 'Spill igjen', onPressed: _toMenu),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tilbake'),
          ),
        ]),
      ),
    );
  }
}

enum _OptionState { idle, pending, right, wrong, dim }

class _Option extends StatelessWidget {
  const _Option(
      {required this.letter, required this.label, required this.state, required this.onTap});

  final String letter;
  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (border, fill) = switch (state) {
      _OptionState.right => (AppColors.grass, AppColors.grass.withValues(alpha: 0.35)),
      _OptionState.wrong => (Colors.redAccent, Colors.redAccent.withValues(alpha: 0.30)),
      _OptionState.pending => (AppColors.gold, AppColors.gold.withValues(alpha: 0.18)),
      _OptionState.dim => (AppColors.gold.withValues(alpha: 0.25), null),
      _OptionState.idle => (AppColors.gold, null),
    };
    return Opacity(
      opacity: state == _OptionState.dim ? 0.55 : 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: fill,
        elevation: 6,
        margin: const EdgeInsets.symmetric(vertical: 5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), side: BorderSide(color: border, width: 1.5)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              IconTile(
                size: 40,
                radius: 12,
                child: Text(letter, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 52),
            ]),
          ),
        ),
      ),
    );
  }
}

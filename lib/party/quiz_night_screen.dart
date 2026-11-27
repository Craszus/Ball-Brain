import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/l10n.dart';
import '../services/stats.dart';
import '../share_screen.dart' show appShareUrl;
import '../ui/answer_button.dart';
import '../ui/football.dart';
import '../ui/gold_button.dart';
import '../ui/theme.dart';
import 'quiz_night_api.dart';
import '../services/visibility.dart';

String nightError(String key) => switch (key) {
      'not_found' => 'Fant ingen quizkveld med den koden.',
      'no_profile' => 'Lagre profilen din først.',
      'no_players' => 'Ingen har blitt med ennå.',
      'full' => 'Quizkvelden er full.',
      'daily_limit' => 'Du har startet maks antall quizkvelder i dag.',
      'bad_setup' => 'Velg temaer med nok spørsmål.',
      _ => 'Krever internett. Sjekk nettet og prøv igjen.',
    };

void _snack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

Future<void> _openNight(BuildContext context, QuizNightApi api, NightState state) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => QuizNightScreen(initial: state, api: api)));

/// Quizkveld-fanen under «Kamper»: start som vert, bli med med kode, eller fortsett.
class QuizNightView extends StatefulWidget {
  const QuizNightView({super.key, this.api = const QuizNightApi()});
  final QuizNightApi api;

  @override
  State<QuizNightView> createState() => _QuizNightViewState();
}

class _QuizNightViewState extends State<QuizNightView> {
  NightState? _mine;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final mine = await widget.api.mine();
      if (mounted) setState(() => _mine = mine);
    } on NightError {
      // uten nett vises bare knappene
    }
  }

  Future<void> _open(NightState state) async {
    await _openNight(context, widget.api, state);
    await _load();
  }

  Future<void> _join() async {
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
    try {
      final state = await widget.api.join(code);
      if (mounted) await _open(state);
    } on NightError catch (e) {
      if (mounted) _snack(context, nightError(e.key));
    }
  }

  Future<void> _setup() async {
    final state = await Navigator.of(context).push(MaterialPageRoute<NightState>(
        builder: (_) => QuizNightSetupScreen(api: widget.api)));
    if (state != null && mounted) await _open(state);
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Quizkveld for puben og supporterklubben',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Verten styrer quizen, og alle svarer på hver sin mobil.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          if (_mine != null) ...[
            GoldButton(label: 'Fortsett quizkvelden', onPressed: () => _open(_mine!)),
            const SizedBox(height: 12),
          ],
          GoldButton(label: 'Start quizkveld', onPressed: _setup),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _join,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Bli med med kode'),
          ),
          const SizedBox(height: 18),
          const Text('Opptil 100 deltakere. Alle trenger appen og nett.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      );
}

/// Verten velger temaer, antall spørsmål og tid.
class QuizNightSetupScreen extends StatefulWidget {
  const QuizNightSetupScreen({super.key, this.api = const QuizNightApi()});
  final QuizNightApi api;

  static const themes = [
    'Regler', 'VM-historie', 'EM-historie', 'Klubbfotball', 'Ligaer', 'Spillere og rekorder',
    'Trenere', 'Stadioner', 'Norge', 'Visste du at?',
  ];

  @override
  State<QuizNightSetupScreen> createState() => _QuizNightSetupScreenState();
}

class _QuizNightSetupScreenState extends State<QuizNightSetupScreen> {
  final _themes = <String>{};
  int _count = 10;
  int _seconds = 20;
  bool _hostPlays = false;
  bool _busy = false;

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final state = await widget.api.create(
          count: _count, seconds: _seconds, eras: _themes.toList(), hostPlays: _hostPlays);
      if (mounted) Navigator.of(context).pop(state);
    } on NightError catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(context, nightError(e.key));
    }
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.gold)),
      );

  Widget _numbers(List<int> values, int selected, ValueChanged<int> pick) =>
      SegmentedButton<int>(
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        segments: [for (final v in values) ButtonSegment(value: v, label: Text('$v'))],
        selected: {selected},
        onSelectionChanged: (s) => setState(() => pick(s.first)),
      );

  @override
  Widget build(BuildContext context) => PitchScaffold(
        title: 'Start quizkveld',
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _heading('Temaer'),
            Wrap(spacing: 8, runSpacing: 4, children: [
              ChoiceChip(
                label: const Text('Alt'),
                selected: _themes.isEmpty,
                onSelected: (_) => setState(_themes.clear),
              ),
              for (final t in QuizNightSetupScreen.themes)
                FilterChip(
                  label: Text(t),
                  selected: _themes.contains(t),
                  onSelected: (on) => setState(() => on ? _themes.add(t) : _themes.remove(t)),
                ),
            ]),
            _heading('Antall spørsmål'),
            _numbers(const [10, 15, 20, 30], _count, (v) => _count = v),
            _heading('Sekunder per spørsmål'),
            _numbers(const [15, 20, 30, 45], _seconds, (v) => _seconds = v),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Jeg spiller også'),
              value: _hostPlays,
              onChanged: (v) => setState(() => _hostPlays = v),
            ),
            const SizedBox(height: 8),
            GoldButton(label: 'Lag quizkvelden', onPressed: _busy ? null : _create),
          ],
        ),
      );
}

/// Selve kvelden: lobby, spørsmål, svar og resultat. Henter status fra serveren jevnlig.
class QuizNightScreen extends ConsumerStatefulWidget {
  const QuizNightScreen({super.key, required this.initial, this.api = const QuizNightApi()});

  final NightState initial;
  final QuizNightApi api;

  @override
  ConsumerState<QuizNightScreen> createState() => _QuizNightScreenState();
}

class _QuizNightScreenState extends ConsumerState<QuizNightScreen> {
  late NightState _s = widget.initial;
  DateTime _fetched = DateTime.now();
  Timer? _tick;
  int _ticks = 0;
  bool _busy = false;
  String? _picked; // valget mitt før serveren har bekreftet

  @override
  void initState() {
    super.initState();
    _record();
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted || _s.over) return;
      if (++_ticks % 3 == 0 && appVisible()) _refresh();
      if (_s.status == 'question') setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _apply(NightState s) {
    if (!mounted) return;
    setState(() {
      if (s.idx != _s.idx || s.status != _s.status) _picked = null;
      _s = s;
      _fetched = DateTime.now();
    });
    _record();
  }

  /// Teller kvelden i statistikken (og pokalene) én gang når den er ferdig.
  void _record() {
    final s = _s;
    if (s.status != 'finished') return;
    final stats = ref.read(statsProvider.notifier);
    Future.microtask(() async {
      if (s.playing) await stats.bump('partyPlayed', once: 'party-play-${s.id}');
      if (s.playing && s.myRank == 1 && s.players >= 3) {
        await stats.bump('partyWins', once: 'party-win-${s.id}');
      }
      if (s.host && s.players >= 3) {
        await stats.bump('partyHosted', once: 'party-host-${s.id}');
      }
    });
  }

  Future<void> _refresh() async {
    try {
      final s = await widget.api.state(_s.id);
      _apply(s);
    } on NightError catch (e) {
      // «not_found»: verten har fjernet kvelden; ellers prøver vi igjen om litt
      if (e.key == 'not_found' && mounted) {
        _apply(NightState(id: _s.id, code: _s.code, status: 'cancelled'));
      }
    }
  }

  Future<void> _run(Future<NightState> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _apply(await action());
    } on NightError catch (e) {
      if (mounted && e.key != 'not_active') _snack(context, nightError(e.key));
      await _refresh();
    }
    if (mounted) setState(() => _busy = false);
  }

  void _answer(int i) {
    if (_s.myAnswered || _picked != null) return;
    final choice = _s.options[i];
    setState(() => _picked = choice);
    _run(() => widget.api.answer(_s.id, _s.idx, choice));
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_s.host ? 'Avslutte quizkvelden?' : 'Forlate quizkvelden?'),
        content: Text(_s.host
            ? 'Quizkvelden avsluttes for alle deltakerne.'
            : 'Poengene dine fjernes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Forlat')),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    await widget.api.leave(_s.id);
    if (mounted) {
      _tick?.cancel();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: _s.over,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmLeave();
        },
        child: PitchScaffold(
          title: 'Quizkveld',
          body: switch (_s.status) {
            'lobby' => _lobby(),
            'question' => _question(),
            'reveal' => _reveal(),
            'finished' => _finished(),
            _ => _center('Verten avsluttet quizkvelden.'),
          },
        ),
      );

  Widget _center(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
      );

  Widget _page(List<Widget> children, {Widget? bottom}) => Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: children),
        ),
        if (bottom != null)
          SafeArea(
            top: false,
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: bottom),
          ),
      ]);

  Widget _note(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary)),
      );

  Widget _lobby() => _page([
        _note('Koden til quizkvelden'),
        Text(_s.code,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                letterSpacing: 10,
                color: AppColors.gold)),
        if (_s.host) ...[
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                  text: '${'Quizkveld i Ball Brain! Kode'.tr}: ${_s.code} $appShareUrl'));
              _snack(context, 'Kopiert');
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Kopier invitasjonen'),
          ),
          _note('Mangler noen appen? De kan skanne denne:'),
          Center(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: QrImageView(
                data: appShareUrl,
                size: 150,
                backgroundColor: Colors.white,
                semanticsLabel: 'QR-kode til Ball Brain'.tr,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text('${_s.players} har blitt med',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [for (final p in _s.standings) Chip(label: Text(p.name))],
        ),
        if (!_s.host) _note('Venter på at verten starter …'),
      ],
          bottom: _s.host
              ? GoldButton(
                  label: 'Start quizen',
                  onPressed:
                      _s.players == 0 || _busy ? null : () => _run(() => widget.api.next(_s)))
              : null);

  List<Widget> _header() => [
        Text(
          'SPØRSMÅL ${_s.idx + 1} AV ${_s.total}'
          '${_s.era != null ? '  ·  ${_s.era!.toUpperCase()}' : ''}',
          textAlign: TextAlign.center,
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
            child: Text(_s.prompt ?? '',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, height: 1.25)),
          ),
        ),
      ];

  Widget _question() {
    final left = ((_s.leftMs ?? 0) - DateTime.now().difference(_fetched).inMilliseconds)
        .clamp(0, _s.seconds * 1000);
    final mine = _s.myAnswer ?? _picked;
    return _page([
      LinearProgressIndicator(
          value: left / (_s.seconds * 1000),
          minHeight: 8,
          backgroundColor: Colors.black38,
          color: AppColors.gold),
      const SizedBox(height: 4),
      Text('${(left / 1000).ceil()} sek',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.gold)),
      ..._header(),
      const SizedBox(height: 8),
      for (var i = 0; i < _s.options.length; i++)
        Opacity(
          opacity: mine == null || mine == _s.options[i] ? 1 : 0.4,
          child: AnswerButton(
            letter: String.fromCharCode(65 + i),
            label: _s.options[i],
            onTap: _s.playing && mine == null ? () => _answer(i) : () {},
          ),
        ),
      if (_s.playing && mine != null) _note('Svaret er sendt. Venter på de andre …'),
      _note('${_s.answered} av ${_s.players} har svart'),
    ],
        bottom: _s.host
            ? OutlinedButton(
                onPressed: _busy ? null : () => _run(() => widget.api.next(_s)),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('Vis svaret'))
            : null);
  }

  Widget _reveal() {
    final last = _s.idx + 1 >= _s.total;
    return _page([
      ..._header(),
      const SizedBox(height: 8),
      for (final o in _s.options)
        Card(
          margin: const EdgeInsets.symmetric(vertical: 3),
          color: o == _s.right
              ? const Color(0xFF2E7D32)
              : o == _s.myAnswer
                  ? const Color(0xFF8E2A2A)
                  : null,
          child: ListTile(
            dense: true,
            title: Text(o, style: const TextStyle(fontWeight: FontWeight.w800)),
            trailing: o == _s.right
                ? const Icon(Icons.check_circle, color: Colors.white)
                : o == _s.myAnswer
                    ? const Icon(Icons.cancel, color: Colors.white)
                    : null,
          ),
        ),
      if (_s.playing)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text((_s.myPoints ?? 0) > 0 ? '+${_s.myPoints} poeng' : 'Ingen poeng denne gangen',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.gold)),
        ),
      const SizedBox(height: 6),
      for (final r in _s.standings.take(5)) _row(r),
      if (!_s.host) _note('Venter på neste spørsmål …'),
    ],
        bottom: _s.host
            ? GoldButton(
                label: last ? 'Vis resultatet' : 'Neste spørsmål',
                onPressed: _busy ? null : () => _run(() => widget.api.next(_s)))
            : null);
  }

  Widget _row(NightRow r) => Card(
        margin: const EdgeInsets.symmetric(vertical: 3),
        color: r.me ? AppColors.gold.withValues(alpha: 0.18) : null,
        child: ListTile(
          dense: true,
          leading: Text('${r.rank}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.gold)),
          title: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing:
              Text('${r.score} poeng', style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
      );

  Widget _finished() {
    final winner = _s.standings.isEmpty ? null : _s.standings.first;
    return _page([
      const Icon(Icons.emoji_events, size: 72, color: AppColors.gold),
      if (winner != null)
        Text('${winner.name} vant!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      if (_s.playing && _s.myRank != null) _note('Du ble nummer ${_s.myRank}'),
      const SizedBox(height: 8),
      for (final r in _s.standings) _row(r),
    ], bottom: GoldButton(label: 'Ferdig', onPressed: () => Navigator.of(context).pop()));
  }
}

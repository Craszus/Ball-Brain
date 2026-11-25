import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../ui/theme.dart';
import 'club_api.dart';
import 'club_badge.dart';
import 'club_game_screen.dart';
import 'club_table_screen.dart';

/// Øverst på klubbskjermen: skjold, resultater, utfordringskode og klubbkampene.
class ClubSection extends StatefulWidget {
  const ClubSection(
      {super.key,
      required this.clubId,
      this.loadClubs = ClubApi.myClubs,
      this.loadGames = ClubApi.games});

  final String clubId;
  final Future<List<ClubInfo>> Function() loadClubs;
  final Future<List<ClubGame>> Function() loadGames;

  @override
  State<ClubSection> createState() => _ClubSectionState();
}

class _ClubSectionState extends State<ClubSection> {
  ClubInfo? _club;
  List<ClubGame> _games = const [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final clubs = await widget.loadClubs();
      final games = await widget.loadGames();
      if (!mounted) return;
      setState(() {
        _club = clubs.where((c) => c.id == widget.clubId).firstOrNull;
        _games = [
          for (final g in games)
            if (g.home.id == widget.clubId || g.away.id == widget.clubId) g
        ];
      });
    } on ClubError {
      // uten nett vises bare medlemslisten
    }
  }

  void _snack(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _editLook(ClubInfo club) async {
    var c1 = club.color1, c2 = club.color2, emblem = club.emblem;
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        Widget colors(int selected, void Function(int) pick) => Wrap(spacing: 6, runSpacing: 6, children: [
              for (var i = 0; i < clubColors.length; i++)
                GestureDetector(
                  onTap: () => set(() => pick(i)),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: clubColors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: i == selected ? AppColors.gold : Colors.white24,
                          width: i == selected ? 4 : 1),
                    ),
                  ),
                ),
            ]);
        ClubInfo preview(int e) =>
            ClubInfo(id: club.id, name: club.name, color1: c1, color2: c2, emblem: e);
        return AlertDialog(
          title: const Text('Klubbskjold'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ClubBadge(preview(emblem), size: 72),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                for (var e = 0; e < 4; e++)
                  GestureDetector(
                    onTap: () => set(() => emblem = e),
                    child: Opacity(
                        opacity: e == emblem ? 1 : 0.45, child: ClubBadge(preview(e), size: 38)),
                  ),
              ]),
              const SizedBox(height: 14),
              colors(c1, (i) => c1 = i),
              const SizedBox(height: 10),
              colors(c2, (i) => c2 = i),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lagre')),
          ],
        );
      }),
    );
    if (save != true) return;
    try {
      await ClubApi.setLook(club.id, c1, c2, emblem);
    } on ClubError catch (e) {
      _snack(clubError(e.key));
    }
    await _load();
  }

  Future<void> _challenge(ClubInfo club) async {
    final id = await showDialog<String>(
        context: context, builder: (_) => ChallengeClubDialog(clubId: club.id));
    await _load();
    if (id != null && mounted) await _open(id);
  }

  Future<void> _open(String gameId) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => ClubGameScreen(gameId: gameId)));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = _club;
    if (c == null) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              ClubBadge(c, size: 60),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${c.members} medlemmer',
                      style: const TextStyle(color: AppColors.textSecondary)),
                  Text('Seier ${c.wins} · Uavgjort ${c.draws} · Tap ${c.losses}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
              ),
              if (c.canEdit)
                IconButton(
                    onPressed: () => _editLook(c),
                    tooltip: 'Klubbskjold'.tr,
                    icon: const Icon(Icons.palette_outlined, color: AppColors.gold)),
            ]),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: c.members < 3 ? null : () => _challenge(c),
              icon: const Icon(Icons.sports_soccer),
              label: const Text('Utfordre en klubb'),
            ),
            const SizedBox(height: 6),
            const ClubTableButton(),
            if (c.members < 3)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Dere må være minst 3 for å spille mot andre klubber.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            Row(children: [
              Expanded(
                child: Text('Utfordringskode: ${c.matchCode}',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Kopier'.tr,
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                      text: '${'Utfordre klubben vår i Ball Brain!'.tr} ${'Kode'.tr}: ${c.matchCode}'));
                  _snack('Kopiert');
                },
              ),
            ]),
          ]),
        ),
      ),
      if (_games.isNotEmpty) ...[
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 4),
          child: Text('Klubbkamper',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.gold)),
        ),
        for (final g in _games.take(6))
          Card(
            margin: const EdgeInsets.symmetric(vertical: 3),
            child: ListTile(
              leading: ClubBadge(g.home.id == c.id ? g.away : g.home, size: 32),
              title: Text('Mot ${(g.home.id == c.id ? g.away : g.home).name}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(clubGameStatus(g)),
              trailing: g.finished
                  ? Text('${g.pot(c.id)} – ${g.pot(g.home.id == c.id ? g.away.id : g.home.id)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))
                  : const Icon(Icons.chevron_right),
              onTap: () => _open(g.id),
            ),
          ),
      ],
    ]);
  }
}

/// Velg motstander (utfordringskode), lagstørrelse, avspark og frist.
class ChallengeClubDialog extends StatefulWidget {
  const ChallengeClubDialog({super.key, required this.clubId});
  final String clubId;

  @override
  State<ChallengeClubDialog> createState() => _ChallengeClubDialogState();
}

class _ChallengeClubDialogState extends State<ChallengeClubDialog> {
  final _code = TextEditingController();
  int _size = 3;
  int _window = 5;
  int _inMinutes = 15; // 0 = valgt klokkeslett
  TimeOfDay? _time;
  String? _error;
  bool _busy = false;

  DateTime get _kickoff {
    final now = DateTime.now();
    if (_inMinutes > 0) return now.add(Duration(minutes: _inMinutes));
    var t = DateTime(now.year, now.month, now.day, _time!.hour, _time!.minute);
    // Et klokkeslett som har passert i dag, betyr i morgen.
    if (t.isBefore(now.add(const Duration(minutes: 2)))) t = t.add(const Duration(days: 1));
    return t;
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      final id = await ClubApi.challenge(
          club: widget.clubId,
          code: _code.text,
          size: _size,
          kickoff: _kickoff,
          window: _window);
      if (mounted) Navigator.pop(context, id);
    } on ClubError catch (e) {
      if (mounted) {
        setState(() {
          _error = clubError(e.key);
          _busy = false;
        });
      }
    }
  }

  Widget _pick(Map<int, String> options, int selected, void Function(int) onPick) =>
      SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          for (final e in options.entries) ButtonSegment(value: e.key, label: Text(e.value))
        ],
        selected: {selected},
        onSelectionChanged: (s) => setState(() => onPick(s.first)),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Utfordre en klubb'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _code,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: 'Utfordringskoden til motstanderen'.tr),
              onChanged: (_) => setState(() => _error = null),
            ),
            const Text('Lag'),
            _pick(const {3: '3 mot 3', 5: '5 mot 5'}, _size, (v) => _size = v),
            const SizedBox(height: 10),
            const Text('Avspark om'),
            _pick(const {5: '5 min', 15: '15 min', 60: '1 t', 0: 'Kl.'}, _inMinutes, (v) {
              _inMinutes = v;
              if (v == 0) {
                _time ??= TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2)));
                showTimePicker(context: context, initialTime: _time!).then((t) {
                  if (t != null && mounted) setState(() => _time = t);
                });
              }
            }),
            if (_inMinutes == 0 && _time != null)
              Text('Avspark kl. ${_time!.hour.toString().padLeft(2, '0')}:'
                  '${_time!.minute.toString().padLeft(2, '0')}'),
            const SizedBox(height: 10),
            const Text('Frist for å svare'),
            _pick(const {3: '3 min', 5: '5 min'}, _window, (v) => _window = v),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFFF6B6B))),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Avbryt')),
          FilledButton(
              onPressed: _busy || _code.text.trim().length < 6 ? null : _send,
              child: const Text('Send utfordring')),
        ],
      );
}

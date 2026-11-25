import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import '../ui/football.dart';
import '../ui/theme.dart';
import 'duel_api.dart';

const _lossColor = Color(0xFFFF6B6B);

/// Bokstaver for seier, uavgjort og tap, slik de vanligvis skrives i formtabeller.
const _formLetters = {
  'nb': ['S', 'U', 'T'],
  'en': ['W', 'D', 'L'],
  'sv': ['V', 'O', 'F'],
  'da': ['V', 'U', 'T'],
  'de': ['S', 'U', 'N'],
  'es': ['G', 'E', 'P'],
  'fr': ['V', 'N', 'D'],
};

/// Ferdige kamper, nyeste først.
List<DuelListItem> finishedDuels(List<DuelListItem> items) {
  final done = items.where((i) => i.isFinished).toList();
  done.sort((a, b) => (b.finishedMs ?? 0).compareTo(a.finishedMs ?? 0));
  return done;
}

/// Kampene samlet per motstander. Motstanderen i den nyeste kampen kommer først.
List<List<DuelListItem>> duelsByOpponent(List<DuelListItem> items) {
  final groups = <String, List<DuelListItem>>{};
  for (final i in finishedDuels(items)) {
    (groups[i.opponentId ?? i.opponent] ??= []).add(i);
  }
  return groups.values.toList();
}

int _count(List<DuelListItem> games, String result) => games.where((g) => g.result == result).length;

class _FormBadge extends StatelessWidget {
  const _FormBadge(this.result, {this.size = 26});

  final String? result;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letters = _formLetters[L10n.lang] ?? _formLetters['en']!;
    final (letter, color) = switch (result) {
      'win' => (letters[0], AppColors.gold),
      'loss' => (letters[2], _lossColor),
      _ => (letters[1], AppColors.textSecondary),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Text(letter,
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: size * 0.5)),
    );
  }
}

/// 1v1-menyen: bare stillingen mot den siste motstanderen. Resten ligger i [DuelHistoryScreen].
class LastOpponentCard extends StatelessWidget {
  const LastOpponentCard({super.key, required this.items, required this.onOpenHistory});

  final List<DuelListItem> items;
  final VoidCallback onOpenHistory;

  Widget _number(int n, String label, Color color) => Expanded(
        child: Column(children: [
          Text('$n', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final groups = duelsByOpponent(items);
    if (groups.isEmpty) return const SizedBox.shrink();
    final games = groups.first;
    final last = games.first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(children: [
          const Text('Siste motstander',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(last.opponent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Row(children: [
            _number(_count(games, 'win'), 'Seier', AppColors.gold),
            _number(_count(games, 'draw'), 'Uavgjort', AppColors.textSecondary),
            _number(_count(games, 'loss'), 'Tap', _lossColor),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 4, alignment: WrapAlignment.center, children: [
            for (final g in games.take(8)) _FormBadge(g.result),
          ]),
          const SizedBox(height: 8),
          Text('Siste kamp: ${last.myScore} – ${last.theirScore}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          TextButton(onPressed: onOpenHistory, child: const Text('Se historikken')),
        ]),
      ),
    );
  }
}

/// Eget vindu med alle kampene, ett kort per motstander.
class DuelHistoryScreen extends StatefulWidget {
  const DuelHistoryScreen(
      {super.key, required this.items, required this.onRemove, required this.reload});

  final List<DuelListItem> items;
  final Future<void> Function(DuelListItem) onRemove;

  /// Henter listen på nytt etter at en kamp er fjernet.
  final List<DuelListItem> Function() reload;

  @override
  State<DuelHistoryScreen> createState() => _DuelHistoryScreenState();
}

class _DuelHistoryScreenState extends State<DuelHistoryScreen> {
  late List<DuelListItem> _items = widget.items;

  Future<void> _remove(DuelListItem item) async {
    try {
      await widget.onRemove(item);
    } on DuelError {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Krever internett. Sjekk nettet og prøv igjen.')));
      }
      return;
    }
    if (mounted) setState(() => _items = widget.reload());
  }

  @override
  Widget build(BuildContext context) {
    final groups = duelsByOpponent(_items);
    return PitchScaffold(
      title: 'Historikk'.tr,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Kamper fra de siste 14 dagene',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          if (groups.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text('Ingen kamper ennå.', textAlign: TextAlign.center),
            ),
          for (final (index, games) in groups.indexed)
            _OpponentTile(
              key: ValueKey(games.first.opponentId ?? games.first.opponent),
              games: games,
              initiallyOpen: index == 0,
              onRemove: _remove,
            ),
        ],
      ),
    );
  }
}

class _OpponentTile extends StatelessWidget {
  const _OpponentTile(
      {super.key, required this.games, required this.initiallyOpen, required this.onRemove});

  final List<DuelListItem> games;
  final bool initiallyOpen;
  final Future<void> Function(DuelListItem) onRemove;

  @override
  Widget build(BuildContext context) {
    final name = games.first.opponent;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyOpen,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          backgroundColor: AppColors.tile,
          child: Text(name.characters.take(1).toString().toUpperCase(),
              style: const TextStyle(color: AppColors.goldLight)),
        ),
        title: Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
            'Seier ${_count(games, 'win')} · Uavgjort ${_count(games, 'draw')} · Tap ${_count(games, 'loss')}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        children: [
          for (final g in games)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: Row(children: [
                _FormBadge(g.result, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${g.myScore} – ${g.theirScore}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  onPressed: () => onRemove(g),
                  tooltip: 'Fjern'.tr,
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

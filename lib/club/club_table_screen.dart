import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import '../ui/football.dart';
import '../ui/theme.dart';
import 'club_api.dart';
import 'club_badge.dart';

/// Knappen som åpner klubbtabellen.
class ClubTableButton extends StatelessWidget {
  const ClubTableButton({super.key});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const ClubTableScreen())),
        icon: const Icon(Icons.leaderboard_outlined),
        label: const Text('Klubbtabellen'),
      );
}

/// Valget mellom denne måneden og totalt.
class PeriodPicker extends StatelessWidget {
  const PeriodPicker({super.key, required this.period, required this.onChanged});
  final String period;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<String>(
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        segments: const [
          ButtonSegment(value: 'month', label: Text('Denne måneden')),
          ButtonSegment(value: 'all', label: Text('Totalt')),
        ],
        selected: {period},
        onSelectionChanged: (v) => onChanged(v.first),
      );
}

/// Én linje: plass, skjold, navn, seier-uavgjort-tap og poeng.
class StandingTile extends StatelessWidget {
  const StandingTile(this.row, {super.key, this.action});
  final StandingRow row;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(vertical: 3),
        shape: row.mine
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.gold))
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(children: [
            SizedBox(
              width: 28,
              child: Text('${row.rank}',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.gold)),
            ),
            if (row.club != null) ...[ClubBadge(row.club!, size: 30), const SizedBox(width: 10)],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('Seier ${row.wins} · Uavgjort ${row.draws} · Tap ${row.losses}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
            Text('${row.points} poeng',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            ?action,
          ]),
        ),
      );
}

/// Alle klubber rangert etter klubbkampene.
class ClubTableScreen extends StatelessWidget {
  const ClubTableScreen({super.key, this.load = ClubApi.table});
  final Future<List<StandingRow>> Function(String period) load;

  @override
  Widget build(BuildContext context) =>
      PitchScaffold(title: 'Klubbtabellen', body: ClubTableView(load: load));
}

/// Selve tabellen (brukes også som fane i rangeringen).
class ClubTableView extends StatefulWidget {
  const ClubTableView({super.key, this.load = ClubApi.table});
  final Future<List<StandingRow>> Function(String period) load;

  @override
  State<ClubTableView> createState() => _ClubTableViewState();
}

class _ClubTableViewState extends State<ClubTableView> {
  String _period = 'month';
  late Future<List<StandingRow>> _future = widget.load(_period);

  void _pick(String p) => setState(() {
        _period = p;
        _future = widget.load(p);
      });

  Widget _message(String text) => Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
      );

  @override
  Widget build(BuildContext context) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            PeriodPicker(period: _period, onChanged: _pick),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                  'Seier gir 3 poeng, uavgjort 1. Bare første kamp mot samme klubb teller hver dag.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
            FutureBuilder<List<StandingRow>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snap.data;
                if (rows == null) return _message(clubError('offline'));
                if (rows.isEmpty) return _message('Ingen klubbkamper er spilt ennå.');
                return Column(children: [for (final r in rows) StandingTile(r)]);
              },
            ),
          ],
      );
}

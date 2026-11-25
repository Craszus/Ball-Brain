import 'package:flutter/material.dart' hide Text;

import '../daily_board_screen.dart';
import '../l10n/l10n.dart';
import '../leaderboard_screen.dart';
import '../services/cloud.dart';
import '../services/profile.dart';
import 'theme.dart';

typedef RankLoader = Future<LeaderboardData?> Function({String? country});

/// Rangeringen i statistikken: plassen min i landet og i verden, med vei til hele listene.
class RankingCard extends StatefulWidget {
  const RankingCard({super.key, required this.country, this.load = Cloud.leaderboard});

  final String country;
  final RankLoader load;

  @override
  State<RankingCard> createState() => _RankingCardState();
}

class _RankingCardState extends State<RankingCard> {
  late final Future<LeaderboardData?> _country = widget.load(country: widget.country);
  late final Future<LeaderboardData?> _world = widget.load();

  Widget _place(String label, Future<LeaderboardData?> future) => Expanded(
        child: FutureBuilder<LeaderboardData?>(
          future: future,
          builder: (context, snap) {
            final data = snap.data;
            final me = data?.me ?? data?.rows.where((r) => r.isMe).firstOrNull;
            return Column(children: [
              Text(me == null ? '–' : 'Nr. ${me.rank}',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.gold)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]);
          },
        ),
      );

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Rangering',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Row(children: [
              _place(countryName(widget.country), _country),
              _place('Verden', _world),
            ]),
            const SizedBox(height: 10),
            FilledButton(
                onPressed: () => _open(const LeaderboardScreen()),
                child: const Text('Se rangeringen')),
            const SizedBox(height: 6),
            OutlinedButton(
                onPressed: () => _open(const DailyBoardScreen()),
                child: const Text('Dagens rangering')),
          ]),
        ),
      );
}

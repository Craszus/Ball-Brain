import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'club/club_table_screen.dart';
import 'daily_board_screen.dart';
import 'l10n/l10n.dart';
import 'services/cloud.dart';
import 'services/profile.dart';
import 'ui/football.dart';
import 'ui/theme.dart';

/// Rangering: samlet poengsum, for landet ditt og for hele verden.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  int _tab = 0; // 0 land, 1 verden, 2 klubbtabellen
  late Future<LeaderboardData?> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final country = ref.read(profileProvider).country;
    _future = Cloud.leaderboard(country: _tab == 1 ? null : country);
  }

  @override
  Widget build(BuildContext context) {
    final country = ref.watch(profileProvider).country;
    return PitchScaffold(
      title: 'Rangering',
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.today, size: 18),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const DailyBoardScreen())),
            label: const Text('Dagens rangering'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                  value: 0,
                  label: Text(countryName(country), maxLines: 1, overflow: TextOverflow.ellipsis)),
              const ButtonSegment(value: 1, label: Text('Verden')),
              const ButtonSegment(value: 2, label: Text('Klubber')),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() {
              _tab = s.first;
              _load();
            }),
          ),
        ),
        if (_tab == 2) const Expanded(child: ClubTableView()) else Expanded(
          child: FutureBuilder<LeaderboardData?>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snap.data;
              if (data == null) {
                return _Message('Kunne ikke hente rangeringen. Sjekk nettet.', onRetry: () {
                  setState(_load);
                });
              }
              if (data.rows.isEmpty) {
                return const _Message('Ingen poeng ennå. Spill en runde!');
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  for (final r in data.rows) LeaderboardTile(r),
                  if (data.me != null && !data.rows.any((r) => r.isMe)) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Center(
                          child: Text('· · ·', style: TextStyle(color: AppColors.textSecondary))),
                    ),
                    LeaderboardTile(data.me!),
                  ],
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.onRetry});
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Prøv igjen')),
            ],
          ]),
        ),
      );
}

class LeaderboardTile extends StatelessWidget {
  const LeaderboardTile(this.r, {super.key, this.trailingAction});
  final LeaderboardRow r;

  /// Valgfri knapp helt til høyre (f.eks. «utfordre» i en gruppe).
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    final medal = switch (r.rank) {
      1 => const Color(0xFFFFD54F),
      2 => const Color(0xFFCFD8DC),
      3 => const Color(0xFFD08A55),
      _ => null,
    };
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: r.isMe ? AppColors.gold.withValues(alpha: 0.18) : null,
      shape: r.isMe
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.gold.withValues(alpha: 0.7)))
          : null,
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: Center(
            child: Text('${r.rank}',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: medal ?? AppColors.textSecondary)),
          ),
        ),
        title: Text(r.isMe ? '${r.username} (${'Deg'.tr})' : r.username,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(countryName(r.country)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('${r.total} poeng',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold)),
          ?trailingAction,
        ]),
      ),
    );
  }
}

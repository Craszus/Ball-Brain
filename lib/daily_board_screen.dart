import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/l10n.dart';
import 'services/daily.dart';
import 'services/profile.dart';
import 'ui/football.dart';
import 'ui/theme.dart';

typedef DailyBoardLoader = Future<List<DailyRow>?> Function(String period, String scope);

/// Rangering for dagens utfordring: i dag eller hele uka, i landet, verden eller blant venner.
class DailyBoardScreen extends ConsumerStatefulWidget {
  const DailyBoardScreen({super.key, this.load = DailyApi.board});

  final DailyBoardLoader load;

  @override
  ConsumerState<DailyBoardScreen> createState() => _DailyBoardScreenState();
}

class _DailyBoardScreenState extends ConsumerState<DailyBoardScreen> {
  String _period = 'day';
  String _scope = 'world';
  late Future<List<DailyRow>?> _future = widget.load(_period, _scope);

  void _reload() => setState(() {
        _future = widget.load(_period, _scope);
      });

  Widget _pick(Map<String, String> options, String selected, void Function(String) onPick) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: SegmentedButton<String>(
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          segments: [
            for (final e in options.entries)
              ButtonSegment(
                  value: e.key,
                  label: Text(e.value, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
          selected: {selected},
          onSelectionChanged: (s) {
            onPick(s.first);
            _reload();
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final country = ref.watch(profileProvider).country;
    return PitchScaffold(
      title: 'Dagens rangering'.tr,
      body: Column(children: [
        _pick(const {'day': 'I dag', 'week': 'Uka'}, _period, (v) => _period = v),
        _pick({'country': countryName(country), 'world': 'Verden', 'friends': 'Klubbene mine'}, _scope,
            (v) => _scope = v),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(
              _period == 'day'
                  ? 'Flest riktige vinner. Likt? Da vinner den raskeste.'
                  : 'Uka går fra mandag til søndag.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: FutureBuilder<List<DailyRow>?>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final rows = snap.data;
              if (rows == null) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Kunne ikke hente rangeringen. Sjekk nettet.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _reload, child: const Text('Prøv igjen')),
                  ]),
                );
              }
              if (rows.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Ingen resultater ennå. Spill dagens utfordring!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [for (final r in rows) _DailyTile(r, week: _period == 'week')],
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _DailyTile extends StatelessWidget {
  const _DailyTile(this.r, {required this.week});

  final DailyRow r;
  final bool week;

  @override
  Widget build(BuildContext context) {
    final medal = switch (r.rank) {
      1 => const Color(0xFFFFD54F),
      2 => const Color(0xFFCFD8DC),
      3 => const Color(0xFFD08A55),
      _ => AppColors.textSecondary,
    };
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: r.isMe ? AppColors.gold.withValues(alpha: 0.18) : null,
      child: ListTile(
        leading: SizedBox(
          width: 36,
          child: Center(
            child: Text('${r.rank}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: medal)),
          ),
        ),
        title: Text(r.isMe ? '${r.username} (${'Deg'.tr})' : r.username,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(week ? 'Dager: ${r.days} · ${r.time}' : 'Tid: ${r.time}'),
        trailing: Text(week ? '${r.correct} riktige' : '${r.correct}/10',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.gold)),
      ),
    );
  }
}

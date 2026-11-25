import 'package:flutter/material.dart' hide Text;

import '../l10n/l10n.dart';
import '../ui/theme.dart';
import 'club_api.dart';
import 'club_table_screen.dart';

/// Klubbserien: medlemmene rangert etter 1v1 mot hverandre.
class ClubLeague extends StatefulWidget {
  const ClubLeague(
      {super.key, required this.clubId, required this.onChallenge, this.load = ClubApi.league});

  final String clubId;
  final void Function(String userId, String name) onChallenge;
  final Future<List<StandingRow>> Function(String club, String period) load;

  @override
  State<ClubLeague> createState() => _ClubLeagueState();
}

class _ClubLeagueState extends State<ClubLeague> {
  String _period = 'month';
  late Future<List<StandingRow>> _future = widget.load(widget.clubId, _period);

  void _pick(String p) => setState(() {
        _period = p;
        _future = widget.load(widget.clubId, p);
      });

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PeriodPicker(period: _period, onChanged: _pick),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
              '1v1 mellom medlemmene teller. Seier gir 3 poeng, uavgjort 1. Bare første oppgjør mot samme person teller hver dag.',
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
            if (rows == null) {
              return Text(clubError('offline'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary));
            }
            return Column(children: [
              for (final r in rows)
                StandingTile(r,
                    action: r.mine
                        ? const SizedBox(width: 48)
                        : IconButton(
                            icon: const Icon(Icons.sports_mma, color: AppColors.gold),
                            tooltip: 'Utfordre til 1v1'.tr,
                            onPressed: () => widget.onChallenge(r.userId, r.name),
                          )),
            ]);
          },
        ),
      ]);
}

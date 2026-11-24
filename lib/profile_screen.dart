import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'avatar_picker_screen.dart';
import 'edit_profile_screen.dart';
import 'services/levels.dart';
import 'services/scoring.dart';
import 'services/profile.dart';
import 'services/stats.dart';
import 'settings_screen.dart';
import 'ui/avatar_view.dart';
import 'ui/football.dart';
import 'ui/icon_tile.dart';
import 'ui/level_card.dart';
import 'ui/level_up.dart';
import 'ui/theme.dart';
import 'ui/trophy_badge.dart';
import 'l10n/l10n.dart';

/// «Profil»: avatar, navn og land (åpnes fra avataren på hovedmenyen).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final profile = ref.watch(profileProvider);

    return PitchScaffold(
      title: 'Profil',
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.gold),
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.gold),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AvatarPickerScreen())),
                    child: AvatarView(profile.avatar, size: 140),
                  ),
                  const SizedBox(height: 12),
                  Text(profile.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900)),
                  Text('${profile.country} · ${countryName(profile.country)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const EditProfileScreen())),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Rediger'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      side: const BorderSide(color: AppColors.gold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const StatsScreen())),
            child: LevelCard(xp: stats.totalPoints),
          ),
        ],
      ),
    );
  }
}

/// «Statistikk og troféer»: nivå, tall og troféskap (åpnes fra det gule nivåkortet).
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final earned = trophies.where((t) => t.earned(stats)).length;

    Widget stat(IconData icon, String label, int value) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Column(children: [
                IconTile(size: 44, iconSize: 24, radius: 12, child: Icon(icon)),
                const SizedBox(height: 8),
                Text('$value',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w900)),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
          ),
        );

    return PitchScaffold(
      title: 'Statistikk og troféer',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          LevelCard(xp: stats.totalPoints),
          const SizedBox(height: 8),
          Row(children: [
            stat(Icons.sports_soccer, 'Runder spilt', stats.games),
            const SizedBox(width: 8),
            stat(Icons.star, 'Poeng totalt', stats.totalPoints),
          ]),
          Row(children: [
            stat(Icons.assignment_turned_in_outlined, 'Beste regler-runde',
                stats.bestRules),
            const SizedBox(width: 8),
            stat(Icons.layers_outlined, 'Beste sortering', stats.bestSort),
          ]),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.gold),
              const SizedBox(width: 8),
              const Text('Troféskap',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const Spacer(),
              ScoreChipText('$earned/${trophies.length}'),
            ],
          ),
          const SizedBox(height: 10),
          for (final g in TrophyGroup.values) ...[
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 8),
              child: Text(groupTitles[g]!.toUpperCase(),
                  style: const TextStyle(
                      letterSpacing: 2,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold)),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.74,
              children: [
                for (final t in trophies.where((t) => t.group == g))
                  _TrophyCard(trophy: t, got: t.earned(stats)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ScoreChipText extends StatelessWidget {
  const ScoreChipText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.goldLighter),
        ),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.w900)),
      );
}

class _TrophyCard extends StatelessWidget {
  const _TrophyCard({required this.trophy, required this.got});

  final Trophy trophy;
  final bool got;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      // Opptjent = gullkant, ikke opptjent = grønn kant og nedtonet
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: got
            ? const BorderSide(color: AppColors.gold)
            : BorderSide(color: AppColors.grass.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TrophyBadge(
                tier: trophy.tier, asset: trophy.asset, earned: got, size: 92),
            const SizedBox(height: 8),
            Text(trophy.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: got ? Colors.white : Colors.white54)),
            const SizedBox(height: 2),
            Text(trophy.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: got
                        ? AppColors.textSecondary
                        : Colors.white.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }
}

// Brukes av resultatskjermene.
class ResultPanel extends ConsumerStatefulWidget {
  const ResultPanel({
    super.key,
    required this.score,
    required this.note,
    required this.onAgain,
  });

  final int score;
  final String note;
  final VoidCallback onAgain;

  @override
  ConsumerState<ResultPanel> createState() => _ResultPanelState();
}

class _ResultPanelState extends ConsumerState<ResultPanel> {
  late bool _celebrate;
  late final int _xpBefore;

  @override
  void initState() {
    super.initState();
    final total = ref.read(statsProvider).totalPoints;
    _xpBefore = (total - widget.score).clamp(0, total);
    _celebrate = leveledUp(_xpBefore, total);
  }

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(statsProvider).totalPoints;
    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandMark(width: 80),
                const SizedBox(height: 10),
                const TrophyBadge(
                    tier: TrophyTier.gold,
                    asset: 'assets/trophies/fulltime.png',
                    size: 130),
                const SizedBox(height: 10),
                const Text('FULLTID!',
                    style: TextStyle(
                        fontSize: 16,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold)),
                Text('${widget.score} poeng',
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.w900)),
                Text('${signed(widget.score)} XP',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: AppColors.gold)),
                const SizedBox(height: 14),
                LevelCard(xp: total, fromXp: _xpBefore),
                const SizedBox(height: 8),
                Text(widget.note,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                FilledButton(
                    onPressed: widget.onAgain, child: const Text('Spill igjen')),
              ],
            ),
          ),
        ),
        if (_celebrate)
          Positioned.fill(
            child: LevelUpOverlay(
              info: levelFor(total),
              onClose: () => setState(() => _celebrate = false),
            ),
          ),
      ],
    );
  }
}

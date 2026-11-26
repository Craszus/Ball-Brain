import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'avatar_picker_screen.dart';
import 'edit_profile_screen.dart';
import 'pro/pro_screen.dart';
import 'services/ads.dart';
import 'services/levels.dart';
import 'services/scoring.dart';
import 'services/pro.dart';
import 'services/profile.dart';
import 'services/stats.dart';
import 'settings_screen.dart';
import 'ui/ad_flow.dart';
import 'ui/ranking_card.dart';
import 'ui/avatar_view.dart';
import 'ui/football.dart';
import 'ui/icon_tile.dart';
import 'ui/level_card.dart';
import 'ui/level_up.dart';
import 'ui/pro_frame.dart';
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
    final pro = ref.watch(proProvider);

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
                    child: ProFrame(
                        frame: pro.shownFrame,
                        child: AvatarView(profile.avatar, size: 140)),
                  ),
                  const SizedBox(height: 12),
                  Text(profile.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900)),
                  if (pro.shownTitle.isNotEmpty)
                    Text(pro.shownTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.gold, fontWeight: FontWeight.w900)),
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
            child: LevelCard(xp: stats.totalPoints, pro: pro.active),
          ),
          const SizedBox(height: 8),
          const ProProfileEntry(),
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
    final shown = trophiesFor(pro: ref.watch(proProvider).active);
    final earned = shown.where((t) => t.earned(stats)).length;

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
          const ProStatsEntry(),
          RankingCard(country: ref.watch(profileProvider).country),
          Row(children: [
            stat(Icons.sports_soccer, 'Runder spilt', stats.games),
            const SizedBox(width: 8),
            stat(Icons.star, 'Poeng totalt', stats.totalPoints),
          ]),
          Row(children: [
            stat(Icons.assignment_turned_in_outlined, 'Beste quizrunde',
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
              ScoreChipText('$earned/${shown.length}'),
            ],
          ),
          const SizedBox(height: 10),
          for (final g in TrophyGroup.values)
            if (shown.any((t) => t.group == g)) ...[
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
              // tre i bredden på nettbrett
              crossAxisCount: MediaQuery.sizeOf(context).width >= 500 ? 3 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.74,
              children: [
                for (final t in shown.where((t) => t.group == g))
                  _TrophyCard(trophy: t, got: t.earned(stats)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (!ref.watch(proProvider).active) const ProButton(),
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
                tier: trophy.tier,
                asset: trophy.asset,
                earned: got,
                size: 92),
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
    this.dailyNote,
    this.onRanking,
    this.practice = false,
    this.logo = true,
  });

  /// Ball Brain-merket øverst (utelates på dagens utfordring).
  final bool logo;

  /// Øvingsrunde: ingen XP, nivå eller annonse.
  final bool practice;

  final int score;
  final String note;
  final VoidCallback onAgain;

  /// Bare for dagens utfordring: merknad om rangeringen og knapp til den.
  final String? dailyNote;
  final VoidCallback? onRanking;

  @override
  ConsumerState<ResultPanel> createState() => _ResultPanelState();
}

class _ResultPanelState extends ConsumerState<ResultPanel> {
  late bool _celebrate;
  late final int _xpBefore;
  int _offer = 0; // bonus-XP som tilbys for en annonse
  int _bonus = 0; // bonus-XP som er hentet

  @override
  void initState() {
    super.initState();
    final total = ref.read(statsProvider).totalPoints;
    _xpBefore = (total - widget.score).clamp(0, total);
    _celebrate = !widget.practice && leveledUp(_xpBefore, total);
    if (widget.practice) return;
    Ads.offer(widget.score).then((v) {
      if (mounted && v > 0) setState(() => _offer = v);
    });
  }

  /// Bonus-XP etter en annonse. Gjelder bare nivået mitt, ikke rangeringene.
  Future<void> _watchAd() async {
    final bonus = _offer;
    final watched = await showRewardedAd(context, bonus);
    if (!mounted) return;
    if (!watched) {
      // slått av i samtykkevinduet: fjern tilbudet
      final still = await Ads.available();
      if (mounted && !still) setState(() => _offer = 0);
      return;
    }
    final before = ref.read(statsProvider).totalPoints;
    await ref.read(statsProvider.notifier).addBonus(bonus);
    if (!mounted) return;
    setState(() {
      _bonus = bonus;
      _offer = 0;
      _celebrate = leveledUp(before, before + bonus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(statsProvider).totalPoints;
    final unlocked = ref.read(statsProvider.notifier).lastUnlocked;
    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.logo) ...const [BrandMark(width: 80), SizedBox(height: 10)],
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
                if (!widget.practice)
                  Text('${signed(widget.score)} XP',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: AppColors.gold)),
                if (_bonus > 0)
                  Text('+$_bonus XP i bonus',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: AppColors.gold)),
                const SizedBox(height: 14),
                if (!widget.practice) LevelCard(xp: total, fromXp: _xpBefore),
                const SizedBox(height: 8),
                Text(widget.note,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
                if (widget.dailyNote != null) ...[
                  const SizedBox(height: 6),
                  Text(widget.dailyNote!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
                for (final t in unlocked.take(3)) ...[
                  const SizedBox(height: 10),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    TrophyBadge(tier: t.tier, asset: t.asset, size: 48),
                    const SizedBox(width: 10),
                    Flexible(
                        child: Text('Ny pokal: ${t.title}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, color: AppColors.gold))),
                  ]),
                ],
                const SizedBox(height: 20),
                if (_offer > 0) ...[
                  OutlinedButton.icon(
                      onPressed: _watchAd,
                      icon: const Icon(Icons.play_circle_outline),
                      label: Text('Se en annonse: +$_offer XP')),
                  const SizedBox(height: 8),
                ],
                if (widget.onRanking != null) ...[
                  FilledButton(
                      onPressed: widget.onRanking, child: const Text('Se rangeringen')),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: widget.onAgain, child: const Text('Spill igjen')),
                ] else
                  FilledButton(
                      onPressed: widget.onAgain, child: const Text('Spill igjen')),
                const SizedBox(height: 4),
                TextButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('Til hovedmenyen')),
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

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'geo/geo_quiz_screen.dart';
import 'quiz/photo_quiz_screen.dart';
import 'duel/duel_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'quiz/image_sort_screen.dart';
import 'quiz/rules_quiz_screen.dart';
import 'services/profile.dart';
import 'services/stats.dart';
import 'settings_screen.dart';
import 'quiz/quiz_controller.dart';
import 'ui/avatar_view.dart';
import 'ui/choice_screen.dart';
import 'ui/football.dart';
import 'ui/icon_tile.dart';
import 'ui/level_card.dart';
import 'ui/theme.dart';
import 'l10n/l10n.dart';

/// Hovedmeny i stilen «Premium Nattkamp / Stadion-gull».
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final stats = ref.watch(statsProvider);
    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return PitchScaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(children: [
          // Toppfelt: avatar (gullring) og tannhjul
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.card.withValues(alpha: 0.55),
                  AppColors.card.withValues(alpha: 0.25),
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => open(const ProfileScreen()),
                  child: AvatarView(profile.avatar, size: 62),
                ),
                Row(children: [
                  _GearButton(
                      icon: Icons.emoji_events_outlined,
                      onTap: () => open(const LeaderboardScreen())),
                  const SizedBox(width: 10),
                  _GearButton(onTap: () => open(const SettingsScreen())),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: BrandMark(width: 66)),
                const SizedBox(height: 8),
                const Text(
                  'BALL BRAIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fotballkunnskap. Raskere. Skarpere.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => open(const StatsScreen()),
                  child: LevelCard(xp: stats.totalPoints),
                ),
                const SizedBox(height: 8),
                const Text(
                  'SPILLMODE',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
            ]),
          ),
          // Spillknappene fyller resten av skjermen under det gule XP-kortet
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
              child: Column(
                children: [
                _ModeCard(
                  icon: const Icon(Icons.assignment_turned_in_outlined),
                  title: 'Regler-quiz',
                  onTap: () => open(ChoiceScreen(
                    title: 'Regler-quiz',
                    heading: 'Test regelkunnskapen din.',
                    rules: const [
                      '10 spørsmål per runde. Velg riktig av fire alternativer.',
                      'Riktig svar gir +2 poeng, feil svar gir −1 poeng.',
                      'Poengene blir XP og gir nye nivåer. Du faller aldri under nivået du har nådd.',
                      'Spørsmålene blir vanskeligere utover i runden, og du får ikke de samme igjen før du har vært gjennom alle.',
                    ],
                    choices: const [
                      Choice('Dagens utfordring',
                          'Ti spørsmål fra alle temaer – nye hver dag, like for alle', dailyChallenge),
                      Choice('Alt', 'Blandet fra alle temaer', null),
                      Choice('Regler', 'Offside, frispark og kortene', 'Regler'),
                      Choice('VM-historie', 'Verdensmesterskapene', 'VM-historie'),
                      Choice('EM-historie', 'Europamesterskapene', 'EM-historie'),
                      Choice('Klubbfotball', 'Klubber og ligaer', 'Klubbfotball'),
                      Choice('Ligaer', 'Premier League, La Liga, Serie A og Bundesliga', 'Ligaer'),
                      Choice('Spillere og rekorder', "Legender, rekorder og Ballon d'Or", 'Spillere og rekorder'),
                      Choice('Trenere', 'Managere og landslagstrenere', 'Trenere'),
                      Choice('Stadioner', 'Arenaer og kapasitet', 'Stadioner'),
                      Choice('Norge', 'Norsk fotball', 'Norge'),
                      Choice('Visste du at?', 'Kallenavn, kuriosa og mesterskap', 'Visste du at?'),
                    ],
                    onPick: (ctx, era) {
                      ref.read(quizEraProvider.notifier).set(era);
                      ref.invalidate(quizControllerProvider);
                      Navigator.of(ctx).push(MaterialPageRoute(
                          builder: (_) => const RulesQuizScreen()));
                    },
                  )),
                ),
                _ModeCard(
                  icon: const Icon(Icons.layers_outlined),
                  title: 'Sorter rekkefølgen',
                  onTap: () => open(ChoiceScreen(
                    title: 'Sorter rekkefølgen',
                    heading: 'Sett hendelser og vinnere i riktig rekkefølge.',
                    rules: const [
                      'Dra kortene opp og ned til rekkefølgen stemmer, og trykk «Sjekk rekkefølge».',
                      'Hele rekkefølgen må være riktig: +2 poeng. Feil rekkefølge gir −1 poeng.',
                    ],
                    choices: const [Choice('Start', '', null)],
                    onPick: (ctx, _) => Navigator.of(ctx).push(MaterialPageRoute(
                        builder: (_) => const ImageSortScreen())),
                  )),
                ),
                _ModeCard(
                  icon: const Icon(Icons.photo_camera_outlined),
                  title: 'Gjett fra bilde',
                  onTap: () => open(ChoiceScreen(
                    title: 'Gjett fra bilde',
                    heading: 'Se bildet og gjett riktig svar.',
                    rules: const [
                      '10 bilder per runde med fire svaralternativer.',
                      'Riktig svar gir +2 poeng, feil svar gir −1 poeng.',
                      'Trykk på ⓘ i bildet for å se hvem som tok det og lisensen.',
                      'Målvakter: bare målvakter. Hvilket land?: velg landet spilleren kommer fra.',
                      'Du får ikke de samme bildene igjen før du har sett alle.',
                    ],
                    choices: const [
                      Choice('Alt', 'Spillere, målvakter, land og stadioner blandet', null),
                      Choice('Gjett spilleren', 'Kjenn igjen spilleren fra bildet', 'player'),
                      Choice('Målvakter', 'Kjenn igjen målvaktene', 'goalkeeper'),
                      Choice('Hvilket land?', 'Hvilket land kommer spilleren fra?', 'country'),
                      Choice('Gjett stadionet', 'Hvilket stadion er dette?', 'stadium'),
                    ],
                    onPick: (ctx, v) => Navigator.of(ctx).push(MaterialPageRoute(
                        builder: (_) => PhotoQuizScreen(
                                mode: switch (v) {
                              'player' => PhotoMode.player,
                              'goalkeeper' => PhotoMode.goalkeeper,
                              'country' => PhotoMode.country,
                              'stadium' => PhotoMode.stadium,
                              _ => PhotoMode.mixed,
                            }))),
                  )),
                ),
                _ModeCard(
                  icon: const Icon(Icons.public),
                  title: 'Geografi-quiz',
                  onTap: () => open(ChoiceScreen(
                    title: 'Geografi-quiz',
                    heading: 'Plasser klubber og stadioner på kartet.',
                    rules: const [
                      '10 spørsmål, 60 sekunder per spørsmål. Tiden går også mens du zoomer.',
                      'Trykk på kartet for å sette nålen (trykk igjen for å flytte den). Zoom med to fingre, +/− eller dobbelttrykk.',
                      'Trykk «Bekreft plassering». Går tiden ut, bekreftes nålen automatisk (uten nål gir −1 poeng).',
                      'Poeng etter avstand: 0–25 km = +5, 25–100 km = +3, 100–500 km = +2, 500–1500 km = +1, lenger unna = −1.',
                    ],
                    choices: const [
                      Choice('Alt', 'Klubber og stadioner blandet', null),
                      Choice('Klubber', 'Hvor ligger klubben?', 'club'),
                      Choice('Stadioner og arenaer', 'Hvor ligger stadionet?', 'stadium'),
                    ],
                    onPick: (ctx, kind) => Navigator.of(ctx).push(MaterialPageRoute(
                        builder: (_) => GeoQuizScreen(kind: kind))),
                  )),
                ),
                _ModeCard(
                  icon: const Icon(Icons.sports_mma),
                  title: '1v1',
                  onTap: () => open(const DuelScreen()),
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GearButton extends StatelessWidget {
  const _GearButton({required this.onTap, this.icon = Icons.settings_outlined});
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.18),
            border:
                Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
          ),
          child: Icon(icon,
              size: 30, color: AppColors.gold.withValues(alpha: 0.7)),
        ),
      );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final Widget icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: SizedBox.expand(
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 8,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.gold, width: 1),
            ),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconTile(size: 44, iconSize: 26, radius: 12, child: icon),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900)),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.gold, size: 36),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

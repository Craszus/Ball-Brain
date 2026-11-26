import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'geo/geo_quiz_screen.dart';
import 'quiz/photo_quiz_screen.dart';
import 'duel/challenge_gate.dart';
import 'duel/duel_screen.dart';
import 'pro/pro_screen.dart';
import 'profile_screen.dart';
import 'quiz/image_sort_screen.dart';
import 'quiz/rules_quiz_screen.dart';
import 'services/pro.dart';
import 'services/profile.dart';
import 'services/stats.dart';
import 'duel/challenge_alerts.dart';
import 'settings_screen.dart';
import 'quiz/quiz_controller.dart';
import 'ui/avatar_view.dart';
import 'ui/challenge_alert.dart';
import 'ui/choice_screen.dart';
import 'ui/football.dart';
import 'ui/icon_tile.dart';
import 'ui/level_card.dart';
import 'ui/pro_frame.dart';
import 'ui/theme.dart';
import 'update_prompt.dart';
import 'l10n/l10n.dart';

/// Hovedmeny i stilen «Premium Nattkamp / Stadion-gull».
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final stats = ref.watch(statsProvider);
    final alerts = ref.watch(challengeAlertsProvider);
    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    final size = MediaQuery.sizeOf(context);
    // stående nettbrett: større logo og nivåkort, ellers ser de små ut
    final tallTablet = size.height > size.width && size.width >= 500;
    final top = Column(children: [
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
                  child: ProFrame(
                      frame: ref.watch(proProvider).shownFrame,
                      child: AvatarView(profile.avatar, size: 62)),
                ),
                Row(children: [
                  _GearButton(
                      icon: Icons.emoji_events_outlined,
                      onTap: () => open(const StatsScreen())),
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
                Center(child: BrandMark(width: tallTablet ? 82 : 56)),
                const SizedBox(height: 8),
                Text(
                  'BALL BRAIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: tallTablet ? 46 : 33,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Colors.white,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fotballkunnskap. Raskere. Skarpere.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: tallTablet ? 19 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => open(const StatsScreen()),
                  child: LevelCard(
                      xp: stats.totalPoints,
                      large: tallTablet,
                      pro: ref.watch(proProvider).active),
                ),
                const SizedBox(height: 8),
                _DailyStrip(
                  done: stats.count('dailyDay') == StatsController.dayNumber(DateTime.now()),
                  streak: stats.count('dailyStreak'),
                  onTap: () {
                    ref.read(quizEraProvider.notifier).set(dailyChallenge);
                    ref.invalidate(quizControllerProvider);
                    open(const RulesQuizScreen());
                  },
                ),
              ],
            ),
          ),
            ]);
    // Spillknappene deler høyden som er igjen (litt lavere på stående nettbrett)
    final modes = Padding(
      padding: EdgeInsets.fromLTRB(20, 2, 20, tallTablet ? 30 : 12),
      child: Column(
        children: [
                _ModeCard(
                  icon: const Icon(Icons.assignment_turned_in_outlined),
                  title: 'Fotballquiz',
                  onTap: () => open(ChoiceScreen(
                    title: 'Fotballquiz',
                    heading: 'Test fotballkunnskapen din.',
                    before: const ProQuizTools(whenActive: true),
                    after: const ProQuizTools(whenActive: false),
                    rules: const [
                      '10 spørsmål per runde. Velg riktig av fire alternativer.',
                      'Riktig svar gir +2 poeng, feil svar gir −1 poeng.',
                      'Poengene blir XP og gir nye nivåer. Du faller aldri under nivået du har nådd.',
                      'I dagens utfordring gir bare første forsøk XP og rangeringspoeng.',
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
                  title: 'Kamper',
                  alerts: alerts.total,
                  onTap: () => open(DuelScreen(initialTab: alerts.tab)),
                ),
        ],
      ),
    );
    // Liggende (nettbrett): toppen til venstre og spillknappene til høyre
    final sideBySide = size.width > size.height && size.width >= 700;

    return UpdateGate(
      child: ChallengeGate(
        child: PitchScaffold(
          wide: sideBySide,
          body: sideBySide
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: Center(child: SingleChildScrollView(child: top))),
                        Expanded(child: Padding(padding: const EdgeInsets.only(top: 8), child: modes)),
                      ],
                    ),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: top),
                    // Spillknappene fyller resten av skjermen under det gule XP-kortet
                    SliverFillRemaining(hasScrollBody: false, child: modes),
                  ],
                ),
        ),
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
    this.alerts = 0,
  });

  /// Antall utfordringer som venter (gult kort og gullpuls).
  final int alerts;

  final Widget icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final tallTablet = size.height > size.width && size.width >= 500;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tallTablet ? 6 : 4),
        child: SizedBox.expand(
          child: ChallengeAlert(
            count: alerts,
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
                      // Lange navn skaleres ned i stedet for å brytes på små skjermer
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(title,
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w900)),
                      ),
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
      ),
    );
  }
}

/// Snarveien til dagens utfordring: gullkantet stripe mellom nivåkortet og spillknappene.
class _DailyStrip extends StatelessWidget {
  const _DailyStrip({required this.done, required this.streak, required this.onTap});

  final bool done;
  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.gold.withValues(alpha: done ? 0.10 : 0.34),
              AppColors.gold.withValues(alpha: done ? 0.04 : 0.12),
            ]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold, width: done ? 1 : 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(children: [
                Icon(done ? Icons.check_circle : Icons.today, color: AppColors.gold, size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('Dagens utfordring',
                        maxLines: 1,
                        style: TextStyle(
                            color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                  ),
                ),
                if (streak > 1) ...[
                  const Icon(Icons.local_fire_department, color: Color(0xFFFF8F00), size: 20),
                  Text('$streak',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(width: 10),
                ],
                Text(done ? 'Spilt i dag' : 'Spill',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.gold)),
                const Icon(Icons.chevron_right, color: AppColors.gold),
              ]),
            ),
          ),
        ),
      );
}

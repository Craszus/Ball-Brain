import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../daily_board_screen.dart';
import '../profile_screen.dart' show ResultPanel;
import '../ui/answer_button.dart';
import '../ui/football.dart';
import '../ui/streak_badge.dart';
import '../ui/theme.dart';
import 'quiz_controller.dart';
import '../l10n/l10n.dart';

class RulesQuizScreen extends ConsumerWidget {
  const RulesQuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);
    final controller = ref.read(quizControllerProvider.notifier);
    final selection = ref.watch(quizEraProvider);
    final practice = isPractice(selection);
    // temanavnet står over spørsmålet, så overskriften holdes kort
    final title = selection == dailyChallenge
        ? 'Dagens utfordring'
        : practice
            ? 'Øving'
            : 'Fotballquiz';

    return PitchScaffold(
      title: title,
      actions: [ScoreChip(state.score)],
      body: Builder(builder: (_) {
        if (state.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final q = state.current;
        if (q == null && practice && state.questions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Du har ingen bom å øve på', textAlign: TextAlign.center),
            ),
          );
        }
        if (q == null) {
          return ResultPanel(
            practice: practice,
            score: state.score,
            note: practice
                ? 'Øvingsrunder: gir ikke XP eller rangeringspoeng.'
                : state.saved
                ? 'Poengene er lagret.'
                : 'Ikke lagret ennå (innlogging kommer).',
            onAgain: controller.start,
            dailyNote: state.dailyNote,
            onRanking: ref.watch(quizEraProvider) == dailyChallenge
                ? () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const DailyBoardScreen()))
                : null,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.index / state.questions.length,
                minHeight: 8,
                backgroundColor: Colors.black38,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SPØRSMÅL ${state.index + 1} AV ${state.questions.length}'
              '${q.era != null ? '  ·  ${q.era!.toUpperCase()}' : ''}',
              style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary),
            ),
            StreakBadge(state.streak),
            const SizedBox(height: 14),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.gold.withValues(alpha: 0.6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(q.prompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 1.25)),
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < q.options.length; i++)
              AnswerButton(
                letter: String.fromCharCode(65 + i),
                label: q.options[i],
                onTap: () => controller.answer(i),
              ),
          ],
        );
      }),
    );
  }
}

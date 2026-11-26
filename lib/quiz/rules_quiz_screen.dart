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
    final practice = isPractice(selection) || state.replay;
    // temanavnet står over spørsmålet, så overskriften holdes kort
    final title = selection == dailyChallenge
        ? 'Dagens utfordring'
        : isPractice(selection)
            ? 'Øving'
            : 'Fotballquiz';

    final atStake = state.atStake && !state.finished;
    final screen = PitchScaffold(
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
            logo: selection != dailyChallenge,
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
        final short = shortScreen(context);
        return ListView(
          padding: EdgeInsets.all(short ? 12 : 20),
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
            if (state.replay)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Du har spilt i dag. Dette er bare øving, uten XP.',
                    style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
              ),
            StreakBadge(state.streak),
            SizedBox(height: short ? 8 : 14),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.gold.withValues(alpha: 0.6)),
              ),
              child: Padding(
                padding: EdgeInsets.all(short ? 12 : 20),
                child: Text(q.prompt,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: short ? 18 : 21,
                        fontWeight: FontWeight.w900,
                        height: 1.25)),
              ),
            ),
            SizedBox(height: short ? 6 : 12),
            for (var i = 0; i < q.options.length; i++)
              AnswerButton(
                letter: String.fromCharCode(65 + i),
                label: q.options[i],
                mark: state.picked == null
                    ? null
                    : q.isCorrect(i)
                        ? AnswerMark.correct
                        : state.picked == i
                            ? AnswerMark.wrong
                            : null,
                onTap: () => controller.answer(i),
              ),
          ],
        );
      }),
    );
    return PopScope(
      canPop: !atStake,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeaveDaily(context);
      },
      child: screen,
    );
  }

  /// Bare første forsøk teller, så man får et varsel før det går tapt.
  Future<void> _confirmLeaveDaily(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gå ut av dagens utfordring?'),
        content: const Text('Forsøket ditt i dag går tapt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Bli her')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gå ut')),
        ],
      ),
    );
    if (leave == true && context.mounted) Navigator.of(context).pop();
  }
}

import 'package:ball_brain/quiz/quiz_controller.dart';
import 'package:ball_brain/quiz/rules_quiz_screen.dart';
import 'package:ball_brain/services/stats.dart';
import 'package:ball_brain/ui/answer_button.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('nytt forsøk på dagens utfordring gir verken XP eller rekorder', (tester) async {
    SharedPreferences.setMockInitialValues(
        {dailyAnsweredKey: StatsController.dayNumber(DateTime.now())});
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(quizEraProvider.notifier).set(dailyChallenge);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildTheme(), home: const RulesQuizScreen())));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Du har spilt i dag. Dette er bare øving, uten XP.'), findsOneWidget);
    for (var i = 0; i < quizLength; i++) {
      await tester.ensureVisible(find.byType(AnswerButton).first);
      await tester.tap(find.byType(AnswerButton).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
    }
    await tester.pump(const Duration(seconds: 2));
    expect(container.read(quizControllerProvider).finished, isTrue);
    // ingen «+12 XP»-linje (forklaringsteksten nevner XP og er ikke med her)
    expect(find.textContaining(RegExp(r'\d XP')), findsNothing);
    expect(container.read(statsProvider).totalPoints, 0);
    expect(container.read(statsProvider).games, 0);
    expect(container.read(statsProvider).count('dailyPlayed'), 0);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}

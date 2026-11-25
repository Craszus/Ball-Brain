import 'package:ball_brain/quiz/image_sort_screen.dart';
import 'package:ball_brain/quiz/rules_quiz_screen.dart';
import 'package:ball_brain/ui/answer_button.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> open(WidgetTester tester, Widget screen) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(child: MaterialApp(theme: buildTheme(), home: screen)));
    // spørsmålene leses fra seed-filen utenfor testklokka
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('dobbelttrykk svarer bare på ett spørsmål, og fasiten vises', (tester) async {
    await open(tester, const RulesQuizScreen());
    expect(find.textContaining('SPØRSMÅL 1 AV 10'), findsOneWidget);
    await tester.tap(find.byType(AnswerButton).first);
    await tester.tap(find.byType(AnswerButton).first);
    await tester.pump();
    expect(find.textContaining('SPØRSMÅL 1 AV 10'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.textContaining('SPØRSMÅL 2 AV 10'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('sorteringen viser riktig rekkefølge før neste oppgave', (tester) async {
    await open(tester, const ImageSortScreen());
    expect(find.text('OPPGAVE 1 AV 10'), findsOneWidget);
    await tester.tap(find.text('Sjekk rekkefølge'));
    await tester.pump();
    // startrekkefølgen er aldri riktig
    expect(find.text('RIKTIG REKKEFØLGE:'), findsOneWidget);
    await tester.tap(find.text('Neste')); // for raskt: telles ikke
    await tester.pump();
    expect(find.text('OPPGAVE 1 AV 10'), findsOneWidget);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 700)));
    await tester.tap(find.text('Neste'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('OPPGAVE 2 AV 10'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}

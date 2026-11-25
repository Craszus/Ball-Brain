import 'package:ball_brain/club/club_api.dart';
import 'package:ball_brain/club/club_badge.dart';
import 'package:ball_brain/data/pack_repository.dart';
import 'package:ball_brain/models/question.dart';
import 'package:ball_brain/pro/pro_screen.dart';
import 'package:ball_brain/profile_screen.dart';
import 'package:ball_brain/services/ads.dart';
import 'package:ball_brain/services/learning.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget app(Widget home) =>
    ProviderScope(child: MaterialApp(theme: buildTheme(), home: home));

Question q(String key, String topic) => Question(
    id: 1,
    type: QuestionType.rulesQuiz,
    prompt: key,
    options: const ['a', 'b'],
    correct: 0,
    era: topic,
    key: key);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bom huskes til de besvares riktig, og temaene telles', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final learn = c.read(learningProvider.notifier);
    await learn.record(q('x', 'Regler'), false);
    await learn.record(q('y', 'Regler'), true);
    expect(c.read(learningProvider).missed, ['x']);
    await learn.record(q('x', 'Regler'), true);
    expect(c.read(learningProvider).missed, isEmpty);
    expect(c.read(learningProvider).topics['Regler']!.correct, 2);
    expect(c.read(learningProvider).topics['Regler']!.total, 3);

    // lagret til neste oppstart
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    await c2.read(learningProvider.notifier).ready;
    expect(c2.read(learningProvider).topics['Regler']!.total, 3);
  });

  test('pakkene har gyldige og unike spørsmål', () async {
    final packs = await loadPacks();
    expect(packs.map((p) => p.id), ['cl', 'pl', 'nor', 'ref']);
    final keys = <String>{};
    for (final p in packs) {
      expect(p.questions.length, greaterThanOrEqualTo(15), reason: p.title);
      for (final x in p.questions) {
        expect(keys.add(x.uid), isTrue, reason: x.prompt);
        expect(x.options.toSet().length, x.options.length, reason: x.prompt);
        expect(x.correct as int, inInclusiveRange(0, x.options.length - 1));
        expect(x.era, p.title);
      }
    }
  });

  test('Pro fjerner annonsetilbudet', () async {
    SharedPreferences.setMockInitialValues({'ads.rounds': adEveryRounds - 1});
    expect(await Ads.available(), isTrue);
    SharedPreferences.setMockInitialValues(
        {'pro.active': true, 'ads.rounds': adEveryRounds - 1});
    expect(await Ads.available(), isFalse);
    expect(await Ads.offer(20), 0);
  });

  testWidgets('Pro kan prøves uten betaling og låser opp innholdet', (tester) async {
    SharedPreferences.setMockInitialValues({});
    phone(tester);
    await tester.pumpWidget(app(const ProScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Statistikk per tema'), findsNothing);
    await tester.scrollUntilVisible(find.text('Prøv Pro (test)'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prøv Pro (test)'));
    await tester.pumpAndSettle();
    expect(find.text('Statistikk per tema'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getBool('pro.active'), isTrue);
  });

  testWidgets('statistikken viser sterkest og svakest tema', (tester) async {
    SharedPreferences.setMockInitialValues({'learn.topics': '{"Regler":[9,10],"Norge":[2,10]}'});
    phone(tester);
    await tester.pumpWidget(app(const TopicStatsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Sterkest: Regler'), findsOneWidget);
    expect(find.text('Svakest: Norge'), findsOneWidget);
    expect(find.text('2 av 10 riktige'), findsOneWidget);
  });

  testWidgets('øvingsrunder viser verken XP eller annonse', (tester) async {
    SharedPreferences.setMockInitialValues({'ads.rounds': adEveryRounds - 1});
    phone(tester);
    await tester.pumpWidget(app(Scaffold(
        body: ResultPanel(score: 12, note: 'n', onAgain: () {}, practice: true))));
    await tester.pumpAndSettle();
    expect(find.text('12 poeng'), findsOneWidget);
    expect(find.text('+12 XP'), findsNothing);
    expect(find.textContaining('annonse'), findsNothing);
  });

  testWidgets('alle klubbskjoldene kan tegnes', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Wrap(children: [
        for (var e = 0; e < clubEmblems; e++)
          ClubBadge(ClubInfo(id: '$e', name: 'K', color1: 0, color2: 1, emblem: e)),
      ]),
    ));
    expect(tester.takeException(), isNull);
  });
}

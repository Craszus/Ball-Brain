import 'package:ball_brain/party/quiz_night_api.dart';
import 'package:ball_brain/party/quiz_night_screen.dart';
import 'package:ball_brain/services/stats.dart';
import 'package:ball_brain/settings_screen.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// En «server» i minnet: går gjennom lobby -> spørsmål -> svar -> ferdig.
class FakeApi extends QuizNightApi {
  FakeApi(this.current);
  NightState current;
  final sent = <String>[];

  static NightState night(String status,
          {bool host = false, bool playing = true, String? mine, int players = 3}) =>
      NightState(
        id: 'n1',
        code: 'ABCDE',
        status: status,
        total: 1,
        seconds: 20,
        host: host,
        playing: playing,
        players: players,
        leftMs: 15000,
        prompt: 'Hvem vant?',
        options: const ['Norge', 'Brasil', 'Italia', 'Spania'],
        right: status == 'reveal' ? 'Norge' : null,
        myAnswer: mine,
        myAnswered: mine != null,
        myPoints: status == 'reveal' ? 13 : null,
        myRank: 1,
        standings: status == 'question'
            ? const []
            : const [NightRow(rank: 1, name: 'Meg selv med et veldig langt navn', score: 13, me: true)],
      );

  @override
  Future<NightState> state(String id) async => current;

  @override
  Future<NightState> next(NightState from) async {
    current = night(
        switch (from.status) {
          'lobby' => 'question',
          'question' => 'reveal',
          _ => 'finished',
        },
        host: from.host,
        playing: from.playing);
    return current;
  }

  @override
  Future<NightState> answer(String id, int idx, String answer) async {
    sent.add(answer);
    current = night('question', mine: answer);
    return current;
  }
}

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget app(Widget home) => ProviderScope(child: MaterialApp(theme: buildTheme(), home: home));

void main() {
  testWidgets('deltakeren svarer én gang og ser ikke fasiten mens spørsmålet er åpent',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    phone(tester);
    final api = FakeApi(FakeApi.night('question'));
    await tester.pumpWidget(app(QuizNightScreen(initial: api.current, api: api)));
    await tester.pump();
    expect(find.text('Vis svaret'), findsNothing);
    await tester.tap(find.text('Brasil'));
    await tester.pump();
    await tester.tap(find.text('Italia'));
    await tester.pump();
    expect(api.sent, ['Brasil']);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('verten styrer fra lobby til resultat, og kvelden gir pokaler', (tester) async {
    SharedPreferences.setMockInitialValues({});
    phone(tester);
    final api = FakeApi(FakeApi.night('lobby', host: true));
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
          theme: buildTheme(), home: QuizNightScreen(initial: api.current, api: api)),
    ));
    await tester.pump();
    expect(find.text('ABCDE'), findsOneWidget);
    for (final button in ['Start quizen', 'Vis svaret', 'Vis resultatet']) {
      await tester.tap(find.text(button));
      await tester.pump();
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('vant!'), findsOneWidget);
    final stats = container.read(statsProvider);
    expect(stats.count('partyPlayed'), 1);
    expect(stats.count('partyWins'), 1);
    expect(stats.count('partyHosted'), 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('oppsett av quizkveld får plass på en smal skjerm', (tester) async {
    phone(tester);
    await tester.pumpWidget(app(const QuizNightSetupScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Antall spørsmål'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('dagens utfordring teller én gang pr. dag og husker dager på rad', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final stats = c.read(statsProvider.notifier);
    for (var d = 1; d <= 7; d++) {
      await stats.recordDaily(perfect: d == 1, now: DateTime(2026, 11, d, 20));
      await stats.recordDaily(perfect: true, now: DateTime(2026, 11, d, 23));
    }
    expect(c.read(statsProvider).count('dailyPlayed'), 7);
    expect(c.read(statsProvider).count('dailyBestStreak'), 7);
    expect(c.read(statsProvider).count('dailyPerfect'), 1);
    expect(stats.lastUnlocked.map((t) => t.id), contains('daily_7'));
    await stats.recordDaily(perfect: false, now: DateTime(2026, 11, 20));
    expect(c.read(statsProvider).count('dailyStreak'), 1);
    expect(c.read(statsProvider).count('dailyBestStreak'), 7);
  });

  test('samme hendelse telles bare én gang, og Pro-pokaler telles ikke uten Pro', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final stats = c.read(statsProvider.notifier);
    await stats.bump('clubPlayed', once: 'g1');
    await stats.bump('clubPlayed', once: 'g1');
    expect(c.read(statsProvider).count('clubPlayed'), 1);
    expect(trophiesFor(pro: false).any((t) => t.group == TrophyGroup.practice), isFalse);
    expect(trophiesFor(pro: true).length, trophies.length);
    expect(trophies.map((t) => t.id).toSet().length, trophies.length);
  });

  testWidgets('innstillingene er delt i grupper, med sletting nederst', (tester) async {
    SharedPreferences.setMockInitialValues({});
    phone(tester);
    await tester.pumpWidget(app(const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('LYD OG VIBRASJON'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Slett all min data'), 300);
    expect(find.text('NULLSTILL OG SLETT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

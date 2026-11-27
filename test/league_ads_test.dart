import 'package:ball_brain/club/club_api.dart';
import 'package:ball_brain/club/club_league.dart';
import 'package:ball_brain/club/club_table_screen.dart';
import 'package:ball_brain/profile_screen.dart';
import 'package:ball_brain/services/ads.dart';
import 'package:ball_brain/services/stats.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:ball_brain/ui/level_up.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('klubbtabellen viser plass, navn, resultater og poeng, og kan byttes til totalt',
      (tester) async {
    phone(tester);
    final asked = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: ClubTableScreen(load: (period) async {
        asked.add(period);
        return [
          StandingRow.fromJson({
            'rank': 1, 'id': 'h', 'name': 'En klubb med veldig langt navn her', 'color1': 0,
            'color2': 1, 'emblem': 1, 'mine': true, 'w': 12, 'd': 3, 'l': 4, 'points': 39,
          }),
        ];
      }),
    ));
    await tester.pumpAndSettle();
    expect(find.text('39 poeng'), findsOneWidget);
    expect(find.text('Seier 12 · Uavgjort 3 · Tap 4'), findsOneWidget);
    await tester.tap(find.text('Totalt'));
    await tester.pumpAndSettle();
    expect(asked, ['month', 'all']);
  });

  testWidgets('i klubbserien kan jeg utfordre andre, men ikke meg selv', (tester) async {
    phone(tester);
    final challenged = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
        body: ListView(children: [
          ClubLeague(
            clubId: 'k',
            onChallenge: (id, name) => challenged.add(id),
            load: (club, period) async => [
              StandingRow.fromJson({'rank': 1, 'user_id': 'a', 'name': 'Meg', 'me': true}),
              StandingRow.fromJson({'rank': 2, 'user_id': 'b', 'name': 'Ola', 'me': false}),
            ],
          ),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.sports_mma), findsOneWidget);
    await tester.tap(find.byIcon(Icons.sports_mma));
    expect(challenged, ['b']);
  });

  test('annonser: av etter nei, og dagsgrensen nullstilles neste dag', () async {
    SharedPreferences.setMockInitialValues({});
    final day = DateTime(2026, 11, 25);
    expect(await Ads.available(day), isTrue);
    for (var i = 0; i < adDailyLimit; i++) {
      await Ads.recordWatched(1, day);
    }
    expect(await Ads.available(day), isFalse);
    expect(await Ads.available(DateTime(2026, 11, 26)), isTrue);
    await Ads.setConsent(false);
    expect(await Ads.available(DateTime(2026, 11, 26)), isFalse);
  });

  test('annonser: tilbys bare hver tredje runde, og bonus-XP har et dagstak', () async {
    SharedPreferences.setMockInitialValues({});
    final day = DateTime(2026, 11, 25);
    expect(await Ads.offer(50, day), 0);
    expect(await Ads.offer(0, day), 0); // runder uten poeng teller ikke
    expect(await Ads.offer(50, day), 0);
    expect(await Ads.offer(50, day), 50);
    await Ads.recordWatched(50, day);
    expect(await Ads.offer(50, day), 0);
    expect(await Ads.offer(50, day), 0);
    expect(await Ads.offer(50, day), adDailyXp - 50);
    await Ads.recordWatched(adDailyXp - 50, day);
    expect(await Ads.available(day), isFalse);
    expect(await Ads.bonusLeft(DateTime(2026, 11, 26)), adDailyXp);
  });

  testWidgets('se en testannonse gir bonus-XP, én gang', (tester) async {
    SharedPreferences.setMockInitialValues({'totalPoints': 20, 'ads.rounds': adEveryRounds - 1});
    phone(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(statsProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(),
        home: Scaffold(body: ResultPanel(score: 12, note: 'n', onAgain: () {})),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Vil du ha bonus-XP?'), findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text('Se en annonse: +12 XP')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ja'));
    await tester.pumpAndSettle();
    expect(find.text('Testannonse'), findsOneWidget);
    for (var i = 0; i < adSeconds; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.tap(find.text('Få bonusen'));
    await tester.pumpAndSettle();
    expect(container.read(statsProvider).totalPoints, 32);
    expect(find.text('+12 XP i bonus'), findsOneWidget);
    expect(find.text('Se en annonse: +12 XP'), findsNothing);
  });

  testWidgets('«Ikke nå» lukker vinduet, men knappen blir stående', (tester) async {
    SharedPreferences.setMockInitialValues({'totalPoints': 20, 'ads.rounds': adEveryRounds - 1});
    phone(tester);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: buildTheme(),
        home: Scaffold(body: ResultPanel(score: 12, note: 'n', onAgain: () {})),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ikke nå'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Vil du ha bonus-XP?'), findsNothing);
    expect(find.text('Se en annonse: +12 XP'), findsOneWidget);
  });

  testWidgets('tilbudet venter til nivåfeiringen er lukket', (tester) async {
    SharedPreferences.setMockInitialValues({'totalPoints': 1000, 'ads.rounds': adEveryRounds - 1});
    phone(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(statsProvider);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(),
        home: Scaffold(body: ResultPanel(score: 1000, note: 'n', onAgain: () {})),
      ),
    ));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(LevelUpOverlay), findsOneWidget);
    expect(find.text('Vil du ha bonus-XP?'), findsNothing);
    await tester.ensureVisible(find.text('Fortsett'));
    await tester.tap(find.text('Fortsett'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Vil du ha bonus-XP?'), findsOneWidget);
  });
}

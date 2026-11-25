import 'dart:io';

import 'package:ball_brain/duel/challenge_alerts.dart';
import 'package:ball_brain/home_screen.dart';
import 'package:ball_brain/services/stats.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('alle pokalene har eget bilde', () {
    for (final t in trophies) {
      expect(File(t.asset).existsSync(), isTrue, reason: t.id);
    }
  });

  testWidgets('forsiden viser om dagens utfordring er spilt, og varsler om utfordringer',
      (tester) async {
    final today = StatsController.dayNumber(DateTime.now());
    SharedPreferences.setMockInitialValues({'counts': '{"dailyDay":$today,"dailyStreak":4}'});
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Spilt i dag'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('2'), findsNothing);

    container.read(challengeAlertsProvider.notifier).setDuels(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('Kamper'));
    expect(find.text('2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    container.read(challengeAlertsProvider.notifier).setDuels(0);
    await tester.pumpAndSettle(); // animasjonen stopper når ingen venter
    expect(find.text('2'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  test('bare klubbutfordring åpner klubbfanen', () {
    expect(const ChallengeAlerts(clubs: 1).tab, 1);
    expect(const ChallengeAlerts(duels: 1, clubs: 1).tab, 0);
    expect(const ChallengeAlerts(duels: 1, clubs: 1).total, 2);
  });
}

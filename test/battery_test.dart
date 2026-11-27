import 'package:ball_brain/services/visibility.dart';
import 'package:ball_brain/ui/challenge_alert.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget alert(int count) => MaterialApp(
      home: Scaffold(body: ChallengeAlert(count: count, child: const SizedBox(width: 300, height: 60))));

  testWidgets('varselet på «Kamper» pulserer en stund og står så stille', (tester) async {
    await tester.pumpWidget(alert(1));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle(); // stopper av seg selv
    expect(find.text('1'), findsOneWidget);

    await tester.pumpWidget(alert(1)); // vanlig oppdatering: ikke på nytt
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(alert(2)); // ny utfordring: pulser igjen
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('nettsjekker hoppes over når appen ligger i bakgrunnen', (tester) async {
    addTearDown(() => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    for (final (state, visible) in [
      (AppLifecycleState.resumed, true),
      (AppLifecycleState.inactive, true),
      (AppLifecycleState.hidden, false),
      (AppLifecycleState.paused, false),
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      expect(appVisible(), visible, reason: '$state');
    }
  });
}

import 'package:ball_brain/quiz/photo_quiz_screen.dart';
import 'package:ball_brain/ui/credited_photo.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // ellers henger lasting av en fil som ble lest i en tidligere test
  setUp(rootBundle.clear);

  testWidgets('bildequizen viser spørsmål med fire alternativer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: buildTheme(), home: const PhotoQuizScreen()),
    ));
    // Bildene lastes fra appens egne filer (asynkront), så gi den tid.
    for (var i = 0; i < 20 && find.textContaining('BILDE 1 AV').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('BILDE 1 AV'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget); // ⓘ-kreditering
    expect(
        find.byWidgetPredicate((w) => w is Text && (w.style?.fontSize == 16)),
        findsNWidgets(4));
    await tester.pumpWidget(const SizedBox());
  });

  // Huawei P10 Lite og lignende: 360 × 640 med status- og navigasjonslinje.
  for (final mode in [PhotoMode.player, PhotoMode.stadium, PhotoMode.country]) {
    testWidgets('liten skjerm: alle svar og bildet vises uten rulling (${mode.name})',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 592);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(theme: buildTheme(), home: PhotoQuizScreen(mode: mode)),
      ));
      for (var i = 0; i < 20 && find.textContaining('BILDE 1 AV').evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(Scrollable), findsNothing);
      final options = find.byWidgetPredicate((w) => w is Text && w.style?.fontSize == 16);
      expect(options, findsNWidgets(4));
      for (var i = 0; i < 4; i++) {
        expect(tester.getBottomLeft(options.at(i)).dy, lessThan(592));
      }
      expect(tester.getSize(find.byType(CreditedPhoto)).height, greaterThan(150));
      await tester.pumpWidget(const SizedBox());
    });
  }
}

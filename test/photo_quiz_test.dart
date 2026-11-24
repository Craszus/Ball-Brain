import 'package:ball_brain/quiz/photo_quiz_screen.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
        find.byWidgetPredicate((w) => w is Text && (w.style?.fontSize == 18)),
        findsNWidgets(4));
    await tester.pumpWidget(const SizedBox());
  });
}

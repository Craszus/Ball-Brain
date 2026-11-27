import 'package:ball_brain/home_screen.dart';
import 'package:ball_brain/ui/rules_card.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('hovedmenyen følger briefen (375 x 812)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
    ));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('BALL BRAIN'), findsOneWidget);
    expect(find.text('Fotballkunnskap. Raskere. Skarpere.'), findsOneWidget);
    expect(find.text('LVL'), findsOneWidget);
    expect(find.text('Benkesliter'), findsOneWidget);
    expect(find.text('0 / 50 XP'), findsOneWidget);
    expect(find.text('Fotballquiz'), findsOneWidget);
    expect(find.text('Dagens utfordring'), findsOneWidget);
    expect(find.text('Sorter rekkefølgen'), findsOneWidget);
    expect(find.text('Geografi-quiz'), findsOneWidget);
    expect(find.text('Kamper'), findsOneWidget);
    expect(find.text('1v1 og klubbkamp'), findsNothing); // ingen tekst under navnet
    expect(find.text('Profil og trofeer'), findsNothing); // profil via avataren
    // Ingen layoutfeil (overflow) ved mobilbredde
    expect(tester.takeException(), isNull);

    // Det gule nivåkortet åpner statistikk og troféer
    await tester.tap(find.text('Benkesliter'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('STATISTIKK OG TROFÉER'), findsOneWidget);
    expect(find.text('Troféskap'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Fotballquiz og Geografi-quiz har valgmeny', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
    ));
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.text('Geografi-quiz'));
    await tester.pump();
    await tester.tap(find.text('Geografi-quiz'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Alt'), findsOneWidget);
    expect(find.text('Klubber'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Stadioner og arenaer'), 200);
    expect(find.text('Stadioner og arenaer'), findsOneWidget);
    // reglene er sammenfoldet til man trykker
    await tester.scrollUntilVisible(find.text('SLIK FUNGERER DET'), 200);
    expect(find.byType(RulesCard), findsOneWidget);
    final before = tester.getSize(find.byType(RulesCard)).height;
    expect(before, lessThan(60));
    await tester.ensureVisible(find.text('SLIK FUNGERER DET'));
    await tester.tap(find.text('SLIK FUNGERER DET'));
    await tester.pump();
    expect(tester.getSize(find.byType(RulesCard)).height, greaterThan(before));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('hovedmenyen får plass på en vanlig telefon uten å rulle (360 x 760)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
    ));
    await tester.pump(const Duration(seconds: 1));
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scroll.position.maxScrollExtent, 0, reason: 'menyen må ikke trenge scrolling');
    // Spillknappene fyller helt ned til bunnen av skjermen
    final last = tester.getRect(find.text('Kamper').first);
    final cards = tester.getRect(find.ancestor(of: find.text('Kamper'), matching: find.byType(Card)).first);
    // Fotballskolen er et symbol øverst, ikke en knapp i lista
    expect(find.text('Fotballskolen'), findsNothing);
    expect(tester.getCenter(find.byIcon(Icons.school_outlined)).dy,
        closeTo(tester.getCenter(find.byIcon(Icons.emoji_events_outlined)).dy, 1));
    expect(cards.bottom, greaterThan(700));
    expect(cards.height, greaterThan(56));
    expect(last.height, greaterThan(0));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('paletten er eksakt som i briefen', () {
    expect(AppColors.pitch, const Color(0xFF0B3D2E));
    expect(AppColors.card, const Color(0xFF145A42));
    expect(AppColors.gold, const Color(0xFFF5B301));
    expect(AppColors.goldLight, const Color(0xFFFFD84D));
    expect(AppColors.goldLighter, const Color(0xFFFFE27A));
    expect(AppColors.goldDark, const Color(0xFFD99A00));
    expect(AppColors.tile, const Color(0xFF0A1224));
    expect(AppColors.textSecondary, const Color(0xFFC9D6C8));
    expect(AppColors.grass, const Color(0xFF2E9E5B));
  });
}

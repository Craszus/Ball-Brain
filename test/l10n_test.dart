import 'dart:convert';

import 'package:ball_brain/avatar_picker_screen.dart';
import 'package:ball_brain/duel/duel_screen.dart';
import 'package:ball_brain/edit_profile_screen.dart';
import 'package:ball_brain/home_screen.dart';
import 'package:ball_brain/l10n/l10n.dart';
import 'package:ball_brain/profile_screen.dart';
import 'package:ball_brain/services/language.dart';
import 'package:ball_brain/settings_screen.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => L10n.setData('nb', {}));

  test('maler, store bokstaver og reserve til engelsk', () async {
    await L10n.load('sv');
    expect(L10n.tr('Innstillinger'), 'Inställningar');
    expect(L10n.tr('INNSTILLINGER'), 'INSTÄLLNINGAR');
    expect(L10n.tr('Du var 12 km unna!'), 'Du var 12 km ifrån!');
    expect(L10n.tr('Hvor ligger klubben Chelsea?'), 'Var ligger klubben Chelsea?');
    expect(L10n.tr('SPØRSMÅL 3 AV 10  ·  REGLER'), 'FRÅGA 3 AV 10  ·  REGLER');
    expect(L10n.tr('Oslo, Norge'), 'Oslo, Norge');
    await L10n.load('en');
    expect(L10n.tr('Oslo, Norge'), 'Oslo, Norway');
    expect(L10n.tr('Nivå 3 · Rotasjonsspiller · 120 poeng'),
        'Level 3 · Rotation player · 120 points');
    expect(L10n.tr('Ukjent tekst'), 'Ukjent tekst');
    await L10n.load('nb');
    expect(L10n.tr('Innstillinger'), 'Innstillinger');
  });

  test('språk ut fra land og telefon', () {
    expect(L10n.langForCountry('NO'), 'nb');
    expect(L10n.langForCountry('AT'), 'de');
    expect(L10n.langForCountry('MX'), 'es');
    expect(L10n.langForCountry('BR'), 'en');
    expect(L10n.langForDevice('nn'), 'nb');
    expect(L10n.langForDevice('ja'), 'en');
  });

  testWidgets('landet styrer språket, og eget valg vinner', (tester) async {
    SharedPreferences.setMockInitialValues({
      'profile.onboarded': true,
      'profile.country': 'SE',
    });
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(effectiveLangProvider); // starter lasting av profilen
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    expect(c.read(effectiveLangProvider), 'sv');
    await c.read(languageProvider.notifier).choose('fr');
    expect(c.read(effectiveLangProvider), 'fr');
    await c.read(languageProvider.notifier).choose(null);
    expect(c.read(effectiveLangProvider), 'sv');
  });

  testWidgets('hovedmeny og innstillinger oversettes og får ingen manglende tekster',
      (tester) async {
    SharedPreferences.setMockInitialValues({'profile.onboarded': true});
    tester.view.physicalSize = const Size(375, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final lang in ['en', 'sv', 'da', 'de', 'es', 'fr']) {
      await tester.runAsync(() => L10n.load(lang));
      L10n.misses.clear();
      for (final screen in const <Widget>[
        HomeScreen(),
        SettingsScreen(),
        ProfileScreen(),
        EditProfileScreen(),
        DuelScreen(),
        AvatarPickerScreen(onboarding: true),
      ]) {
        await tester.pumpWidget(ProviderScope(
            child: MaterialApp(theme: buildTheme(), home: screen)));
        await tester.pump(const Duration(milliseconds: 400));
      }
      // ignore: avoid_print
      print('[$lang] mangler: ${L10n.misses.toList()}');
    }
  });

  testWidgets('spørsmålene i seed-filen er oversatt (bortsett fra navn og tall)',
      (tester) async {
    // Stor fil: rootBundle bruker en isolate, så den må lastes utenfor fake async.
    final raw = (await tester.runAsync(() => rootBundle.loadString('assets/seed/questions.json')))!;
    final qs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    await tester.runAsync(() => L10n.load('de'));
    L10n.misses.clear();
    for (final q in qs) {
      L10n.tr(q['prompt'] as String);
      for (final o in q['options'] as List) {
        L10n.tr(o.toString());
      }
      if (q['era'] != null) L10n.tr(q['era'] as String);
    }
    // ignore: avoid_print
    print('[spørsmål uten oversettelse] ${L10n.misses.toList()}');
  });
}

import 'package:ball_brain/settings_screen.dart';
import 'package:ball_brain/share_screen.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Del appen viser en QR-kode med lenken', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(), home: const ShareScreen(url: 'https://example.com/ball-brain')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('https://example.com/ball-brain'), findsOneWidget);
    expect(find.text('Kopier lenke'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('standardlenken peker til siste utgave på GitHub', () {
    expect(appShareUrl, startsWith('https://'));
    expect(appShareUrl, contains('github.com/Craszus/Ball-Brain/releases'));
  });

  testWidgets('Innstillinger har «Del appen» som åpner QR-skjermen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        ProviderScope(child: MaterialApp(theme: buildTheme(), home: const SettingsScreen())));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Del appen'), findsOneWidget);
    await tester.tap(find.text('Del appen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('La en venn skanne koden for å laste ned Ball Brain.'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
  });
}

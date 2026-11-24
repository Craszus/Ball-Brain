import 'package:ball_brain/l10n/l10n.dart';
import 'package:ball_brain/services/update_check.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:ball_brain/update_prompt.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> release({String body = 'Bygg 12 fra abc1234.', String name = 'siste', List assets = const [
  {'name': 'BallBrain.apk', 'browser_download_url': 'https://example.com/BallBrain.apk'}
]}) =>
    {'body': body, 'name': name, 'html_url': 'https://example.com/release', 'assets': assets};

void main() {
  test('nyere bygg gir oppdatering med direkte APK-lenke', () {
    final u = parseLatestRelease(release(), 5);
    expect(u, isNotNull);
    expect(u!.build, 12);
    expect(u.url, 'https://example.com/BallBrain.apk');
  });

  test('samme eller eldre bygg gir ingen oppdatering', () {
    expect(parseLatestRelease(release(), 12), isNull);
    expect(parseLatestRelease(release(), 40), isNull);
  });

  test('byggnummer kan stå i tittelen, og uten APK brukes utgavesiden', () {
    final u = parseLatestRelease(release(body: '', name: 'Ball Brain – siste bygg (7)', assets: const []), 3);
    expect(u!.build, 7);
    expect(u.url, 'https://example.com/release');
  });

  test('utgave uten byggnummer eller lenke ignoreres', () {
    expect(parseLatestRelease(release(body: 'Hei', name: 'v1'), 1), isNull);
    expect(parseLatestRelease({'body': 'Bygg 9', 'assets': const []}, 1), isNull);
  });

  testWidgets('dialogen viser byggnummer og knappene Last ned / Senere', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Builder(
        builder: (ctx) => Scaffold(
          body: TextButton(
            onPressed: () => showUpdateDialog(
                ctx, const AppUpdate(build: 12, url: 'https://example.com/a.apk')),
            child: const Text('åpne'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('åpne'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ny versjon tilgjengelig'), findsOneWidget);
    expect(find.text('Bygg 12 er klar. Last ned og installer for å oppdatere.'), findsOneWidget);
    expect(find.text('Last ned'), findsOneWidget);
    await tester.tap(find.text('Senere'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ny versjon tilgjengelig'), findsNothing);
  });
}

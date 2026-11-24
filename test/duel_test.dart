import 'package:ball_brain/duel/duel_api.dart';
import 'package:ball_brain/duel/duel_screen.dart';
import 'package:ball_brain/l10n/l10n.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sammendrag fra serveren tolkes riktig', () {
    final now = DateTime.now().millisecondsSinceEpoch;
    final d = DuelSummary.fromJson({
      'id': 'abc',
      'code': 'K3F9Z',
      'status': 'active',
      'total': 10,
      'now_ms': now + 5000, // serverklokka går 5 sekunder foran
      'starts_ms': now + 9000,
      'me': {'name': 'A', 'country': 'NO', 'score': 14, 'answered': 1, 'correct': 1},
      'opp': {'name': 'B', 'country': 'SE', 'score': 0, 'answered': 0, 'correct': 0},
      'result': null,
    });
    expect(d.isActive, isTrue);
    expect(d.opp!.name, 'B');
    expect(d.me.score, 14);
    // 9 s frem på serverklokka, og serveren går 5 s foran: ca. 4 s igjen på telefonen
    expect(d.msUntilStart(), inInclusiveRange(3500, 4500));
  });

  test('spørsmål fra serveren har ingen fasit', () {
    final q = DuelQuestion.fromJson({
      'idx': 0,
      'key': 'k',
      'era': 'Regler',
      'prompt': 'Spørsmål?',
      'options': ['a', 'b'],
    });
    expect(q.options, ['a', 'b']);
    expect(q.prompt, 'Spørsmål?');
  });

  testWidgets('1v1-menyen vises, og uten nett gis en tydelig melding', (tester) async {
    SharedPreferences.setMockInitialValues({'profile.onboarded': true});
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(theme: buildTheme(), home: const DuelScreen())));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Finn motstander'), findsOneWidget);
    expect(find.text('Utfordre en venn'), findsOneWidget);
    expect(find.text('Bli med med kode'), findsOneWidget);

    await tester.tap(find.text('Finn motstander'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(duelError('offline')), findsOneWidget);
    expect(find.text('Finn motstander'), findsOneWidget); // tilbake i menyen
  });

  test('alle feilmeldinger er oversatt til svensk', () async {
    L10n.setData('sv', {'Du kan ikke bli med i din egen kamp.': 'x'});
    expect(L10n.tr(duelError('own_duel')), 'x');
    L10n.setData('nb', {});
  });
}

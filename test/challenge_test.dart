import 'package:ball_brain/duel/challenge_gate.dart';
import 'package:ball_brain/duel/duel_api.dart';
import 'package:ball_brain/duel/duel_history.dart';
import 'package:ball_brain/duel/duel_screen.dart';
import 'package:ball_brain/l10n/l10n.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> item({String status = 'active', bool incoming = true, bool myDone = false, String? result}) => {
      'id': 'x',
      'mode': 'challenge',
      'status': status,
      'incoming': incoming,
      'opponent': 'Kari',
      'my_score': 0,
      'their_score': 0,
      'my_done': myDone,
      'their_done': false,
      'result': result,
      'expires_ms': DateTime.now().millisecondsSinceEpoch + 3600000 * 20,
    };

void main() {
  test('innkommende utfordring trenger svar, ikke når jeg har spilt eller sendt den selv', () {
    expect(DuelListItem.fromJson(item()).needsMyAnswer, isTrue);
    expect(DuelListItem.fromJson(item(myDone: true)).needsMyAnswer, isFalse);
    expect(DuelListItem.fromJson(item(incoming: false)).needsMyAnswer, isFalse);
    expect(DuelListItem.fromJson(item(status: 'finished', result: 'win')).needsMyAnswer, isFalse);
    expect(DuelListItem.fromJson(item()).timeLeft()!.inHours, inInclusiveRange(19, 20));
  });

  test('sammendraget forstår utfordringer', () {
    final d = DuelSummary.fromJson({
      'id': 'a',
      'status': 'active',
      'total': 10,
      'mode': 'challenge',
      'challenger': false,
      'my_done': false,
      'now_ms': DateTime.now().millisecondsSinceEpoch,
      'starts_ms': null,
      'me': {'name': 'A', 'score': 0, 'answered': 0, 'correct': 0},
      'opp': {'name': 'B', 'score': 0, 'answered': 0, 'correct': 0},
    });
    expect(d.isChallenge, isTrue);
    expect(d.startsMs, isNull);
  });

  test('feilmeldinger for utfordringer finnes', () {
    for (final k in ['self', 'not_shared', 'not_accepting', 'too_many', 'already', 'already_played']) {
      expect(duelError(k), isNot(duelError('offline')), reason: k);
    }
  });

  testWidgets('«Du er utfordret!» har Spill nå, Senere og Avslå', (tester) async {
    String? choice;
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Builder(
        builder: (ctx) => Scaffold(
          body: TextButton(
            onPressed: () async => choice = await showChallengeDialog(ctx, ['Kari', 'Ola']),
            child: const Text('åpne'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('åpne'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Du er utfordret!'), findsOneWidget);
    expect(find.text('Kari, Ola har utfordret deg til 1v1.'), findsOneWidget);
    expect(find.text('Spill nå'), findsOneWidget);
    expect(find.text('Senere'), findsOneWidget);
    await tester.tap(find.text('Avslå'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(choice, 'decline');
  });

  DuelListItem done(String name, String result, int mine, int theirs, int at) =>
      DuelListItem.fromJson({
        ...item(status: 'finished', result: result),
        'id': '$at',
        'opponent': name,
        'opponent_id': 'id-$name',
        'my_score': mine,
        'their_score': theirs,
        'finished_ms': at,
      });

  List<DuelListItem> history() => [
        done('Ola', 'loss', 62, 118, 1),
        done('Kari', 'loss', 97, 131, 2),
        done('Kari', 'win', 140, 84, 4),
        done('Per', 'draw', 100, 100, 3),
      ];

  test('historikken samles per motstander, siste først', () {
    final groups = duelsByOpponent([DuelListItem.fromJson(item()), ...history()]);
    expect(groups.map((g) => g.first.opponent), ['Kari', 'Per', 'Ola']);
    expect(groups.first.map((g) => g.myScore), [140, 97]);
  });

  testWidgets('menykortet viser bare siste motstander, resten ligger i eget vindu', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var items = history();
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Builder(
        builder: (ctx) => Scaffold(
          body: ListView(children: [
            LastOpponentCard(
              items: items,
              onOpenHistory: () => Navigator.of(ctx).push(MaterialPageRoute<void>(
                builder: (_) => DuelHistoryScreen(
                  items: items,
                  onRemove: (g) async => items = items.where((i) => i.id != g.id).toList(),
                  reload: () => items,
                ),
              )),
            ),
          ]),
        ),
      ),
    ));
    expect(find.text('Siste motstander'), findsOneWidget);
    expect(find.text('Kari'), findsOneWidget);
    expect(find.text('Ola'), findsNothing);
    expect(find.text('Siste kamp: 140 – 84'), findsOneWidget);

    await tester.tap(find.text('Se historikken'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Ola'), findsOneWidget);
    expect(find.text('Seier 1 · Uavgjort 0 · Tap 1'), findsOneWidget);
    expect(find.text('97 – 131'), findsOneWidget);

    await tester.tap(find.byTooltip('Fjern').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('140 – 84'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('utfordringstekster med navn oversettes', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await L10n.load('en');
    expect(L10n.tr('Kari har utfordret deg til 1v1.'), 'Kari challenged you to a 1v1.');
    expect(L10n.tr('Venter på Kari'), 'Waiting for Kari');
    expect(L10n.tr('Seier mot Ola'), 'Win against Ola');
    L10n.setData('nb', {});
  });
}

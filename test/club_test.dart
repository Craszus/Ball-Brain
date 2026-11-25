import 'dart:math' as math;

import 'package:ball_brain/club/club_api.dart';
import 'package:ball_brain/club/club_game_screen.dart';
import 'package:ball_brain/club/club_section.dart';
import 'package:ball_brain/models/question.dart';
import 'package:ball_brain/quiz/quiz_controller.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> game({String status = 'accepted', int kickoffIn = -30000, String? winner}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return {
    'id': 'k1',
    'status': status,
    'size': 3,
    'window_min': 5,
    'kickoff_ms': now + kickoffIn,
    'ends_ms': now + kickoffIn + 300000,
    'now_ms': now,
    'winner': winner,
    'home': {'id': 'h', 'name': 'Gjengen', 'color1': 0, 'color2': 1, 'emblem': 1, 'mine': true},
    'away': {'id': 'a', 'name': 'Naboene', 'color1': 2, 'color2': 5, 'emblem': 3, 'mine': false},
    'players': [
      {'name': 'Kari', 'club': 'h', 'score': 24, 'answered': 2, 'me': true},
      {'name': 'Ola', 'club': 'h', 'score': 36, 'answered': 3, 'me': false},
      {'name': 'Per', 'club': 'a', 'score': 15, 'answered': 1, 'me': false},
    ],
  };
}

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  test('potten er summen for hvert lag, og jeg kan spille når kampen pågår', () {
    final g = ClubGame.fromJson(game());
    expect(g.pot('h'), 60);
    expect(g.pot('a'), 15);
    expect(g.canPlay, isTrue);
    expect(ClubGame.fromJson(game(kickoffIn: 60000)).canPlay, isFalse);
  });

  test('dagens utfordring: egen rekkefølge, samme spørsmål og riktig svar følger med', () {
    final qs = [
      for (var i = 0; i < 10; i++)
        Question(
            id: i,
            type: QuestionType.rulesQuiz,
            prompt: 'S$i',
            options: const ['a', 'b', 'c', 'd'],
            correct: 2,
            key: 'k$i')
    ];
    final one = shuffledForPlayer(qs, math.Random(1));
    final two = shuffledForPlayer(qs, math.Random(2));
    expect(one.map((q) => q.key).toSet(), two.map((q) => q.key).toSet());
    expect(one.map((q) => q.key).toList(), isNot(two.map((q) => q.key).toList()));
    for (final q in one) {
      expect(q.options[q.correct as int], 'c');
    }
  });

  testWidgets('kampskjermen viser potten, ledige plasser og «Spill nå»', (tester) async {
    phone(tester);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: ClubGameScreen(gameId: 'k1', load: () async => [ClubGame.fromJson(game())]),
    ));
    await tester.pump();
    expect(find.text('60'), findsOneWidget);
    expect(find.text('15'), findsWidgets);
    expect(find.text('Spill nå'), findsOneWidget);
    expect(find.textContaining('Kampen pågår'), findsOneWidget);
    expect(find.text('Ledig plass'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('spill: svar, se fasit, neste spørsmål og ferdig', (tester) async {
    phone(tester);
    var served = 0;
    final answers = <String?>[];
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: ClubPlayScreen(
        gameId: 'k1',
        next: (_) async => served >= 2
            ? null
            : ClubQuestion(
                idx: served++,
                total: 10,
                prompt: 'Spørsmål $served?',
                options: const ['Ja', 'Nei'],
                remainingMs: 10000),
        answer: (_, idx, a) async {
          answers.add(a);
          return ClubAnswer(a == 'Ja', a == 'Ja' ? 15 : 0, 'Ja');
        },
      ),
    ));
    await tester.pump();
    expect(find.text('Spørsmål 1?'), findsOneWidget);
    await tester.tap(find.text('Ja'));
    await tester.pump();
    expect(find.text('Riktig! +15'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Spørsmål 2?'), findsOneWidget);
    await tester.tap(find.text('Nei'));
    await tester.pump();
    expect(find.text('Riktig svar: Ja'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Ferdig! Du ga laget 15 poeng.'), findsOneWidget);
    expect(answers, ['Ja', 'Nei']);
  });

  testWidgets('klubbdelen viser skjold, resultater og kamper; under 3 medlemmer kan ikke utfordre',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
        body: ListView(children: [
          ClubSection(
            clubId: 'h',
            loadClubs: () async => const [
              ClubInfo(id: 'h', name: 'Gjengen', members: 2, wins: 1, matchCode: 'ABC123')
            ],
            loadGames: () async => [ClubGame.fromJson(game(status: 'finished', winner: 'h'))],
          ),
        ]),
      ),
    ));
    await tester.pump();
    expect(find.text('Seier 1 · Uavgjort 0 · Tap 0'), findsOneWidget);
    expect(find.text('Utfordringskode: ABC123'), findsOneWidget);
    expect(find.text('Vinner: Gjengen'), findsOneWidget);
    expect(find.text('60 – 15'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('utfordringsdialogen har 3 og 5 mot 5, ikke 7, og frist på 3 eller 5 min',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(), home: const Scaffold(body: ChallengeClubDialog(clubId: 'h'))));
    expect(find.text('3 mot 3'), findsOneWidget);
    expect(find.text('5 mot 5'), findsOneWidget);
    expect(find.text('7 mot 7'), findsNothing);
    expect(find.text('3 min'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

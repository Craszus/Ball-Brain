import 'dart:convert';
import 'dart:io';

import 'package:ball_brain/models/question.dart';
import 'package:ball_brain/services/levels.dart';
import 'package:ball_brain/services/profile.dart';
import 'package:ball_brain/services/scoring.dart';
import 'package:ball_brain/services/stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('riktig svar gir +2 og feil svar gir -1', () {
    expect(Scoring.pointsFor(correct: true, difficulty: 3, elapsed: Duration.zero), 2);
    expect(Scoring.pointsFor(correct: false, difficulty: 3, elapsed: Duration.zero), -1);
    expect(signed(2), '+2');
    expect(signed(-1), '\u22121');
  });

  test('statistikk og troféer oppdateres etter en runde', () {
    var s = const Stats();
    expect(trophies.where((t) => t.earned(s)), isEmpty);
    s = s.withResult('rules_quiz', 18);
    expect(s.games, 1);
    expect(s.bestRules, 18);
    expect(s.bestSort, 0);
    final names = trophies.where((t) => t.earned(s)).map((t) => t.title);
    expect(names, containsAll(['Første kamp', 'Regelekspert']));
    s = s.withResult('rules_quiz', 6);
    expect(s.bestRules, 18); // beste beholdes
    expect(s.totalPoints, 24);
    // Full pott gir «perfekt runde» og modus-trofé
    s = s.withResult('geo', 50, perfect: true);
    expect(s.mode('geo').perfects, 1);
    expect(trophies.where((t) => t.earned(s)).map((t) => t.id),
        containsAll(['perfect_any', 'geo_50', 'geo_perfect']));
    // 1v1-troféer er låst til oppgjør er spilt
    expect(trophies.where((t) => t.group == TrophyGroup.pvp && t.earned(s)), isEmpty);
    s = s.withPvp(won: true).withPvp(won: true).withPvp(won: true);
    expect(s.pvpBestStreak, 3);
    expect(trophies.where((t) => t.earned(s)).map((t) => t.id),
        containsAll(['pvp_first', 'pvp_win', 'pvp_streak']));
  });

  test('man faller aldri under nivået man har nådd', () {
    var s = const Stats(totalPoints: 55); // nivå 2 starter på 50
    expect(levelFor(s.totalPoints).level, 2);
    s = s.withResult('rules_quiz', -9); // ville gitt 46 (nivå 1)
    expect(s.totalPoints, 50);
    expect(levelFor(s.totalPoints).level, 2);
    expect(applyPoints(0, -5), 0); // nivå 1: ikke under 0
    expect(applyPoints(200, -5), 195); // fortsatt over starten (120) av nivå 3
    expect(applyPoints(125, -10), 120); // stopper på starten av nivå 3
  });

  test('nivåer følger XP-kurven', () {
    expect(levelFor(0).level, 1);
    expect(levelFor(49).level, 1);
    expect(levelFor(50).level, 2);
    expect(levelFor(50).xpIntoLevel, 0);
    expect(levelFor(120).level, 3);
    final mid = levelFor(25);
    expect(mid.progress, closeTo(0.5, 0.001));
    // Kurven blir stadig brattere, og Legende er siste nivå (poeng kan fortsatt samles)
    for (var l = 3; l < maxLevel; l++) {
      expect(xpAtLevel(l + 1) - xpAtLevel(l), greaterThan(xpAtLevel(l) - xpAtLevel(l - 1)));
    }
    expect(levelFor(14999).level, 9);
    expect(levelFor(15000).level, 10);
    final top = levelFor(10000000);
    expect(top.level, 10);
    expect(top.isMax, isTrue);
    expect(top.xpIntoLevel, 10000000 - 15000);
  });

  test('kallenavn valideres (3–16 tegn)', () {
    expect(Profile.isValidName('Jon'), isTrue);
    expect(Profile.isValidName('Åse_Ø-1.2'), isTrue);
    expect(Profile.isValidName('Jo'), isFalse);
    expect(Profile.isValidName('a' * 17), isFalse);
    expect(Profile.isValidName('har mellomrom'), isFalse);
    expect(Profile.isValidName('<script>'), isFalse);
  });

  test('seed-filen er gyldig', () {
    final all = (jsonDecode(File('assets/seed/questions.json').readAsStringSync())
            as List)
        .cast<Map<String, dynamic>>();
    expect(all.length, greaterThanOrEqualTo(100));
    for (final json in all) {
      final q = Question.fromJson({...json, 'id': 1});
      expect(q.options.length, greaterThanOrEqualTo(2), reason: q.prompt);
      expect(q.options.toSet().length, q.options.length,
          reason: 'duplikate alternativer: ${q.prompt}');
      if (q.type == QuestionType.rulesQuiz) {
        expect(q.correct, isA<int>());
        expect(q.correct as int, inInclusiveRange(0, q.options.length - 1));
      } else {
        final order = (q.correct as List).cast<int>();
        expect(order.toSet().length, q.options.length, reason: q.prompt);
      }
    }
  });

  test('image_sort krever riktig rekkefølge', () {
    const q = Question(
      id: 1,
      type: QuestionType.imageSort,
      prompt: 'Sorter',
      options: ['a', 'b', 'c'],
      correct: [2, 0, 1],
    );
    expect(q.isCorrect([2, 0, 1]), isTrue);
    expect(q.isCorrect([0, 1, 2]), isFalse);
  });
}

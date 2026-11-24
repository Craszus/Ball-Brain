import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:ball_brain/models/question.dart';
import 'package:ball_brain/quiz/quiz_controller.dart';
import 'package:ball_brain/services/seen_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Temaene som finnes i valgmenyen til regler-quizen (lib/home_screen.dart).
const categories = {
  'Regler', 'VM-historie', 'EM-historie', 'Klubbfotball', 'Ligaer', 'Spillere og rekorder',
  'Trenere', 'Stadioner', 'Norge', 'Visste du at?',
};

List<Map<String, dynamic>> _json(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as List).cast<Map<String, dynamic>>();

void main() {
  group('spørsmålene', () {
    final all = _json('assets/seed/questions.json');
    final quiz = all.where((q) => q['type'] == 'rules_quiz').toList();
    final sort = all.where((q) => q['type'] == 'image_sort').toList();

    test('det er nok spørsmål, og alle temaer er godt dekket', () {
      expect(quiz.length, greaterThanOrEqualTo(400));
      expect(sort.length, greaterThanOrEqualTo(25));
      for (final c in categories) {
        expect(quiz.where((q) => q['era'] == c).length, greaterThanOrEqualTo(20), reason: c);
      }
      expect(all.map((q) => q['era']).toSet().difference(categories), isEmpty);
      // Variert vanskelighetsgrad
      final levels = quiz.map((q) => q['difficulty']).toSet();
      expect(levels, containsAll([1, 2, 3, 4, 5]));
    });

    test('hvert spørsmål er gyldig og unikt', () {
      final keys = <String>{};
      final prompts = <String>{};
      for (final j in all) {
        final q = Question.fromJson({...j, 'id': 1});
        expect(q.key, isNotNull, reason: q.prompt);
        expect(keys.add(q.key!), isTrue, reason: 'duplikat: ${q.prompt}');
        expect(q.options.toSet().length, q.options.length, reason: q.prompt);
        expect(q.difficulty, inInclusiveRange(1, 5), reason: q.prompt);
        if (q.type == QuestionType.rulesQuiz) {
          expect(q.options.length, inInclusiveRange(2, 4), reason: q.prompt);
          expect(q.correct, isA<int>());
          expect(q.correct as int, inInclusiveRange(0, q.options.length - 1));
          expect(prompts.add(q.prompt), isTrue, reason: 'samme spørsmål to ganger: ${q.prompt}');
        } else {
          final order = (q.correct as List).cast<int>();
          expect([...order]..sort(), List.generate(q.options.length, (i) => i),
              reason: q.prompt);
        }
      }
    });

    test('stokking av svaralternativer beholder riktig svar', () {
      final rng = math.Random(7);
      for (final j in quiz) {
        final q = Question.fromJson({...j, 'id': 1});
        final s = q.withShuffledOptions(rng);
        expect(s.options[s.correct as int], q.options[q.correct as int]);
        expect(s.options.toSet(), q.options.toSet());
        expect(s.uid, q.uid);
      }
      const yesNo = Question(
          id: 1, type: QuestionType.rulesQuiz, prompt: 'p', options: ['Ja', 'Nei'], correct: 1);
      expect(yesNo.withShuffledOptions(rng).options, ['Ja', 'Nei']);
    });

    test('dagens utfordring er lik hele dagen, ny neste dag, og blander temaer', () {
      final qs = [for (final j in quiz) Question.fromJson({...j, 'id': 1})];
      final a = dailyQuestions(qs, DateTime(2026, 11, 24, 8));
      final b = dailyQuestions([...qs.reversed], DateTime(2026, 11, 24, 22));
      final c = dailyQuestions(qs, DateTime(2026, 11, 25));
      expect(a.length, quizLength);
      expect(a.map((q) => q.uid).toList(), b.map((q) => q.uid).toList());
      expect(a.map((q) => q.options).toList(), b.map((q) => q.options).toList());
      expect(a.map((q) => q.uid).toSet().intersection(c.map((q) => q.uid).toSet()).length,
          lessThan(quizLength));
      expect(a.map((q) => q.era).toSet().length, greaterThanOrEqualTo(8));
      // lettest først
      for (var i = 1; i < a.length; i++) {
        expect(a[i].difficulty, greaterThanOrEqualTo(a[i - 1].difficulty));
      }
    });
  });

  group('mindre repetisjon', () {
    test('ingen gjentakelser før hele puljen er brukt, deretter ny runde', () {
      final pool = List.generate(25, (i) => 'q$i');
      final rng = math.Random(1);
      var seen = <String>{};
      final shown = <String>[];
      for (var round = 0; round < 2; round++) {
        final r = pickFresh(pool, 10, (s) => s, seen, rng);
        expect(r.picked.toSet().length, 10);
        shown.addAll(r.picked);
        seen = r.seen;
      }
      expect(shown.toSet().length, 20); // 20 ulike på to runder
      // Tredje runde: de 5 siste uviste kommer først, så starter en ny runde
      final r3 = pickFresh(pool, 10, (s) => s, seen, rng);
      expect(r3.picked.toSet().length, 10);
      final unseen = pool.where((p) => !shown.contains(p)).toSet();
      expect(r3.picked.toSet().containsAll(unseen), isTrue);
      expect(r3.seen, r3.picked.toSet()); // listen nullstilt og startet på nytt
    });

    test('spredning gir flere temaer i samme runde', () {
      final pool = [
        for (var i = 0; i < 30; i++) 'A$i',
        for (var i = 0; i < 5; i++) 'B$i',
        for (var i = 0; i < 5; i++) 'C$i',
      ];
      final r = pickFresh(pool, 9, (s) => s, {}, math.Random(3), spread: (s) => s[0]);
      expect(r.picked.where((s) => s.startsWith('B')).length, 3);
      expect(r.picked.where((s) => s.startsWith('C')).length, 3);
    });

    test('lettest først i en runde', () {
      Question q(int d) =>
          Question(id: d, type: QuestionType.rulesQuiz, prompt: '$d', options: const ['a', 'b'], correct: 0, difficulty: d);
      expect(easyToHard([q(3), q(1), q(5), q(2)]).map((e) => e.difficulty), [1, 2, 3, 5]);
    });

    test('SeenHistory husker mellom rundene (shared_preferences)', () async {
      SharedPreferences.setMockInitialValues({});
      final h = SeenHistory(rng: math.Random(5));
      final pool = List.generate(12, (i) => i);
      final first = await h.pick('test', pool, 6, (i) => '$i');
      final second = await h.pick('test', pool, 6, (i) => '$i');
      expect({...first, ...second}.length, 12);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('seen.test')!.length, 12);
    });
  });

  group('bildene', () {
    final allowed = RegExp(r'^(CC BY(-SA)?[ -]\d(\.\d)?(\s.*)?|CC0.*|Public domain.*|PDM.*|Attribution.*)$', caseSensitive: false);
    final denied = RegExp(r'(NC|ND|GFDL|fair use|non-?commercial)', caseSensitive: false);

    void checkPhotos(List<Map<String, dynamic>> list) {
      final ids = <String>{};
      for (final j in list) {
        final id = j['id'] as String;
        expect(ids.add(id), isTrue, reason: 'dobbel id $id');
        final p = j['photo'] as Map<String, dynamic>;
        final lic = p['license'] as String;
        expect(allowed.hasMatch(lic), isTrue, reason: '$id: $lic');
        expect(denied.hasMatch(lic), isFalse, reason: '$id: $lic');
        expect((p['author'] as String).trim(), isNotEmpty, reason: id);
        expect(p['pageUrl'] as String, startsWith('https://commons.wikimedia.org/'), reason: id);
        expect((p['title'] as String).toLowerCase(), isNot(contains('logo')), reason: id);
        final file = j['file'] as String?;
        expect(file, isNotNull, reason: '$id mangler bilde i appen');
        expect(File(file!).existsSync(), isTrue, reason: file);
      }
    }

    test('spillere: mange, mange målvakter, lisens og fil i orden', () {
      final players = _json('assets/media/players.json');
      expect(players.length, greaterThanOrEqualTo(150));
      expect(players.where((p) => p['pos'] == 'GK').length, greaterThanOrEqualTo(40));
      checkPhotos(players);
      for (final p in players) {
        expect(p['nationality'] as String, isNotEmpty, reason: p['id'] as String);
      }
    });

    test('stadioner: minst 100, lisens, fil og koordinater i orden', () {
      final stadiums = _json('assets/media/stadiums.json');
      expect(stadiums.length, greaterThanOrEqualTo(100));
      checkPhotos(stadiums);
      for (final s in stadiums) {
        expect((s['lat'] as num).abs(), lessThanOrEqualTo(90));
        expect((s['lon'] as num).abs(), lessThanOrEqualTo(180));
        expect(s['club'] as String, isNotEmpty);
        expect(s['country'] as String, isNotEmpty);
      }
    });
  });
}

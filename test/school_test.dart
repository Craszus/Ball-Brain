import 'dart:convert';
import 'dart:io';

import 'package:ball_brain/l10n/l10n.dart' show L10n, TrString;
import 'package:ball_brain/school/lesson_hint.dart';
import 'package:ball_brain/school/lessons.dart';
import 'package:ball_brain/school/school_progress.dart';
import 'package:ball_brain/school/pitch_view.dart';
import 'package:ball_brain/school/school_screen.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Offsideposisjon regnet ut fra plasseringene.
bool inOffsidePosition(Situation s, Player a) {
  final defenders = [for (final p in s.players) if (p.side != Side.blue) p.x]
    ..sort((x, y) => y.compareTo(x));
  return a.x > 52.5 && a.x > s.ball!.dx && a.x > defenders[1];
}

void main() {
  test('alle oppgavene har en gyldig fasit', () {
    expect(lessons.map((l) => l.id).toSet().length, lessons.length);
    for (final l in lessons) {
      for (final s in l.situations) {
        switch (s.task) {
          case Choose(:final options, :final correct):
            expect(correct, inInclusiveRange(0, options.length - 1), reason: s.prompt);
            expect(options.toSet().length, options.length, reason: s.prompt);
          case TapPlayer(:final correct):
            expect(correct, inInclusiveRange(0, s.players.length - 1), reason: s.prompt);
          case PlaceSpot(:final spots):
            expect(markIsRight(s.task, spots.first), isTrue, reason: s.prompt);
          case PlaceLine(:final x):
            expect(markIsRight(s.task, Offset(x, 10)), isTrue, reason: s.prompt);
          case PlaceArea(:final areas):
            expect(areas, isNotEmpty);
        }
        // spillere og ball skal være synlige i utsnittet
        final points = [for (final p in s.players) p.at, ?s.ball];
        for (final p in points) {
          expect(p.dx, greaterThanOrEqualTo(PitchMap.minX(s.from)), reason: s.prompt);
          expect(p.dx, lessThanOrEqualTo(PitchMap.maxX), reason: s.prompt);
        }
      }
    }
  });

  test('hver oppgave har sin egen tekst (brukes til å huske bom)', () {
    final prompts = [for (final l in lessons) for (final s in l.situations) s.prompt];
    expect(prompts.toSet().length, prompts.length);
    expect(lessons.length, 11);
  });

  test('«Dagens tre» tar bom først og ellers fra leksjoner man har tatt', () {
    expect(dailyThree(const SchoolProgress(), 1), isEmpty);
    final miss = lessons[2].situations.last.prompt;
    final three = dailyThree(SchoolProgress(done: const {'pitch'}, missed: {miss}), 5);
    expect(three.length, 3);
    expect(three.first.prompt, miss);
    final pitch = lessons.first.situations.map((s) => s.prompt).toSet();
    expect(pitch.containsAll(three.skip(1).map((s) => s.prompt)), isTrue);
  });

  test('regelspørsmål peker til riktig leksjon', () {
    expect(lessonFor('Kan man være offside på innkast?'), 'offside');
    expect(lessonFor('Hvilke situasjoner kan VAR gripe inn i?'), 'var');
    expect(lessonFor('Hva kreves av keeperen ved et straffespark?'), 'keeper');
    expect(lessonFor('Hva er straffen for et farlig spill? Indirekte frispark?'), 'fouls');
    expect(lessonFor('Hvem var den første dommeren?'), isNull);
    for (final id in ['var', 'offside', 'hands', 'keeper', 'fouls', 'out', 'pitch']) {
      expect(lessons.any((l) => l.id == id), isTrue, reason: id);
    }
  });

  test('offsidesituasjonene stemmer med plasseringene', () {
    final s = lessons.firstWhere((l) => l.id == 'offside').situations;
    Player nine(int i) => s[i].players.firstWhere((p) => p.label == '9');
    // bare nummer 9 i første oppgave
    expect([for (final p in s[0].players) if (p.side == Side.blue && inOffsidePosition(s[0], p)) p.label],
        ['9']);
    expect(s[0].players[(s[0].task as TapPlayer).correct].label, '9');
    expect(inOffsidePosition(s[1], nine(1)), isFalse); // på linje
    expect(nine(2).x, lessThan(52.5)); // egen halvdel
    expect(inOffsidePosition(s[3], nine(3)), isFalse); // bak ballen
    expect((s[4].task as PlaceLine).x, 89);
    for (final i in [4, 5, 6, 7]) {
      expect(inOffsidePosition(s[i], nine(i)), isTrue, reason: s[i].prompt);
    }
  });

  test('områder og punkter godtar riktig merke og avviser feil', () {
    final pitch = lessons.first.situations;
    expect(markIsRight(pitch[0].task, const Offset(93, 35)), isTrue);
    expect(markIsRight(pitch[0].task, const Offset(80, 34)), isFalse);
    expect(markIsRight(pitch[3].task, const Offset(92, 20)), isTrue);
    expect(markIsRight(pitch[3].task, const Offset(102, 34)), isFalse); // i målfeltet
  });

  test('skjerm og meter regnes riktig begge veier', () {
    final map = PitchMap(48, const Size(380, 300));
    const m = Offset(80, 20);
    expect((map.toMetres(map.toScreen(m)) - m).distance, lessThan(0.001));
  });

  test('leksjonstekstene er oversatt til alle språk', () {
    // tall og personnavn skrives likt overalt
    const same = {'VAR', 'Andrés Iniesta', 'Xavi', 'David Villa', 'Arjen Robben'};
    final texts = <String>{
      for (final l in lessons) ...[l.title, l.subtitle, l.fact],
      for (final l in lessons)
        for (final s in l.situations) ...[
          s.prompt,
          s.explain,
          ?s.tipTitle,
          ?s.tip,
          if (s.task case Choose(:final options)) ...options,
        ],
    }..removeWhere((t) => same.contains(t) || !t.contains(RegExp('[A-Za-zÆØÅæøå]')));
    for (final lang in ['en', 'sv', 'da', 'de', 'es', 'fr']) {
      final map = jsonDecode(File('assets/i18n/$lang.json').readAsStringSync()) as Map;
      expect([for (final t in texts) if (!map.containsKey(t)) t], isEmpty, reason: lang);
    }
  });

  for (final (size, lang) in const [
    (Size(360, 592), 'nb'),
    (Size(400, 860), 'nb'),
    (Size(360, 592), 'de'),
    (Size(360, 592), 'fr'),
  ]) {
    testWidgets('alle leksjonene kan spilles på ${size.width.toInt()} × ${size.height.toInt()} ($lang)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      if (lang != 'nb') {
        L10n.setData(lang,
            (jsonDecode(File('assets/i18n/$lang.json').readAsStringSync()) as Map).cast<String, String>());
        addTearDown(() => L10n.setData('nb', {}));
      }
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final lesson in lessons) {
        await tester.pumpWidget(ProviderScope(
            key: ValueKey(lesson.id),
            child: MaterialApp(theme: buildTheme(), home: LessonScreen(lesson: lesson))));
        await tester.pumpAndSettle();
        for (final s in lesson.situations) {
          Future<void> tapAt(Offset metres) async {
            final map = PitchMap(s.from, tester.getSize(find.byType(CustomPaint).last));
            await tester.tapAt(tester.getTopLeft(find.byType(CustomPaint).last) + map.toScreen(metres));
            await tester.pumpAndSettle();
          }

          switch (s.task) {
            case Choose(:final options, :final correct):
              await tester.tap(find.text(options[correct].tr));
            case TapPlayer(:final correct):
              await tapAt(s.players[correct].at);
            case PlaceSpot(:final spots):
              await tapAt(spots.first == const Offset(105, 0) ? const Offset(104, 1) : spots.first);
              await tester.tap(find.text('Bekreft merket'.tr));
            case PlaceLine(:final x):
              await tapAt(Offset(x, 10));
              await tester.tap(find.text('Bekreft merket'.tr));
            case PlaceArea(:final areas, :final except):
              final a = areas.first;
              await tapAt(except == null ? a.center : Offset(a.left + 2, a.center.dy));
              await tester.tap(find.text('Bekreft merket'.tr));
          }
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: s.prompt);
          expect(find.text('Riktig!'.tr), findsOneWidget, reason: s.prompt);
          await tester.tap(find.text('Neste'.tr));
          await tester.pumpAndSettle();
        }
        expect(find.text('Leksjonen er fullført!'.tr), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      final done = (await SharedPreferences.getInstance()).getStringList('school.perfect');
      expect(done, containsAll([for (final l in lessons) l.id]));
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('feil svar gir forklaring og lar deg prøve igjen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
            theme: buildTheme(), home: LessonScreen(lesson: lessons.firstWhere((l) => l.id == 'out')))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ja'));
    await tester.pumpAndSettle();
    expect(find.text('Ikke helt.'), findsOneWidget);
    await tester.tap(find.text('Prøv igjen'));
    await tester.pumpAndSettle();
    expect(find.text('Ja'), findsOneWidget);
  });
}

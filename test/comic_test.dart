import 'dart:io';

import 'package:ball_brain/school/comic_screen.dart';
import 'package:ball_brain/school/lessons.dart';
import 'package:ball_brain/ui/credited_photo.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('alle rutene har bildefil, og boblene har taler og plass', () {
    for (final c in allComics) {
      expect(c.panels, hasLength(4), reason: c.header);
      for (final p in c.panels) {
        expect(File(p.image).existsSync(), isTrue, reason: p.image);
        if (p.bubble != null) {
          expect(p.bubbleBox, isNotNull);
          expect(p.tail, isNotNull);
        }
        if (p.sound != null) expect(p.soundAt, isNotNull);
      }
    }
  });

  test('hvert historiske øyeblikk har sin egen tegneserie', () {
    final history = lessons.firstWhere((l) => l.id == 'history');
    expect(history.situations.map((s) => s.comic), orderedEquals(allComics));
  });

  test('spillerne i tegneseriene finnes med ekte bilde', () {
    final players = File('assets/media/players.json').readAsStringSync();
    for (final c in allComics) {
      if (c.player != null) expect(players, contains(c.player!), reason: c.header);
    }
  });

  testWidgets('hver tegneserie får plass på en liten skjerm', (tester) async {
    tester.view.physicalSize = const Size(360, 592);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final c in allComics) {
      await tester.pumpWidget(
          MaterialApp(key: ValueKey(c.header), theme: buildTheme(), home: ComicScreen(comic: c)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: c.header);
      for (final p in c.panels) {
        expect(tester.getRect(find.text(p.caption!)).bottom, lessThan(592), reason: p.image);
      }
      expect(find.text('Se den virkelige spilleren'),
          c.player == null ? findsNothing : findsOneWidget);
    }
  });

  testWidgets('alle rutene vises på én side på en liten skjerm', (tester) async {
    tester.view.physicalSize = const Size(360, 592);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: buildTheme(), home: const ComicScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ComicPicture), findsNWidgets(maradona86.panels.length));
    for (final p in maradona86.panels) {
      expect(tester.getRect(find.text(p.caption!)).bottom, lessThan(592));
    }
    // det ekte bildet åpnes i et vindu med kreditering
    await tester.ensureVisible(find.text('Se den virkelige spilleren'));
    await tester.tap(find.text('Se den virkelige spilleren'));
    for (var i = 0; i < 10 && find.text('Diego Maradona').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(find.text('Diego Maradona'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    // hele det kvadratiske bildet vises, uten at sidene kuttes
    final photo = tester.getSize(find.byType(CreditedPhoto));
    expect(photo.width, closeTo(photo.height, 1));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Lukk'));
    await tester.pumpAndSettle();
    // trykk på en rute: den vises stor, og man kan bla videre
    await tester.tap(find.byType(ComicPicture).at(2));
    await tester.pumpAndSettle();
    expect(find.byType(ComicViewer), findsOneWidget);
    await tester.tap(find.text('Trykk for neste rute'));
    await tester.pumpAndSettle();
    expect(find.text('Se igjen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

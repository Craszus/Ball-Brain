import 'package:ball_brain/avatar_picker_screen.dart';
import 'package:ball_brain/home_screen.dart';
import 'package:ball_brain/services/profile.dart';
import 'package:ball_brain/ui/avatar_carousel.dart';
import 'package:ball_brain/ui/gold_button.dart';
import 'package:ball_brain/ui/level_card.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('de seks avatarene er ulike (hudfarge, hår eller draktfarge)', () {
    expect(presetAvatars.length, 6);
    for (var i = 0; i < presetAvatars.length; i++) {
      for (var j = i + 1; j < presetAvatars.length; j++) {
        expect(presetAvatars[i].sameLook(presetAvatars[j]), isFalse);
        expect(presetAvatars[i].kit == presetAvatars[j].kit, isFalse,
            reason: 'samme drakt på $i og $j');
      }
    }
    expect(presetAvatars.map((a) => a.skin).toSet().length, greaterThanOrEqualTo(4));
    expect(presetAvatars.map((a) => a.hairStyle).toSet().length, greaterThanOrEqualTo(4));
  });

  testWidgets('Velg din avatar: velg, skriv navn og bekreft', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: buildTheme(),
        home: const AvatarPickerScreen(onboarding: true),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Velg din avatar'), findsOneWidget);
    expect(find.text('Velg en avatar for å fortsette'), findsOneWidget);
    expect(find.text('Spillernavn'), findsOneWidget);
    expect(find.byType(LevelCard), findsOneWidget);
    expect(find.byType(AvatarCarousel), findsOneWidget); // karusell med 45 avatarer
    expect(find.text('Alle'), findsOneWidget);
    expect(find.text('Barn'), findsOneWidget);
    expect(tester.takeException(), isNull); // ingen overflow på 375 bredde

    // Uten navn er «Bekreft» deaktivert
    GoldButton confirm() => tester.widget<GoldButton>(find.byType(GoldButton));
    expect(confirm().onPressed, isNull);

    // Barn-filteret hopper til første barneavatar (nr. 33)
    await tester.tap(find.text('Barn'));
    await tester.pump(const Duration(milliseconds: 400));

    // Ugyldig navn deaktiverer igjen
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.pump();
    expect(confirm().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Jon');
    await tester.pump();
    expect(confirm().onPressed, isNotNull);

    await tester.tap(find.text('Bekreft'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // Videre til hovedmenyen, og profilen er lagret
    expect(find.byType(HomeScreen), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
    final profile = container.read(profileProvider);
    expect(profile.name, 'Jon');
    expect(profile.avatar.art, 'assets/avatars/avatar_33.png');

    await tester.pumpWidget(const SizedBox());
  });
}

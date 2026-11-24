import 'package:ball_brain/avatar_picker_screen.dart';
import 'package:ball_brain/settings_screen.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(375, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
      child: MaterialApp(theme: buildTheme(), home: home)));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('Innstillinger: personvern og vilkår åpnes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(tester, const SettingsScreen());
    await tester.tap(find.text('Personvern'));
    await tester.pumpAndSettle();
    expect(find.text('Hva vi lagrer'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vilkår'));
    await tester.pumpAndSettle();
    expect(find.text('Bruk av appen'), findsOneWidget);
  });

  testWidgets('Slett all min data tømmer lagring og starter onboarding',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'profile.onboarded': true,
      'profile.name': 'Jon',
      'settings.sound': false,
    });
    await _pump(tester, const SettingsScreen());
    await tester.scrollUntilVisible(find.text('Slett all min data'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Slett all min data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Slett alt'));
    await tester.pumpAndSettle();
    expect(find.byType(AvatarPickerScreen), findsOneWidget);
    final p = await SharedPreferences.getInstance();
    expect(p.getKeys(), isEmpty);
  });

  testWidgets('Onboarding viser lenker til vilkår og personvern',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(tester, const AvatarPickerScreen(onboarding: true));
    expect(find.text('vilkårene'), findsOneWidget);
    expect(find.text('personvern'), findsOneWidget);
  });
}

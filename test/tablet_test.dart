import 'package:ball_brain/home_screen.dart';
import 'package:ball_brain/ui/tablet.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('mobiler skaleres ikke, nettbrett gjør det', () {
    expect(tabletScale(const Size(360, 640)), 1);
    expect(tabletScale(const Size(430, 930)), 1);
    expect(tabletScale(const Size(930, 430)), 1);
    expect(tabletScale(const Size(600, 960)), closeTo(1.07, 0.01));
    expect(tabletScale(const Size(800, 1280)), closeTo(1.43, 0.01));
    expect(tabletScale(const Size(1366, 1024)), 1.5);
  });

  for (final size in const [Size(600, 960), Size(800, 1280), Size(960, 600), Size(1280, 800)]) {
    testWidgets('forsiden får plass på nettbrett ${size.width.toInt()} × ${size.height.toInt()}',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(theme: buildTheme(), builder: tabletBuilder, home: const HomeScreen()),
      ));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      // nederste spillknapp vises uten rulling
      expect(tester.getRect(find.text('Kamper')).bottom, lessThan(size.height));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }
}

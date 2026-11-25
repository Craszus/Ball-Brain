import 'package:ball_brain/daily_board_screen.dart';
import 'package:ball_brain/services/daily.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const row = DailyRow(
      rank: 1, username: 'Kari', country: 'NO', correct: 9, ms: 72400, days: 3, isMe: false);

  test('tiden vises som minutter og sekunder', () => expect(row.time, '1:12'));

  testWidgets('rangeringen viser dag og uke og henter på nytt ved bytte', (tester) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final calls = <String>[];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: buildTheme(),
        home: DailyBoardScreen(load: (period, scope) async {
          calls.add('$period/$scope');
          return [row];
        }),
      ),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.text('9/10'), findsOneWidget);
    expect(find.text('Tid: 1:12'), findsOneWidget);
    await tester.tap(find.text('Uka'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Venner'));
    await tester.pump();
    await tester.pump();
    expect(calls, ['day/world', 'week/world', 'week/friends']);
    expect(find.text('9 riktige'), findsOneWidget);
    expect(find.text('Dager: 3 · 1:12'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

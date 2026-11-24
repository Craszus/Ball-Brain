import 'package:ball_brain/profile_screen.dart';
import 'package:ball_brain/services/levels.dart';
import 'package:ball_brain/services/stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStats extends StatsController {
  _FakeStats(this.total);
  final int total;

  @override
  Stats build() => Stats(totalPoints: total, games: 1);
}

Widget _panel(int totalAfter, int score) => ProviderScope(
      overrides: [statsProvider.overrideWith(() => _FakeStats(totalAfter))],
      child: MaterialApp(
        home: Scaffold(
          body: ResultPanel(score: score, note: 'test', onAgain: () {}),
        ),
      ),
    );

void main() {
  test('leveledUp ser nivåskiftet', () {
    expect(leveledUp(48, 52), isTrue);
    expect(leveledUp(5, 15), isFalse);
    expect(leveledUp(115, 125), isTrue);
  });

  testWidgets('feiringen vises når runden gir nytt nivå', (tester) async {
    await tester.pumpWidget(_panel(52, 6)); // 46 -> 52 passerer 50
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('NIVÅ OPP!'), findsOneWidget);
    expect(find.text('Du er nå nivå 2'), findsOneWidget);

    await tester.tap(find.text('Fortsett'));
    await tester.pump();
    expect(find.text('NIVÅ OPP!'), findsNothing);
    await tester.pumpWidget(const SizedBox()); // rydder animasjoner
  });

  testWidgets('ingen feiring uten nytt nivå', (tester) async {
    await tester.pumpWidget(_panel(15, 6)); // 9 -> 15, fortsatt nivå 1
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('NIVÅ OPP!'), findsNothing);
    expect(find.text('FULLTID!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

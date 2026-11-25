import 'package:ball_brain/services/cloud.dart';
import 'package:ball_brain/ui/ranking_card.dart';
import 'package:ball_brain/ui/theme.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('viser plassen i landet og i verden, eller strek når jeg ikke er på listen',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
        body: RankingCard(
          country: 'NO',
          load: ({String? country}) async => country == null
              ? const LeaderboardData([], null)
              : const LeaderboardData(
                  [],
                  LeaderboardRow(
                      rank: 3, username: 'Meg', country: 'NO', total: 40, isMe: true)),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('Nr. 3'), findsOneWidget);
    expect(find.text('–'), findsOneWidget);
    expect(find.text('Se rangeringen'), findsOneWidget);
    expect(find.text('Dagens rangering'), findsOneWidget);
  });
}

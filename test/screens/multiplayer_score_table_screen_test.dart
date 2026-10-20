import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/screens/multiplayer_score_table_screen.dart';
import '../support/session_fixtures.dart';

void main() {
  for (final myUid in ['uid1', 'uid2']) {
    testWidgets('the crown marks the winner when viewing as $myUid', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiplayerScoreTableScreen(
            session: MultiplayerSessionData.fromJson(archiveDocument()),
            myUid: myUid,
            options: const UIOptions(),
          ),
        ),
      );

      final winnerRow = find
          .ancestor(of: find.text('Player'), matching: find.byType(Row))
          .first;
      final otherRow = find
          .ancestor(of: find.text('Other'), matching: find.byType(Row))
          .first;
      expect(
        find.descendant(of: winnerRow, matching: find.text('👑')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: otherRow, matching: find.text('👑')),
        findsNothing,
      );
      expect(find.text('👑'), findsOneWidget);
    });
  }
}

/*
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:triviaapp/models/session_data.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';
import 'package:triviaapp/services/singleplayer_score_table_service.dart';

class MockFirebaseSessionRepository extends Mock implements FirebaseSessionRepository {}
class FakeSessionData extends Fake implements SessionData {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSessionData());
  });

  test('ScoreTableService pobiera dane sesji do tabeli wyników', () async {
    final repo = MockFirebaseSessionRepository();
    final service = ScoreTableService(repo);
    final session = FakeSessionData();

    when(() => repo.getGameData('session-1')).thenAnswer((_) async => session);

    final result = await service.getGameData('session-1');

    expect(result, same(session));
  });
}
*/
void main() {}
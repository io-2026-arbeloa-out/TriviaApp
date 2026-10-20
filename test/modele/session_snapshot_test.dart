import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/session_snapshot.dart';
import 'package:triviaapp/models/session_status.dart';
import '../support/session_fixtures.dart';

void main() {
  test(
    'preserves server status, round phase, settings and ordered string IDs',
    () {
      final data = sessionDocument(
        phase: 'resolving',
        ids: ['01', '1', 'question-alpha'],
      );
      final session = SessionSnapshot.fromJson('room', data);
      expect(session.status, SessionStatus.inProgress);
      expect(session.phase, RoundPhase.resolving);
      expect(session.questionIds, ['01', '1', 'question-alpha']);
      expect(session.playerNames, ['Player', 'Other']);
      expect(session.options!.questionTimeLimit, 30);
      expect(session.lastRoundResult!.eliminatedUid, 'uid2');
      expect(() => session.questionIds.clear(), throwsUnsupportedError);
    },
  );
  for (final field in [
    'status',
    'phase',
    'categoryId',
    'questionIds',
    'currentQuestionIndex',
    'players',
    'playerUids',
    'maxPlayers',
    'questionTimeLimit',
    'difficulty',
  ]) {
    test('rejects missing session field $field', () {
      expect(
        () =>
            SessionSnapshot.fromJson('room', sessionDocument()..remove(field)),
        throwsFormatException,
      );
    });
  }
  for (final entry in {
    'status': 'answering',
    'phase': 'inProgress',
    'categoryId': '',
    'questionIds': ['1', '1'],
    'currentQuestionIndex': -1,
    'players': [],
    'playerUids': ['unknown'],
    'maxPlayers': 11,
    'questionTimeLimit': 17,
    'difficulty': 'unknown',
    'resultsReady': 'yes',
  }.entries) {
    test('rejects invalid session field ${entry.key}', () {
      expect(
        () => SessionSnapshot.fromJson(
          'room',
          sessionDocument()..[entry.key] = entry.value,
        ),
        throwsFormatException,
      );
    });
  }
  test(
    'waiting can have no pool while an active session requires a valid position',
    () {
      expect(
        SessionSnapshot.fromJson(
          'room',
          sessionDocument(status: 'waiting', ids: []),
        ).questionIds,
        isEmpty,
      );
      expect(
        () => SessionSnapshot.fromJson('room', sessionDocument(ids: [])),
        throwsFormatException,
      );
      expect(
        () => SessionSnapshot.fromJson('room', sessionDocument(index: 3)),
        throwsFormatException,
      );
    },
  );
  test('a resolving session requires its complete round result', () {
    expect(
      () => SessionSnapshot.fromJson(
        'room',
        sessionDocument(phase: 'resolving')..['lastRoundResult'] = null,
      ),
      throwsFormatException,
    );
    final data = sessionDocument(phase: 'resolving');
    (data['lastRoundResult'] as Map)['lotteryPool'] = {'uid1': 'bad'};
    expect(() => SessionSnapshot.fromJson('room', data), throwsFormatException);
  });
  test('rejects unknown player types and inconsistent phase/status', () {
    final data = sessionDocument();
    (data['players']['uid1'] as Map)['isEliminated'] = 'yes';
    expect(() => SessionSnapshot.fromJson('room', data), throwsFormatException);
    expect(
      () =>
          SessionSnapshot.fromJson('room', sessionDocument(status: 'finished')),
      throwsFormatException,
    );
  });
  test('archive resumes a finished game without inventing lobby settings', () {
    final session = SessionSnapshot.fromArchive('room', archiveDocument());
    expect(session.status, SessionStatus.finished);
    expect(session.resultsReady, true);
    expect(session.phase, RoundPhase.finished);
    expect(session.options, isNull);
    expect(session.players.first.profilePicture, 'avatar.png');
    expect(session.forPlayer('uid1').myState!.username, 'Player');
    expect(
      () => SessionSnapshot.fromArchive(
        'room',
        archiveDocument()..['statsApplied'] = false,
      ),
      throwsStateError,
    );
  });
}

import 'package:triviaapp/models/session_snapshot.dart';

Map<String, dynamic> sessionDocument({
  String status = 'inProgress',
  String phase = 'answering',
  int index = 0,
  bool ready = false,
  List<String> ids = const ['0', '1', '2'],
}) => {
  'status': status,
  'phase': phase,
  'categoryId': 'general',
  'questionIds': ids,
  'currentQuestionIndex': index,
  'resultsReady': ready,
  'maxPlayers': 2,
  'questionTimeLimit': 30,
  'difficulty': 'medium',
  'entryCode': null,
  'playerUids': ['uid1', 'uid2'],
  'players': {
    'uid1': {
      'username': 'Player',
      'profilePicture': 'avatar.png',
      'isEliminated': false,
      'lotteryTickets': 0,
    },
    'uid2': {'username': 'Other', 'isEliminated': false, 'lotteryTickets': 1},
  },
  'lastRoundResult': phase == 'resolving'
      ? {
          'eliminatedUid': 'uid2',
          'eliminatedUsername': 'Other',
          'lotteryOccurred': false,
          'lotteryPool': <String, int>{},
          'opponentLeft': false,
        }
      : null,
};

SessionSnapshot sessionSnapshot({
  String status = 'inProgress',
  String phase = 'answering',
  int index = 0,
  bool ready = false,
  List<String> ids = const ['0', '1', '2'],
}) => SessionSnapshot.fromJson(
  'room',
  sessionDocument(
    status: status,
    phase: phase,
    index: index,
    ready: ready,
    ids: ids,
  ),
);

Map<String, dynamic> archiveDocument() => {
  'sessionId': 'room',
  'categoryId': 'general',
  'questionIds': ['0', '1', '2'],
  'gameMode': 'casual',
  'statsApplied': true,
  'participantUids': ['uid1', 'uid2'],
  'sessionStartTime': '2026-10-20T10:00:00Z',
  'gameStartTime': '2026-10-20T10:00:00Z',
  'endTime': '2026-10-20T10:01:00Z',
  'playerResults': [
    for (final uid in ['uid1', 'uid2'])
      {
        'uid': uid,
        'username': uid == 'uid1' ? 'Player' : 'Other',
        'profilePicture': 'avatar.png',
        'placement': uid == 'uid1' ? 1 : 2,
        'correctAnswers': 1,
        'totalAnswers': 1,
        'lotteryTimesIn': 0,
      },
  ],
  'rounds': [
    {
      'roundIndex': 0,
      'questionId': '0',
      'playerAnswers': {'uid1': 'A', 'uid2': 'B'},
      'isCorrect': {'uid1': true, 'uid2': false},
      'lotteryOccurred': false,
      'lotteryPool': {},
      'eliminatedUid': 'uid2',
    },
  ],
};

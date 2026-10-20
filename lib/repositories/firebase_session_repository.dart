import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/game_answer.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/repositories/firebase_game_commands.dart';

class FirebaseSessionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseGameCommands? _commands;

  FirebaseSessionRepository({FirebaseFirestore? firestore, FirebaseGameCommands? commands})
      : _firestore = firestore ?? FirebaseFirestore.instance, _commands = commands;

  FirebaseGameCommands get _api => _commands ?? FirebaseGameCommands();

  Future<String?> findWaitingSession({required String categoryId, required int maxPlayers}) async {
    final snap = await _firestore.collection('sessions')
        .where('status', isEqualTo: 'waiting').where('isPrivate', isEqualTo: false)
        .where('categoryId', isEqualTo: categoryId)
        .where('maxPlayers', isEqualTo: maxPlayers).limit(10).get();
    return snap.docs.isEmpty ? null : snap.docs.first.id;
  }

  Future<String?> findPrivateSession({required int entryCode}) async =>
      (await _api.call('findPrivateSession', {'entryCode': entryCode}))['sessionId'] as String?;

  Future<String> createSession({required OnlineGameOptions settings}) async {
    settings.validate();
    final result = await _api.call('createSession', {
      'categoryId': settings.categoryId, 'maxPlayers': settings.maxPlayers,
      'questionTimeLimit': settings.questionTimeLimit, 'difficulty': settings.difficulty.name,
      'entryCode': settings.entryCode,
    });
    return result['sessionId'] as String;
  }

  Future<String> joinSession({required String sessionId, int? entryCode}) async =>
      (await _api.call('joinSession', {'sessionId': sessionId, 'entryCode': entryCode}))['sessionId'] as String;

  Future<void> startSession({required String sessionId}) async {
    await _api.call('startSession', {'sessionId': sessionId});
  }

  Future<void> updateSessionSettings({required String sessionId, required int questionTimeLimit,
    required int maxPlayers, required String categoryId, required Difficulty difficulty}) async {
    await _api.call('updateSessionSettings', {'sessionId': sessionId, 'questionTimeLimit': questionTimeLimit,
      'maxPlayers': maxPlayers, 'categoryId': categoryId, 'difficulty': difficulty.name});
  }

  Future<void> leaveGame({required String sessionId, required String uid}) async {
    // Identity comes from the authenticated callable context, never this UI value.
    await _api.call('leaveSession', {'sessionId': sessionId});
  }

  Future<void> removePlayer({required String sessionId, required String uid}) =>
      leaveGame(sessionId: sessionId, uid: uid);

  Stream<Map<String, dynamic>> sessionDocStream(String sessionId) =>
      _firestore.collection('sessions').doc(sessionId).snapshots().asyncMap((snap) async {
        if (snap.exists) return snap.data()!;
        final archive = await _firestore.collection('sessions_archive').doc(sessionId).get();
        if (!archive.exists) throw StateError('Session $sessionId not found');
        final data = archive.data()!;
        if (data['statsApplied'] != true) throw StateError('Session results are not ready');
        final players = (data['playerResults'] as List).cast<Map>();
        return <String, dynamic>{
          'status': 'finished', 'phase': 'finished', 'resultsReady': true,
          'categoryId': data['categoryId'], 'questionIds': data['questionIds'],
          'currentQuestionIndex': (data['rounds'] as List).length - 1,
          'players': {for (final p in players) p['uid'] as String: <String, dynamic>{
            'username': p['username'], 'profilePicture': p['profilePicture'] ?? 'defaultAvatar.png',
            'isEliminated': p['placement'] != 1, 'lotteryTickets': p['lotteryTimesIn'],
          }},
          'lastRoundResult': null,
        };
      });

  Future<GameAnswer> submitAnswer({required String sessionId, required String uid,
    required int roundIndex, required String questionId, required String answer}) async =>
      GameAnswer.fromJson(await _api.call('submitMultiplayerAnswer', {
        'sessionId': sessionId, 'roundIndex': roundIndex, 'questionId': questionId, 'answer': answer,
      }));

  Future<MultiplayerSessionData> fetchArchivedSession(String sessionId) async {
    final snap = await _firestore.collection('sessions_archive').doc(sessionId).get();
    if (!snap.exists) throw StateError('Archived session $sessionId not found');
    return MultiplayerSessionData.fromJson(snap.data()!);
  }
}

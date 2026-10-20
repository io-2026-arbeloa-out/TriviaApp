import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triviaapp/models/session_snapshot.dart';
import 'package:triviaapp/repositories/session_repository.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/game_answer.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/repositories/firebase_game_commands.dart';

class FirebaseSessionRepository implements SessionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseGameCommands? _commands;

  FirebaseSessionRepository({FirebaseFirestore? firestore, FirebaseGameCommands? commands})
      : _firestore = firestore ?? FirebaseFirestore.instance, _commands = commands;

  FirebaseGameCommands get _api => _commands ?? FirebaseGameCommands();

  @override
  Future<String?> findWaitingSession({required String categoryId, required int maxPlayers}) async {
    final snap = await _firestore.collection('sessions')
        .where('status', isEqualTo: 'waiting').where('isPrivate', isEqualTo: false)
        .where('categoryId', isEqualTo: categoryId)
        .where('maxPlayers', isEqualTo: maxPlayers).limit(10).get();
    return snap.docs.isEmpty ? null : snap.docs.first.id;
  }

  @override
  Future<String?> findPrivateSession({required int entryCode}) async =>
      (await _api.call('findPrivateSession', {'entryCode': entryCode}))['sessionId'] as String?;

  @override
  Future<String> createSession({required OnlineGameOptions settings}) async {
    settings.validate();
    final result = await _api.call('createSession', {
      'categoryId': settings.categoryId, 'maxPlayers': settings.maxPlayers,
      'questionTimeLimit': settings.questionTimeLimit, 'difficulty': settings.difficulty.name,
      'entryCode': settings.entryCode,
    });
    return result['sessionId'] as String;
  }

  @override
  Future<String> joinSession({required String sessionId, int? entryCode}) async =>
      (await _api.call('joinSession', {'sessionId': sessionId, 'entryCode': entryCode}))['sessionId'] as String;

  @override
  Future<void> startSession({required String sessionId}) async {
    await _api.call('startSession', {'sessionId': sessionId});
  }

  @override
  Future<void> updateSessionSettings({required String sessionId, required int questionTimeLimit,
    required int maxPlayers, required String categoryId, required Difficulty difficulty}) async {
    await _api.call('updateSessionSettings', {'sessionId': sessionId, 'questionTimeLimit': questionTimeLimit,
      'maxPlayers': maxPlayers, 'categoryId': categoryId, 'difficulty': difficulty.name});
  }

  @override
  Future<void> leaveGame({required String sessionId, required String uid}) async {
    // Identity comes from the authenticated callable context, never this UI value.
    await _api.call('leaveSession', {'sessionId': sessionId});
  }

  @override
  Future<void> removePlayer({required String sessionId, required String uid}) =>
      leaveGame(sessionId: sessionId, uid: uid);

  @override
  Stream<SessionSnapshot> sessionDocStream(String sessionId) =>
      _firestore.collection('sessions').doc(sessionId).snapshots().asyncMap((snap) async {
        if (snap.exists) return SessionSnapshot.fromJson(sessionId, snap.data()!);
        final archive = await _firestore.collection('sessions_archive').doc(sessionId).get();
        if (!archive.exists) throw StateError('Session $sessionId not found');
        return SessionSnapshot.fromArchive(sessionId, archive.data()!);
      });
  @override
  Future<GameAnswer> submitAnswer({required String sessionId, required String uid,
    required int roundIndex, required String questionId, required String answer}) async =>
      GameAnswer.fromJson(await _api.call('submitMultiplayerAnswer', {
        'sessionId': sessionId, 'roundIndex': roundIndex, 'questionId': questionId, 'answer': answer,
      }));

  @override
  Future<MultiplayerSessionData> fetchArchivedSession(String sessionId) async {
    final snap = await _firestore.collection('sessions_archive').doc(sessionId).get();
    if (!snap.exists) throw StateError('Archived session $sessionId not found');
    return MultiplayerSessionData.fromJson(snap.data()!);
  }
}

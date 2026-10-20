import 'package:triviaapp/interfaces/i_multiplayer_connection_service.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

class MultiplayerConnectionService implements IMultiplayerConnectionService {
  final FirebaseSessionRepository _sessionRepository;

  MultiplayerConnectionService({FirebaseSessionRepository? sessionRepository})
      : _sessionRepository = sessionRepository ?? FirebaseSessionRepository();

  @override
  Future<String> connectPlayer({required String uid, required String username,
    required OnlineGameOptions settings}) async {
    settings.validate();
    if (settings.isPrivate) {
      final id = await _sessionRepository.findPrivateSession(entryCode: settings.entryCode!);
      return id == null
          ? _sessionRepository.createSession(settings: settings)
          : _sessionRepository.joinSession(sessionId: id, entryCode: settings.entryCode);
    }
    for (var attempt = 0; ; attempt++) {
      try {
        final id = await _sessionRepository.findWaitingSession(
          categoryId: settings.categoryId, maxPlayers: settings.maxPlayers,
        );
        return id == null
            ? await _sessionRepository.createSession(settings: settings)
            : await _sessionRepository.joinSession(sessionId: id);
      } on StateError {
        if (attempt == 2) rethrow;
        await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
  }

  @override
  Future<void> disconnectPlayer({required String sessionId, required String uid}) =>
      _sessionRepository.removePlayer(sessionId: sessionId, uid: uid);
}

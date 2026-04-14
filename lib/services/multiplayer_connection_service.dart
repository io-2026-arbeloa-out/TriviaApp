import 'package:triviaapp/interfaces/i_multiplayer_connection_service.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

class MultiplayerConnectionService implements IMultiplayerConnectionService {
  final FirebaseSessionRepository _sessionRepository;

  MultiplayerConnectionService(this._sessionRepository);

  @override
  void connectPlayer() {
    // Możesz tu np. przygotować lokalny stan, połączyć sockety itp.
    // Na poziomie repo nie ma tej metody – zostaw jako hook.
  }

  @override
  Future<void> connectPlayers() async {
    // W prawdziwej implementacji czekałbyś aż wymagana liczba graczy dołączy.
    // Tu pozostawiamy jako placeholder.
  }

  @override
  Future<void> startMultiplayerGame() async {
    // Start gry może wymagać aktualizacji statusu sesji itp.
    // Wymaga rozszerzenia repozytorium – placeholder.
  }
}
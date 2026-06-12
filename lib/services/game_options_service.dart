import 'package:triviaapp/interfaces/i_game_options_service.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/repositories/firebase_options_repository.dart';

class GameOptionsService implements IGameOptionsService {
  final FirebaseOptionsRepository _optionsRepository;

  GameOptionsService(this._optionsRepository);

  @override
  Future<void> saveOptions(OnlineGameOptions options) {
    // W repo jest saveOptions(UserOptions), więc musisz dodać odpowiednie metody
    // albo mapowanie między OnlineGameOptions a strukturą w bazie.
    throw UnimplementedError('saveOptions(OnlineGameOptions) wymaga metody w FirebaseOptionsRepository');
  }

  @override
  Future<OnlineGameOptions> getOptions() async {
    // Analogicznie – wymaga wsparcia w repo.
    throw UnimplementedError('getOptions() wymaga metody w FirebaseOptionsRepository');
  }
}
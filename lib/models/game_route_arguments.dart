import 'package:triviaapp/interfaces/i_multiplayer_game_service.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/singleplayer_session_data.dart';
import 'package:triviaapp/models/ui_options.dart';

class SingleplayerOptionsArguments {
  final String category;
  final UIOptions options;
  const SingleplayerOptionsArguments(this.category, this.options);
}

class SingleplayerSessionArguments {
  final UIOptions options;
  final SingleplayerSessionData sessionData;
  const SingleplayerSessionArguments(this.options, this.sessionData);
}

class MultiplayerGameArguments {
  final UIOptions options;
  final IMultiplayerGameService gameService;
  const MultiplayerGameArguments(this.options, this.gameService);
}

class MultiplayerScoreArguments {
  final UIOptions options;
  final MultiplayerSessionData session;
  final String myUid;
  const MultiplayerScoreArguments(this.options, this.session, this.myUid);
}

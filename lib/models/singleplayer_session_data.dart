import 'package:triviaapp/models/singleplayer_game_options.dart';

class SingleplayerSessionData {
  final String _category;
  List<bool> _results;
  final SingleplayerGameOptions _options;

  SingleplayerSessionData({
    required String category,
    List<bool> results = const [],
    required SingleplayerGameOptions options,
  })  : _category = category,
        _results = List.from(results),
        _options = options;


  String get category => _category;
  List<bool> get results => _results;
  SingleplayerGameOptions get options => _options;
}
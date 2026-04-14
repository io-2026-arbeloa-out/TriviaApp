import 'package:triviaapp/models/user_options.dart';

abstract class IUserOptionsService {
  Future<void> saveOptions(UserOptions options);

  Future<UserOptions> getOptions();
}
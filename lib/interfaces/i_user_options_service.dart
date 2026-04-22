import 'package:triviaapp/models/user_options.dart';

abstract class IUserOptionsService {
  Future<void> saveUserOptions(UserOptions options);
  Future<UserOptions> getUserOptions();
}
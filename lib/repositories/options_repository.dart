import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/models/user_options.dart';

abstract class OptionsRepository {
  Future<UserOptions> getUserOptions();
  Future<void> saveUserOptions(UserOptions options);
  Future<UIOptions> getUIOptions(String preset);
  Future<void> saveUIOptions(String preset);
  Future<Map<String, UIOptions>> getUIPresets();
}

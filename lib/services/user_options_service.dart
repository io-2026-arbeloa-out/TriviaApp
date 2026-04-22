import 'package:triviaapp/interfaces/i_user_options_service.dart';
import 'package:triviaapp/models/user_options.dart';
import 'package:triviaapp/repositories/firebase_options_repository.dart';

class UserOptionsService implements IUserOptionsService {
  final FirebaseOptionsRepository _optionsRepository;

  UserOptionsService([FirebaseOptionsRepository? optionsRepository])
      : _optionsRepository = optionsRepository ?? FirebaseOptionsRepository();

  @override
  Future<void> saveUserOptions(UserOptions options) {
    return _optionsRepository.saveUserOptions(options);
  }

  @override
  Future<UserOptions> getUserOptions() {
    return _optionsRepository.getUserOptions();
  }
}
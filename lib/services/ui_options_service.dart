import 'package:firebase_auth/firebase_auth.dart';
import 'package:triviaapp/interfaces/i_ui_options_service.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/repositories/firebase_options_repository.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';

class UIOptionsService implements IUIOptionsService {
  final FirebaseOptionsRepository _optionsRepository;
  final FirebaseProfileRepository _profileRepository;


  UIOptionsService([
    FirebaseOptionsRepository? optionsRepository,
    FirebaseProfileRepository? profileRepository,
  ]) : _optionsRepository = optionsRepository ?? FirebaseOptionsRepository(),
        _profileRepository = profileRepository ?? FirebaseProfileRepository();

  @override
  Future<UIOptions> getUIOptions() async {
    //TODO: Firebase Auth
    //final uid = FirebaseAuth.instance.currentUser?.uid;
    final String uid = 'uid1';
    //if (uid == null) return UIOptions();

    final String preset = await _profileRepository.getUIPreset(uid);
    if (preset == 'default') return UIOptions();
    return _optionsRepository.loadUIOptions("pr2");
  }

  @override
  Future<void> saveUIOptions(UIOptions options) {
    return _optionsRepository.saveUIOptions(options);
  }
}
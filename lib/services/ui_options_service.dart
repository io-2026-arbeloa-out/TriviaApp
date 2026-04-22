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
  ])  : _optionsRepository = optionsRepository ?? FirebaseOptionsRepository(),
        _profileRepository = profileRepository ?? FirebaseProfileRepository();

  @override
  Future<UIOptions> getUIOptions() async {
    final preset = await this.getCurrentPreset();
    if (preset == 'default') return UIOptions();
    return _optionsRepository.getUIOptions(preset);
  }

  @override
  Future<void> saveUIOptions(String preset) {
    return _optionsRepository.saveUIOptions(preset);
  }

  @override
  Future<Map<String, UIOptions>> getUIPresets() {
    return _optionsRepository.getUIPresets();
  }

  @override
  Future<String> getCurrentPreset() {
    return _profileRepository.getUIPreset();
  }
}
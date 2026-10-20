import 'package:triviaapp/interfaces/i_ui_options_service.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/repositories/options_repository.dart';
import 'package:triviaapp/repositories/profile_repository.dart';

class UIOptionsService implements IUIOptionsService {
  final OptionsRepository _optionsRepository;
  final ProfileRepository _profileRepository;

  UIOptionsService(this._optionsRepository, this._profileRepository);

  @override
  Future<UIOptions> getUIOptions() async {
    final preset = await getCurrentPreset();
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

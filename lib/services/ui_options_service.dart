import 'package:triviaapp/interfaces/i_ui_options_service.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/repositories/firebase_options_repository.dart';

class UIOptionsService implements IUIOptionsService {
  final FirebaseOptionsRepository _optionsRepository;

  UIOptionsService(this._optionsRepository);

  @override
  Future<UIOptions> getUIOptions() {
    return _optionsRepository.loadUIOptions();
  }

  @override
  Future<void> saveUIOptions(UIOptions options) {
    return _optionsRepository.saveUIOptions(options);
  }
}
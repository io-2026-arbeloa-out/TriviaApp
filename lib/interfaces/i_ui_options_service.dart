import 'package:triviaapp/models/ui_options.dart';

abstract class IUIOptionsService {
  Future<UIOptions> getUIOptions();
  Future<void> saveUIOptions(String preset);
  Future<Map<String, UIOptions>> getUIPresets();
  Future<String> getCurrentPreset();
}
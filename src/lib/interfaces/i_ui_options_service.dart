import 'package:triviaapp/models/ui_options.dart';

abstract class IUIOptionsService {
  Future<UIOptions> getUIOptions();

  Future<void> saveUIOptions(UIOptions options);
}
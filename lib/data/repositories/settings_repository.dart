import 'package:hive/hive.dart';

import '../../core/constants.dart';

class SettingsRepository {
  Box get _box => Hive.box(ForjaBoxes.settings);

  bool get onboardingDone =>
      _box.get(ForjaStorage.onboardingDoneKey, defaultValue: false) as bool;

  String get userName =>
      _box.get(ForjaStorage.userNameKey, defaultValue: '') as String;

  String get userMode =>
      _box.get(ForjaStorage.userModeKey, defaultValue: ForjaMode.nofap)
          as String;

  Future<void> completeOnboarding({
    required String name,
    required String mode,
  }) async {
    await _box.put(ForjaStorage.onboardingDoneKey, true);
    await _box.put(ForjaStorage.userNameKey, name);
    await _box.put(ForjaStorage.userModeKey, mode);
  }
}

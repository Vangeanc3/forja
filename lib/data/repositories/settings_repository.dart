import 'package:hive_flutter/hive_flutter.dart';

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

  String get userReason =>
      _box.get(ForjaStorage.userReasonKey, defaultValue: '') as String;

  bool get notificationsEnabled =>
      _box.get(ForjaStorage.notificationsEnabledKey, defaultValue: true)
          as bool;

  int get notificationHour =>
      _box.get(ForjaStorage.notificationHourKey, defaultValue: 8) as int;

  Future<void> updateName(String name) =>
      _box.put(ForjaStorage.userNameKey, name);

  Future<void> updateMode(String mode) =>
      _box.put(ForjaStorage.userModeKey, mode);

  Future<void> updateReason(String reason) =>
      _box.put(ForjaStorage.userReasonKey, reason);

  Future<void> updateNotificationsEnabled(bool enabled) =>
      _box.put(ForjaStorage.notificationsEnabledKey, enabled);

  Future<void> updateNotificationHour(int hour) =>
      _box.put(ForjaStorage.notificationHourKey, hour);

  String? get lastCelebrationDate =>
      _box.get(ForjaStorage.lastCelebrationDateKey) as String?;

  Future<void> setCelebrationDone(String date) =>
      _box.put(ForjaStorage.lastCelebrationDateKey, date);

  String? get supportContactName =>
      _box.get(ForjaStorage.supportContactNameKey) as String?;

  String? get supportContactPhone =>
      _box.get(ForjaStorage.supportContactPhoneKey) as String?;

  Future<void> updateSupportContact(String name, String phone) async {
    await _box.put(ForjaStorage.supportContactNameKey, name);
    await _box.put(ForjaStorage.supportContactPhoneKey, phone);
  }

  List<String> get riskHours =>
      _box.get(ForjaStorage.riskHoursKey, defaultValue: <String>[])
          .cast<String>();

  Future<void> updateRiskHours(List<String> hours) =>
      _box.put(ForjaStorage.riskHoursKey, hours);

  Future<void> completeOnboarding({
    required String name,
    required String mode,
    required String reason,
  }) async {
    await _box.put(ForjaStorage.onboardingDoneKey, true);
    await _box.put(ForjaStorage.userNameKey, name);
    await _box.put(ForjaStorage.userModeKey, mode);
    await _box.put(ForjaStorage.userReasonKey, reason);
  }
}

import 'package:hive_flutter/hive_flutter.dart';
import 'package:forja/data/models/settings_model.dart';

import '../../core/constants.dart';
import '../services/firebase_sync_service.dart';

class SettingsRepository {
  SettingsRepository({FirebaseSyncService? firebaseSync})
    : _firebaseSync = firebaseSync;

  final FirebaseSyncService? _firebaseSync;

  Box get _box => Hive.box(ForjaBoxes.settings);

  bool get onboardingDone =>
      _box.get(ForjaStorage.onboardingDoneKey, defaultValue: false) as bool;

  String get userName =>
      _box.get(ForjaStorage.userNameKey, defaultValue: '') as String;

  String get userMode =>
      _box.get(ForjaStorage.userModeKey, defaultValue: ForjaMode.recruta)
          as String;

  String get userReason =>
      _box.get(ForjaStorage.userReasonKey, defaultValue: '') as String;

  bool get notificationsEnabled =>
      _box.get(ForjaStorage.notificationsEnabledKey, defaultValue: true)
          as bool;

  int get notificationHour =>
      _box.get(ForjaStorage.notificationHourKey, defaultValue: 8) as int;

  Future<void> updateName(String name) async {
    await _box.put(ForjaStorage.userNameKey, name);
    await _sync();
  }

  Future<void> updateMode(String mode) async {
    await _box.put(ForjaStorage.userModeKey, mode);
    await _sync();
  }

  Future<void> updateReason(String reason) async {
    await _box.put(ForjaStorage.userReasonKey, reason);
    await _sync();
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    await _box.put(ForjaStorage.notificationsEnabledKey, enabled);
    await _sync();
  }

  Future<void> updateNotificationHour(int hour) async {
    await _box.put(ForjaStorage.notificationHourKey, hour);
    await _sync();
  }

  String? get lastCelebrationDate =>
      _box.get(ForjaStorage.lastCelebrationDateKey) as String?;

  Future<void> setCelebrationDone(String date) async {
    await _box.put(ForjaStorage.lastCelebrationDateKey, date);
    await _sync();
  }

  String? get lastDailyQuotePopupDate =>
      _box.get(ForjaStorage.lastDailyQuotePopupDateKey) as String?;

  Future<void> setDailyQuotePopupShown(String date) async {
    await _box.put(ForjaStorage.lastDailyQuotePopupDateKey, date);
    await _sync();
  }

  String? get supportContactName =>
      _box.get(ForjaStorage.supportContactNameKey) as String?;

  String? get supportContactPhone =>
      _box.get(ForjaStorage.supportContactPhoneKey) as String?;

  Future<void> updateSupportContact(String name, String phone) async {
    await _box.put(ForjaStorage.supportContactNameKey, name);
    await _box.put(ForjaStorage.supportContactPhoneKey, phone);
    await _sync();
  }

  List<String> get riskHours => _box
      .get(ForjaStorage.riskHoursKey, defaultValue: <String>[])
      .cast<String>();

  Future<void> updateRiskHours(List<String> hours) async {
    await _box.put(ForjaStorage.riskHoursKey, hours);
    await _sync();
  }

  String get userGoal =>
      _box.get(ForjaStorage.userGoalsKey, defaultValue: '') as String;

  Future<void> updateGoal(String goal) async {
    await _box.put(ForjaStorage.userGoalsKey, goal);
    await _sync();
  }

  SettingsModel snapshot() => SettingsModel(
    onboardingDone: onboardingDone,
    userName: userName,
    userMode: userMode,
    userReason: userReason,
    notificationsEnabled: notificationsEnabled,
    notificationHour: notificationHour,
    lastCelebrationDate: lastCelebrationDate,
    lastDailyQuotePopupDate: lastDailyQuotePopupDate,
    supportContactName: supportContactName,
    supportContactPhone: supportContactPhone,
    riskHours: List.unmodifiable(riskHours),
    userGoal: userGoal,
  );

  Future<void> completeOnboarding({
    required String name,
    required String mode,
    required String reason,
    required String goal,
  }) async {
    await _box.put(ForjaStorage.onboardingDoneKey, true);
    await _box.put(ForjaStorage.userNameKey, name);
    await _box.put(ForjaStorage.userModeKey, mode);
    await _box.put(ForjaStorage.userReasonKey, reason);
    await _box.put(ForjaStorage.userGoalsKey, goal);
    await _sync();
  }

  Future<void> _sync() =>
      _firebaseSync?.setDocument('settings', 'current', snapshot().toMap()) ??
      Future.value();

  Future<void> syncCurrent() => _sync();

  Future<void> mergeRemote(FirebaseSyncDocument? document) async {
    if (document == null) {
      await syncCurrent();
      return;
    }

    final local = snapshot();
    final remote = SettingsModel.fromMap(document.data);
    final preferRemote = !local.onboardingDone && remote.onboardingDone;
    final merged = SettingsModel(
      onboardingDone: local.onboardingDone || remote.onboardingDone,
      userName: _chooseText(
        local.userName,
        remote.userName,
        preferRemote: preferRemote,
      ),
      userMode: preferRemote ? remote.userMode : local.userMode,
      userReason: _chooseText(
        local.userReason,
        remote.userReason,
        preferRemote: preferRemote,
      ),
      notificationsEnabled: preferRemote
          ? remote.notificationsEnabled
          : local.notificationsEnabled,
      notificationHour: preferRemote
          ? remote.notificationHour
          : local.notificationHour,
      lastCelebrationDate: _latestDateString(
        local.lastCelebrationDate,
        remote.lastCelebrationDate,
      ),
      lastDailyQuotePopupDate: _latestDateString(
        local.lastDailyQuotePopupDate,
        remote.lastDailyQuotePopupDate,
      ),
      supportContactName: _chooseNullableText(
        local.supportContactName,
        remote.supportContactName,
        preferRemote: preferRemote,
      ),
      supportContactPhone: _chooseNullableText(
        local.supportContactPhone,
        remote.supportContactPhone,
        preferRemote: preferRemote,
      ),
      riskHours: {...local.riskHours, ...remote.riskHours}.toList(),
      userGoal: _chooseText(
        local.userGoal,
        remote.userGoal,
        preferRemote: preferRemote,
      ),
    );

    await _writeSnapshot(merged);
    await syncCurrent();
  }

  Future<void> _writeSnapshot(SettingsModel model) async {
    await _box.put(ForjaStorage.onboardingDoneKey, model.onboardingDone);
    await _box.put(ForjaStorage.userNameKey, model.userName);
    await _box.put(ForjaStorage.userModeKey, model.userMode);
    await _box.put(ForjaStorage.userReasonKey, model.userReason);
    await _box.put(
      ForjaStorage.notificationsEnabledKey,
      model.notificationsEnabled,
    );
    await _box.put(ForjaStorage.notificationHourKey, model.notificationHour);
    await _putNullable(
      ForjaStorage.lastCelebrationDateKey,
      model.lastCelebrationDate,
    );
    await _putNullable(
      ForjaStorage.lastDailyQuotePopupDateKey,
      model.lastDailyQuotePopupDate,
    );
    await _putNullable(
      ForjaStorage.supportContactNameKey,
      model.supportContactName,
    );
    await _putNullable(
      ForjaStorage.supportContactPhoneKey,
      model.supportContactPhone,
    );
    await _box.put(ForjaStorage.riskHoursKey, model.riskHours);
    await _box.put(ForjaStorage.userGoalsKey, model.userGoal);
  }

  Future<void> _putNullable(String key, String? value) {
    if (value == null) return _box.delete(key);
    return _box.put(key, value);
  }

  String _chooseText(
    String local,
    String remote, {
    required bool preferRemote,
  }) {
    if (preferRemote) return remote.trim().isEmpty ? local : remote;
    return local.trim().isEmpty ? remote : local;
  }

  String? _chooseNullableText(
    String? local,
    String? remote, {
    required bool preferRemote,
  }) {
    final chosen = _chooseText(
      local ?? '',
      remote ?? '',
      preferRemote: preferRemote,
    );
    return chosen.trim().isEmpty ? null : chosen;
  }

  String? _latestDateString(String? first, String? second) {
    final firstDate = first == null ? null : DateTime.tryParse(first);
    final secondDate = second == null ? null : DateTime.tryParse(second);
    if (firstDate == null) return second;
    if (secondDate == null) return first;
    return firstDate.isAfter(secondDate) ? first : second;
  }
}

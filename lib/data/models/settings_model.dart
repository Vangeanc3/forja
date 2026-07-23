import 'package:forja/core/constants.dart';
import 'package:forja/domain/entities/settings_entity.dart';

class SettingsModel extends SettingsEntity {
  const SettingsModel({
    required super.onboardingDone,
    required super.userName,
    required super.userMode,
    required super.userReason,
    required super.notificationsEnabled,
    required super.notificationHour,
    required super.riskHours,
    required super.userGoal,
    super.lastCelebrationDate,
    super.lastDailyQuotePopupDate,
    super.supportContactName,
    super.supportContactPhone,
  });

  factory SettingsModel.fromMap(Map<dynamic, dynamic> map) => SettingsModel(
    onboardingDone: map['onboardingDone'] as bool? ?? false,
    userName: map['userName'] as String? ?? '',
    userMode: map['userMode'] as String? ?? ForjaMode.recruta,
    userReason: map['userReason'] as String? ?? '',
    notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
    notificationHour: _intFrom(map['notificationHour'], fallback: 8),
    lastCelebrationDate: map['lastCelebrationDate'] as String?,
    lastDailyQuotePopupDate: map['lastDailyQuotePopupDate'] as String?,
    supportContactName: map['supportContactName'] as String?,
    supportContactPhone: map['supportContactPhone'] as String?,
    riskHours: List<String>.from(map['riskHours'] as List? ?? const <String>[]),
    userGoal: map['userGoal'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'onboardingDone': onboardingDone,
    'userName': userName,
    'userMode': userMode,
    'userReason': userReason,
    'notificationsEnabled': notificationsEnabled,
    'notificationHour': notificationHour,
    'lastCelebrationDate': lastCelebrationDate,
    'lastDailyQuotePopupDate': lastDailyQuotePopupDate,
    'supportContactName': supportContactName,
    'supportContactPhone': supportContactPhone,
    'riskHours': riskHours,
    'userGoal': userGoal,
  };
}

int _intFrom(Object? value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

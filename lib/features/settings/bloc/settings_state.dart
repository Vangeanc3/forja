import 'package:equatable/equatable.dart';
import 'package:forja/domain/entities/settings_entity.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.onboardingDone,
    required this.userName,
    required this.userMode,
    required this.userReason,
    required this.notificationsEnabled,
    required this.notificationHour,
    required this.riskHours,
    required this.userGoal,
    this.lastCelebrationDate,
    this.lastDailyQuotePopupDate,
    this.supportContactName,
    this.supportContactPhone,
  });

  factory SettingsState.fromEntity(SettingsEntity entity) => SettingsState(
    onboardingDone: entity.onboardingDone,
    userName: entity.userName,
    userMode: entity.userMode,
    userReason: entity.userReason,
    notificationsEnabled: entity.notificationsEnabled,
    notificationHour: entity.notificationHour,
    lastCelebrationDate: entity.lastCelebrationDate,
    lastDailyQuotePopupDate: entity.lastDailyQuotePopupDate,
    supportContactName: entity.supportContactName,
    supportContactPhone: entity.supportContactPhone,
    riskHours: List.unmodifiable(entity.riskHours),
    userGoal: entity.userGoal,
  );

  SettingsEntity toEntity() => SettingsEntity(
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

  final bool onboardingDone;
  final String userName;
  final String userMode;
  final String userReason;
  final bool notificationsEnabled;
  final int notificationHour;
  final String? lastCelebrationDate;
  final String? lastDailyQuotePopupDate;
  final String? supportContactName;
  final String? supportContactPhone;
  final List<String> riskHours;
  final String userGoal;

  @override
  List<Object?> get props => [
    onboardingDone,
    userName,
    userMode,
    userReason,
    notificationsEnabled,
    notificationHour,
    lastCelebrationDate,
    lastDailyQuotePopupDate,
    supportContactName,
    supportContactPhone,
    riskHours,
    userGoal,
  ];
}

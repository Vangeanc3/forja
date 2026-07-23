class SettingsEntity {
  const SettingsEntity({
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
}

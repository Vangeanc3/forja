import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class SettingsRefreshed extends SettingsEvent {
  const SettingsRefreshed();
}

class SettingsNameUpdated extends SettingsEvent {
  const SettingsNameUpdated(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

class SettingsModeUpdated extends SettingsEvent {
  const SettingsModeUpdated(this.mode);

  final String mode;

  @override
  List<Object?> get props => [mode];
}

class SettingsReasonUpdated extends SettingsEvent {
  const SettingsReasonUpdated(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

class SettingsGoalUpdated extends SettingsEvent {
  const SettingsGoalUpdated(this.goal);

  final String goal;

  @override
  List<Object?> get props => [goal];
}

class SettingsNotificationsUpdated extends SettingsEvent {
  const SettingsNotificationsUpdated(this.enabled);

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}

class SettingsNotificationHourUpdated extends SettingsEvent {
  const SettingsNotificationHourUpdated(this.hour);

  final int hour;

  @override
  List<Object?> get props => [hour];
}

class SettingsSupportContactUpdated extends SettingsEvent {
  const SettingsSupportContactUpdated({
    required this.name,
    required this.phone,
  });

  final String name;
  final String phone;

  @override
  List<Object?> get props => [name, phone];
}

class SettingsRiskHoursUpdated extends SettingsEvent {
  const SettingsRiskHoursUpdated(this.hours);

  final List<String> hours;

  @override
  List<Object?> get props => [hours];
}

class SettingsCelebrationMarked extends SettingsEvent {
  const SettingsCelebrationMarked(this.date);

  final String date;

  @override
  List<Object?> get props => [date];
}

class SettingsDailyQuotePopupMarked extends SettingsEvent {
  const SettingsDailyQuotePopupMarked(this.date);

  final String date;

  @override
  List<Object?> get props => [date];
}

class SettingsOnboardingCompleted extends SettingsEvent {
  const SettingsOnboardingCompleted({
    required this.name,
    required this.mode,
    required this.reason,
    required this.goal,
  });

  final String name;
  final String mode;
  final String reason;
  final String goal;

  @override
  List<Object?> get props => [name, mode, reason, goal];
}

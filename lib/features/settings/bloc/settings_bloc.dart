import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/notification_service.dart';
import '../../../data/repositories/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this._repository)
    : super(SettingsState.fromEntity(_repository.snapshot())) {
    on<SettingsRefreshed>(_onRefreshed);
    on<SettingsNameUpdated>(_onNameUpdated);
    on<SettingsModeUpdated>(_onModeUpdated);
    on<SettingsReasonUpdated>(_onReasonUpdated);
    on<SettingsGoalUpdated>(_onGoalUpdated);
    on<SettingsNotificationsUpdated>(_onNotificationsUpdated);
    on<SettingsNotificationHourUpdated>(_onNotificationHourUpdated);
    on<SettingsSupportContactUpdated>(_onSupportContactUpdated);
    on<SettingsRiskHoursUpdated>(_onRiskHoursUpdated);
    on<SettingsCelebrationMarked>(_onCelebrationMarked);
    on<SettingsDailyQuotePopupMarked>(_onDailyQuotePopupMarked);
    on<SettingsOnboardingCompleted>(_onOnboardingCompleted);
  }

  final SettingsRepository _repository;

  SettingsState _snapshot() => SettingsState.fromEntity(_repository.snapshot());

  void _onRefreshed(SettingsRefreshed event, Emitter<SettingsState> emit) {
    emit(_snapshot());
  }

  Future<void> _onNameUpdated(
    SettingsNameUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateName(event.name);
    emit(_snapshot());
  }

  Future<void> _onModeUpdated(
    SettingsModeUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateMode(event.mode);
    emit(_snapshot());
  }

  Future<void> _onReasonUpdated(
    SettingsReasonUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateReason(event.reason);
    emit(_snapshot());
  }

  Future<void> _onGoalUpdated(
    SettingsGoalUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateGoal(event.goal);
    emit(_snapshot());
  }

  Future<void> _onNotificationsUpdated(
    SettingsNotificationsUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateNotificationsEnabled(event.enabled);
    final nextState = _snapshot();
    emit(nextState);
    await NotificationService.scheduleAll(nextState.toEntity());
  }

  Future<void> _onNotificationHourUpdated(
    SettingsNotificationHourUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateNotificationHour(event.hour);
    final nextState = _snapshot();
    emit(nextState);
    await NotificationService.scheduleAll(nextState.toEntity());
  }

  Future<void> _onSupportContactUpdated(
    SettingsSupportContactUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateSupportContact(event.name, event.phone);
    emit(_snapshot());
  }

  Future<void> _onRiskHoursUpdated(
    SettingsRiskHoursUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.updateRiskHours(event.hours);
    final nextState = _snapshot();
    emit(nextState);
    await NotificationService.scheduleAll(nextState.toEntity());
  }

  Future<void> _onCelebrationMarked(
    SettingsCelebrationMarked event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.setCelebrationDone(event.date);
    emit(_snapshot());
  }

  Future<void> _onDailyQuotePopupMarked(
    SettingsDailyQuotePopupMarked event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.setDailyQuotePopupShown(event.date);
    emit(_snapshot());
  }

  Future<void> _onOnboardingCompleted(
    SettingsOnboardingCompleted event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.completeOnboarding(
      name: event.name,
      mode: event.mode,
      reason: event.reason,
      goal: event.goal,
    );
    final nextState = _snapshot();
    emit(nextState);
    await NotificationService.scheduleAll(nextState.toEntity());
  }
}

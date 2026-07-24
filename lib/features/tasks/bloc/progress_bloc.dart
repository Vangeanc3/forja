import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/progress_repository.dart';
import 'progress_event.dart';
import 'progress_state.dart';

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  ProgressBloc(this._repository)
    : super(ProgressState(areas: _repository.getAll())) {
    on<ProgressRefreshed>(_onRefreshed);
    on<ProgressAreaCreated>(_onAreaCreated);
    on<ProgressAreaUpdated>(_onAreaUpdated);
    on<ProgressAreaDeleted>(_onAreaDeleted);
    on<ProgressMetricCreated>(_onMetricCreated);
    on<ProgressMetricUpdated>(_onMetricUpdated);
    on<ProgressMetricDeleted>(_onMetricDeleted);
  }

  final ProgressRepository _repository;

  void _onRefreshed(ProgressRefreshed event, Emitter<ProgressState> emit) {
    emit(ProgressState(areas: _repository.getAll()));
  }

  Future<void> _onAreaCreated(
    ProgressAreaCreated event,
    Emitter<ProgressState> emit,
  ) async {
    await _repository.addArea(
      title: event.title,
      description: event.description,
    );
    emit(ProgressState(areas: _repository.getAll()));
  }

  Future<void> _onAreaUpdated(
    ProgressAreaUpdated event,
    Emitter<ProgressState> emit,
  ) async {
    await _repository.updateArea(
      id: event.id,
      title: event.title,
      description: event.description,
    );
    emit(ProgressState(areas: _repository.getAll()));
  }

  Future<void> _onAreaDeleted(
    ProgressAreaDeleted event,
    Emitter<ProgressState> emit,
  ) async {
    await _repository.deleteArea(event.id);
    emit(ProgressState(areas: _repository.getAll()));
  }

  Future<void> _onMetricCreated(
    ProgressMetricCreated event,
    Emitter<ProgressState> emit,
  ) async {
    await _repository.addMetric(
      areaId: event.areaId,
      title: event.title,
      percent: event.percent,
      description: event.description,
      note: event.note,
      details: event.details,
    );
    emit(ProgressState(areas: _repository.getAll()));
  }

  Future<void> _onMetricUpdated(
    ProgressMetricUpdated event,
    Emitter<ProgressState> emit,
  ) async {
    await _repository.updateMetric(
      areaId: event.areaId,
      metricId: event.metricId,
      title: event.title,
      percent: event.percent,
      description: event.description,
      note: event.note,
      details: event.details,
    );
    emit(ProgressState(areas: _repository.getAll()));
  }

  Future<void> _onMetricDeleted(
    ProgressMetricDeleted event,
    Emitter<ProgressState> emit,
  ) async {
    await _repository.deleteMetric(
      areaId: event.areaId,
      metricId: event.metricId,
    );
    emit(ProgressState(areas: _repository.getAll()));
  }
}

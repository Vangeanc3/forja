import 'package:equatable/equatable.dart';

abstract class ProgressEvent extends Equatable {
  const ProgressEvent();

  @override
  List<Object?> get props => [];
}

class ProgressRefreshed extends ProgressEvent {
  const ProgressRefreshed();
}

class ProgressAreaCreated extends ProgressEvent {
  const ProgressAreaCreated({required this.title, this.description = ''});

  final String title;
  final String description;

  @override
  List<Object?> get props => [title, description];
}

class ProgressAreaUpdated extends ProgressEvent {
  const ProgressAreaUpdated({
    required this.id,
    required this.title,
    this.description = '',
  });

  final String id;
  final String title;
  final String description;

  @override
  List<Object?> get props => [id, title, description];
}

class ProgressAreaDeleted extends ProgressEvent {
  const ProgressAreaDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

class ProgressMetricCreated extends ProgressEvent {
  const ProgressMetricCreated({
    required this.areaId,
    required this.title,
    required this.percent,
    this.description = '',
    this.note = '',
  });

  final String areaId;
  final String title;
  final int percent;
  final String description;
  final String note;

  @override
  List<Object?> get props => [areaId, title, percent, description, note];
}

class ProgressMetricUpdated extends ProgressEvent {
  const ProgressMetricUpdated({
    required this.areaId,
    required this.metricId,
    required this.title,
    required this.percent,
    this.description = '',
    this.note = '',
  });

  final String areaId;
  final String metricId;
  final String title;
  final int percent;
  final String description;
  final String note;

  @override
  List<Object?> get props => [
    areaId,
    metricId,
    title,
    percent,
    description,
    note,
  ];
}

class ProgressMetricDeleted extends ProgressEvent {
  const ProgressMetricDeleted({required this.areaId, required this.metricId});

  final String areaId;
  final String metricId;

  @override
  List<Object?> get props => [areaId, metricId];
}

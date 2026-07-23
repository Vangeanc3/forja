import 'package:equatable/equatable.dart';

import 'package:forja/domain/entities/progress_area_entity.dart';

class ProgressState extends Equatable {
  const ProgressState({required this.areas});

  final List<ProgressAreaEntity> areas;

  @override
  List<Object?> get props => [areas];
}

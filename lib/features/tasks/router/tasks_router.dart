class TasksRouter {
  static const initial = '/evolution';
  static const newArea = '/evolution/new';
  static const detail = '/evolution/:areaId';
  static const editArea = '/evolution/:areaId/edit';
  static const newMetric = '/evolution/:areaId/metrics/new';
  static const editMetric = '/evolution/:areaId/metrics/:metricId/edit';

  static const name = 'evolution';
  static const newAreaName = 'evolution-new-area';
  static const detailName = 'evolution-detail';
  static const editAreaName = 'evolution-edit-area';
  static const newMetricName = 'evolution-new-metric';
  static const editMetricName = 'evolution-edit-metric';

  static String detailLocation(String areaId) => '$initial/$areaId';

  static String editAreaLocation(String areaId) => '$initial/$areaId/edit';

  static String newMetricLocation(String areaId) =>
      '$initial/$areaId/metrics/new';

  static String editMetricLocation(String areaId, String metricId) =>
      '$initial/$areaId/metrics/$metricId/edit';
}

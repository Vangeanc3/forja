import 'package:forja/features/tasks/router/tasks_router.dart';
import 'package:forja/features/tasks/view/tasks_screen.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> routes = [
  GoRoute(
    path: TasksRouter.initial,
    name: TasksRouter.name,
    builder: (context, state) => const ProgressAreasScreen(),
  ),
  GoRoute(
    path: TasksRouter.newArea,
    name: TasksRouter.newAreaName,
    builder: (context, state) => const ProgressAreaFormScreen(),
  ),
  GoRoute(
    path: TasksRouter.editArea,
    name: TasksRouter.editAreaName,
    builder: (context, state) =>
        ProgressAreaFormScreen(areaId: state.pathParameters['areaId']),
  ),
  GoRoute(
    path: TasksRouter.newMetric,
    name: TasksRouter.newMetricName,
    builder: (context, state) =>
        ProgressMetricFormScreen(areaId: state.pathParameters['areaId'] ?? ''),
  ),
  GoRoute(
    path: TasksRouter.editMetric,
    name: TasksRouter.editMetricName,
    builder: (context, state) => ProgressMetricFormScreen(
      areaId: state.pathParameters['areaId'] ?? '',
      metricId: state.pathParameters['metricId'],
    ),
  ),
  GoRoute(
    path: TasksRouter.detail,
    name: TasksRouter.detailName,
    builder: (context, state) =>
        ProgressAreaDetailScreen(areaId: state.pathParameters['areaId'] ?? ''),
  ),
];

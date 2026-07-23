import 'package:forja/features/relapse/router/relapse_router.dart';
import 'package:forja/features/relapse/view/relapse_history_screen.dart';
import 'package:forja/features/relapse/view/relapse_screen.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> routes = [
  GoRoute(
    path: RelapseRouter.initial,
    name: RelapseRouter.name,
    builder: (context, state) => const RelapseScreen(),
  ),
  GoRoute(
    path: RelapseRouter.history,
    name: RelapseRouter.historyName,
    builder: (context, state) => const RelapseHistoryScreen(),
  ),
];

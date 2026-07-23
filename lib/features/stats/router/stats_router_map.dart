import 'package:forja/features/stats/router/stats_router.dart';
import 'package:forja/features/stats/view/stats_screen.dart';
import 'package:forja/features/stats/view/weekly_report_screen.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> routes = [
  GoRoute(
    path: StatsRouter.initial,
    name: StatsRouter.name,
    builder: (context, state) => const StatsScreen(),
  ),
  GoRoute(
    path: StatsRouter.weeklyReport,
    name: StatsRouter.weeklyReportName,
    builder: (context, state) => const WeeklyReportScreen(),
  ),
];

import 'package:forja/features/achievements/router/achievements_router.dart';
import 'package:forja/features/achievements/view/achievements_screen.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> routes = [
  GoRoute(
    path: AchievementsRouter.initial,
    name: AchievementsRouter.name,
    builder: (context, state) => const AchievementsScreen(),
  ),
];

import 'package:forja/features/missions/router/missions_router.dart';
import 'package:forja/features/missions/view/missions_screen.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> routes = [
  GoRoute(
    path: MissionsRouter.initial,
    name: MissionsRouter.name,
    builder: (context, state) => const MissionsScreen(),
  ),
];

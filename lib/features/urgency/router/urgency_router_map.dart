import 'package:forja/features/urgency/router/urgency_router.dart';
import 'package:forja/features/urgency/view/urgency_screen.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> routes = [
  GoRoute(
    path: UrgencyRouter.initial,
    name: UrgencyRouter.name,
    builder: (context, state) => const UrgencyScreen(),
  ),
];

import 'package:forja/features/monk_mode/router/monk_mode_router.dart';
import 'package:forja/features/monk_mode/view/monk_mode_screen.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> routes = [
  GoRoute(
    path: MonkModeRouter.initial,
    name: MonkModeRouter.name,
    builder: (context, state) => const MonkModeScreen(),
  ),
];

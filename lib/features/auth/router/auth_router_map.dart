import 'package:forja/features/auth/router/auth_router.dart';
import 'package:forja/features/auth/view/auth_screen.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> routes = [
  GoRoute(
    path: AuthRouter.initial,
    name: AuthRouter.name,
    builder: (context, state) => const AuthScreen(),
  ),
];

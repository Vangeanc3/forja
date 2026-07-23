import 'package:forja/features/splash/router/splash_router.dart';
import 'package:forja/features/splash/view/splash_screen.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> routes({required bool showOnboarding}) => [
  GoRoute(
    path: SplashRouter.initial,
    name: SplashRouter.name,
    builder: (context, state) => SplashScreen(showOnboarding: showOnboarding),
  ),
];

import 'package:forja/features/onboarding/router/onboarding_router.dart';
import 'package:forja/features/onboarding/view/onboarding_screen.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> routes = [
  GoRoute(
    path: OnboardingRouter.initial,
    name: OnboardingRouter.name,
    builder: (context, state) => const OnboardingScreen(),
  ),
];

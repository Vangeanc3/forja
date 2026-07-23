import 'package:forja/features/weekly_challenge/router/weekly_challenge_router.dart';
import 'package:forja/features/weekly_challenge/view/weekly_challenge_screen.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> routes = [
  GoRoute(
    path: WeeklyChallengeRouter.initial,
    name: WeeklyChallengeRouter.name,
    builder: (context, state) => const WeeklyChallengeScreen(),
  ),
];

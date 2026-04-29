import 'package:go_router/go_router.dart';

import '../features/achievements/achievements_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/home/home_screen.dart';
import '../features/missions/missions_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/relapse/relapse_screen.dart';
import 'constants.dart';

GoRouter buildForjaRouter({required bool showOnboarding}) => GoRouter(
      initialLocation:
          showOnboarding ? ForjaRoutes.onboarding : ForjaRoutes.home,
      routes: [
        GoRoute(
          path: ForjaRoutes.onboarding,
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: ForjaRoutes.home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: ForjaRoutes.missions,
          name: 'missions',
          builder: (context, state) => const MissionsScreen(),
        ),
        GoRoute(
          path: ForjaRoutes.relapse,
          name: 'relapse',
          builder: (context, state) => const RelapseScreen(),
        ),
        GoRoute(
          path: ForjaRoutes.achievements,
          name: 'achievements',
          builder: (context, state) => const AchievementsScreen(),
        ),
        GoRoute(
          path: ForjaRoutes.stats,
          name: 'stats',
          builder: (context, state) => const StatsScreen(),
        ),
      ],
    );

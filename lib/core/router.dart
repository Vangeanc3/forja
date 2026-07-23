import 'package:go_router/go_router.dart';

import '../features/achievements/router/achievements_router_map.dart'
    as achievements;
import '../features/auth/router/auth_router_map.dart' as auth;
import '../features/home/router/home_router_map.dart' as home;
import '../features/journal/router/journal_router_map.dart' as journal;
import '../features/missions/router/missions_router_map.dart' as missions;
import '../features/monk_mode/router/monk_mode_router_map.dart' as monk_mode;
import '../features/onboarding/router/onboarding_router_map.dart' as onboarding;
import '../features/profile/router/profile_router_map.dart' as profile;
import '../features/relapse/router/relapse_router_map.dart' as relapse;
import '../features/splash/router/splash_router.dart';
import '../features/splash/router/splash_router_map.dart' as splash;
import '../features/stats/router/stats_router_map.dart' as stats;
import '../features/tasks/router/tasks_router_map.dart' as tasks;
import '../features/urgency/router/urgency_router_map.dart' as urgency;
import '../features/weekly_challenge/router/weekly_challenge_router_map.dart'
    as weekly_challenge;

GoRouter buildForjaRouter({required bool showOnboarding}) => GoRouter(
  initialLocation: SplashRouter.initial,
  routes: [
    ...splash.routes(showOnboarding: showOnboarding),
    ...auth.routes,
    ...onboarding.routes,
    ...home.routes,
    ...missions.routes,
    ...relapse.routes,
    ...achievements.routes,
    ...stats.routes,
    ...journal.routes,
    ...tasks.routes,
    ...urgency.routes,
    ...weekly_challenge.routes,
    ...monk_mode.routes,
    ...profile.routes,
  ],
);

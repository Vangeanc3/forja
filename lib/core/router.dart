import 'package:go_router/go_router.dart';

import '../features/achievements/achievements_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/stats/weekly_report_screen.dart';
import '../features/home/home_screen.dart';
import '../features/missions/missions_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/relapse/relapse_history_screen.dart';
import '../features/journal/journal_screen.dart';
import '../features/urgency/urgency_screen.dart';
import '../features/weekly_challenge/weekly_challenge_screen.dart';
import '../features/monk_mode/monk_mode_screen.dart';
import '../features/profile/support_contact_screen.dart';
import '../features/profile/risk_hours_screen.dart';
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
        GoRoute(
          path: ForjaRoutes.journal,
          name: 'journal',
          builder: (context, state) => const JournalScreen(),
        ),
        GoRoute(
          path: ForjaRoutes.urgency,
          name: 'urgency',
          builder: (context, state) => const UrgencyScreen(),
        ),
        GoRoute(
          path: ForjaRoutes.relapseHistory,
          name: 'relapse-history',
          builder: (context, state) => const RelapseHistoryScreen(),
        ),
        GoRoute(
          path: ForjaRoutes.weeklyChallenge,
          name: 'weekly-challenge',
          builder: (context, state) => const WeeklyChallengeScreen(),
        ),
        GoRoute(
          path: ForjaRoutes.monkMode,
          name: 'monk-mode',
          builder: (context, state) => const MonkModeScreen(),
        ),
        GoRoute(
          path: ForjaRoutes.weeklyReport,
          name: 'weekly-report',
          builder: (context, state) => const WeeklyReportScreen(),
        ),
        GoRoute(
          path: ForjaRoutes.profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: ForjaRoutes.supportContact,
          name: 'support-contact',
          builder: (context, state) => const SupportContactScreen(),
        ),
        GoRoute(
          path: ForjaRoutes.riskHours,
          name: 'risk-hours',
          builder: (context, state) => const RiskHoursScreen(),
        ),
      ],
    );

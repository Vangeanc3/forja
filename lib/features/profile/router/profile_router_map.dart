import 'package:forja/features/profile/router/profile_router.dart';
import 'package:forja/features/profile/view/profile_screen.dart';
import 'package:forja/features/profile/view/risk_hours_screen.dart';
import 'package:forja/features/profile/view/support_contact_screen.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> routes = [
  GoRoute(
    path: ProfileRouter.initial,
    name: ProfileRouter.name,
    builder: (context, state) => const ProfileScreen(),
  ),
  GoRoute(
    path: ProfileRouter.supportContact,
    name: ProfileRouter.supportContactName,
    builder: (context, state) => const SupportContactScreen(),
  ),
  GoRoute(
    path: ProfileRouter.riskHours,
    name: ProfileRouter.riskHoursName,
    builder: (context, state) => const RiskHoursScreen(),
  ),
];

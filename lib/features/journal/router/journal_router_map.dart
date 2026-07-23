import 'package:forja/features/journal/router/journal_router.dart';
import 'package:forja/features/journal/view/journal_screen.dart';
import 'package:go_router/go_router.dart';

List<RouteBase> routes = [
  GoRoute(
    path: JournalRouter.initial,
    name: JournalRouter.name,
    builder: (context, state) => const JournalScreen(),
  ),
];

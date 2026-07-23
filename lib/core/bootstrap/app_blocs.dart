import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/achievements_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/journal_repository.dart';
import '../../data/repositories/missions_repository.dart';
import '../../data/repositories/monk_mode_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/repositories/streak_repository.dart';
import '../../data/repositories/weekly_challenge_repository.dart';
import '../../data/repositories/weekly_report_repository.dart';
import '../../data/services/firebase_sync_service.dart';
import '../../data/services/local_remote_sync_service.dart';
import '../../features/achievements/bloc/achievements_bloc.dart';
import '../../features/achievements/bloc/achievements_event.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/journal/bloc/journal_bloc.dart';
import '../../features/journal/bloc/journal_event.dart';
import '../../features/missions/bloc/missions_bloc.dart';
import '../../features/missions/bloc/missions_event.dart';
import '../../features/monk_mode/bloc/monk_mode_bloc.dart';
import '../../features/monk_mode/bloc/monk_mode_event.dart';
import '../../features/settings/bloc/settings_bloc.dart';
import '../../features/settings/bloc/settings_event.dart';
import '../../features/stats/bloc/stats_bloc.dart';
import '../../features/stats/bloc/stats_event.dart';
import '../../features/stats/bloc/weekly_report_bloc.dart';
import '../../features/stats/bloc/weekly_report_event.dart';
import '../../features/streak/bloc/streak_bloc.dart';
import '../../features/streak/bloc/streak_event.dart';
import '../../features/tasks/bloc/progress_bloc.dart';
import '../../features/tasks/bloc/progress_event.dart';
import '../../features/weekly_challenge/bloc/weekly_challenge_bloc.dart';
import '../../features/weekly_challenge/bloc/weekly_challenge_event.dart';

class ForjaBlocScope extends StatelessWidget {
  const ForjaBlocScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => FirebaseSyncService()),
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(
          create: (context) => SettingsRepository(
            firebaseSync: context.read<FirebaseSyncService>(),
          ),
        ),
        RepositoryProvider(
          create: (context) => StreakRepository(
            firebaseSync: context.read<FirebaseSyncService>(),
          ),
        ),
        RepositoryProvider(
          create: (context) => MissionsRepository(
            firebaseSync: context.read<FirebaseSyncService>(),
          ),
        ),
        RepositoryProvider(
          create: (context) => JournalRepository(
            firebaseSync: context.read<FirebaseSyncService>(),
          ),
        ),
        RepositoryProvider(
          create: (context) => AchievementsRepository(
            firebaseSync: context.read<FirebaseSyncService>(),
          ),
        ),
        RepositoryProvider(
          create: (context) => StatsRepository(
            firebaseSync: context.read<FirebaseSyncService>(),
          ),
        ),
        RepositoryProvider(
          create: (context) => WeeklyReportRepository(
            firebaseSync: context.read<FirebaseSyncService>(),
          ),
        ),
        RepositoryProvider(
          create: (context) => ProgressRepository(
            firebaseSync: context.read<FirebaseSyncService>(),
          ),
        ),
        RepositoryProvider(
          create: (context) => WeeklyChallengeRepository(
            firebaseSync: context.read<FirebaseSyncService>(),
          ),
        ),
        RepositoryProvider(
          create: (context) => MonkModeRepository(
            firebaseSync: context.read<FirebaseSyncService>(),
          ),
        ),
        RepositoryProvider(
          create: (context) => LocalRemoteSyncService(
            firebaseSync: context.read<FirebaseSyncService>(),
            achievements: context.read<AchievementsRepository>(),
            journal: context.read<JournalRepository>(),
            missions: context.read<MissionsRepository>(),
            monkMode: context.read<MonkModeRepository>(),
            progress: context.read<ProgressRepository>(),
            settings: context.read<SettingsRepository>(),
            stats: context.read<StatsRepository>(),
            streak: context.read<StreakRepository>(),
            weeklyChallenge: context.read<WeeklyChallengeRepository>(),
            weeklyReport: context.read<WeeklyReportRepository>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(context.read<AuthRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                SettingsBloc(context.read<SettingsRepository>()),
          ),
          BlocProvider(
            create: (context) => StreakBloc(context.read<StreakRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                MissionsBloc(context.read<MissionsRepository>()),
          ),
          BlocProvider(
            create: (context) => JournalBloc(context.read<JournalRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                AchievementsBloc(context.read<AchievementsRepository>()),
          ),
          BlocProvider(
            create: (context) => StatsBloc(context.read<StatsRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                WeeklyReportBloc(context.read<WeeklyReportRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                ProgressBloc(context.read<ProgressRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                WeeklyChallengeBloc(context.read<WeeklyChallengeRepository>()),
          ),
          BlocProvider(
            create: (context) =>
                MonkModeBloc(context.read<MonkModeRepository>()),
          ),
        ],
        child: _AuthLocalDataSync(child: child),
      ),
    );
  }
}

class _AuthLocalDataSync extends StatefulWidget {
  const _AuthLocalDataSync({required this.child});

  final Widget child;

  @override
  State<_AuthLocalDataSync> createState() => _AuthLocalDataSyncState();
}

class _AuthLocalDataSyncState extends State<_AuthLocalDataSync> {
  String? _lastSyncedUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncIfAuthenticated(context.read<AuthBloc>().state);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.user?.uid != current.user?.uid ||
          !previous.isAuthenticated && current.isAuthenticated,
      listener: (context, state) {
        if (!state.isAuthenticated) {
          _lastSyncedUid = null;
          return;
        }
        _syncIfAuthenticated(state);
      },
      child: widget.child,
    );
  }

  void _syncIfAuthenticated(AuthState state) {
    final uid = state.user?.uid;
    if (!state.isAuthenticated || uid == null || uid == _lastSyncedUid) return;

    _lastSyncedUid = uid;
    unawaited(_syncAndRefresh());
  }

  Future<void> _syncAndRefresh() async {
    try {
      await context.read<LocalRemoteSyncService>().syncAll();
      if (!mounted) return;
      _refreshBlocs();
    } catch (error, stackTrace) {
      debugPrint('Local/remote auth sync failed: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  void _refreshBlocs() {
    context.read<SettingsBloc>().add(const SettingsRefreshed());
    context.read<StreakBloc>().add(const StreakRefreshed());
    context.read<MissionsBloc>().add(const MissionsRefreshed());
    context.read<JournalBloc>().add(const JournalRefreshed());
    context.read<AchievementsBloc>().add(const AchievementsRefreshed());
    context.read<StatsBloc>().add(const StatsRefreshed());
    context.read<WeeklyReportBloc>().add(const WeeklyReportsRefreshed());
    context.read<ProgressBloc>().add(const ProgressRefreshed());
    context.read<WeeklyChallengeBloc>().add(const WeeklyChallengeRefreshed());
    context.read<MonkModeBloc>().add(const MonkModeRefreshed());
  }
}

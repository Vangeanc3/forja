import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/bootstrap/app_blocs.dart';
import 'core/bootstrap/firebase_bootstrap.dart';
import 'core/constants.dart';
import 'core/notification_service.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'data/repositories/settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox(ForjaBoxes.settings),
    Hive.openBox(ForjaBoxes.streak),
    Hive.openBox(ForjaBoxes.missions),
    Hive.openBox(ForjaBoxes.achievements),
    Hive.openBox(ForjaBoxes.stats),
    Hive.openBox(ForjaBoxes.journal),
    Hive.openBox(ForjaBoxes.tasks),
    Hive.openBox(ForjaBoxes.weeklyChallenge),
    Hive.openBox(ForjaBoxes.monkMode),
    Hive.openBox(ForjaBoxes.weeklyReports),
  ]);

  final onboardingDone =
      Hive.box(
            ForjaBoxes.settings,
          ).get(ForjaStorage.onboardingDoneKey, defaultValue: false)
          as bool;

  await NotificationService.init();
  await FirebaseBootstrap.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(ForjaBlocScope(child: ForjaApp(showOnboarding: !onboardingDone)));

  // Reagenda notificações em background sem bloquear o startup visual
  if (onboardingDone) {
    NotificationService.scheduleAll(SettingsRepository().snapshot());
  }
}

class ForjaApp extends StatelessWidget {
  const ForjaApp({super.key, required this.showOnboarding});

  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: ForjaStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: forjaDarkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: buildForjaRouter(showOnboarding: showOnboarding),
    );
  }
}

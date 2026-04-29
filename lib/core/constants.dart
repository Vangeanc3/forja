abstract final class ForjaStrings {
  static const appName = 'Forja';
  static const tagline = 'Forje sua disciplina';
}

abstract final class ForjaRoutes {
  static const home = '/';
  static const onboarding = '/onboarding';
  static const missions = '/missions';
  static const relapse = '/relapse';
  static const achievements = '/achievements';
  static const stats = '/stats';
}

abstract final class ForjaBoxes {
  static const settings = 'settings';
  static const streak = 'streak';
  static const missions = 'missions';
  static const achievements = 'achievements';
  static const stats = 'stats';
}

abstract final class ForjaStorage {
  static const streakStartKey = 'streak_start';
  static const onboardingDoneKey = 'onboarding_done';
  static const userNameKey = 'user_name';
  static const userModeKey = 'user_mode';
}

abstract final class ForjaMode {
  static const nofap = 'nofap';
  static const monk = 'monk';
}

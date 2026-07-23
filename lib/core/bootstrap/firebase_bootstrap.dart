import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

abstract final class FirebaseBootstrap {
  static bool initialized = false;
  static Object? initializationError;

  static Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      initialized = Firebase.apps.isNotEmpty;
      initializationError = null;
    } catch (error, stackTrace) {
      initialized = false;
      initializationError = error;

      debugPrint('Firebase was not initialized: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:msaratwasel_user/src/app/app.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:msaratwasel_user/src/core/utils/logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:msaratwasel_user/src/core/services/notification_service.dart';

Future<void> bootstrap() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  // Hide system navigation buttons (Immersive Mode)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize timeago Arabic locale
  timeago.setLocaleMessages('ar', timeago.ArMessages());

  // 1. Initialize Firebase first (Ensure notification services initialize AFTER Firebase)
  try {
    AppLogger.i('🔥 MsaratWasel: Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        AppLogger.w('⚠️ MsaratWasel: Firebase initialization timed out after 10s');
        return Firebase.app();
      },
    );
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    AppLogger.i('🔥 MsaratWasel: Firebase initialized successfully');
  } catch (e, stack) {
    AppLogger.e('❌ MsaratWasel: Firebase initialization failed: $e', error: e, stackTrace: stack);
  }

  // 2. Set up global Flutter error logging
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.e('Flutter Error: ${details.exception}', error: details.exception, stackTrace: details.stack);
  };

  // 3. Set up Platform Dispatcher async error handling (Async Zone Protection)
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.e('Unhandled Async Error: $error', error: error, stackTrace: stack);
    return true; // Prevent app from crashing
  };

  // Watchdog timer: Force remove splash after 15 seconds silently if nothing else does
  Future.delayed(const Duration(seconds: 15), () {
    try {
      FlutterNativeSplash.remove();
    } catch (_) {}
  });

  // 4. Create AppController (Notification services initialize inside AppController AFTER Firebase)
  AppLogger.i('🏗️ MsaratWasel: Creating AppController...');
  final controller = AppController();

  // 5. Run the app
  AppLogger.i('🚀 MsaratWasel: Calling runApp...');
  runApp(MsaratWaselApp(controller: controller));
}

void main() async {
  await bootstrap();
}

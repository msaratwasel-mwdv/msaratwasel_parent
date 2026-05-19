import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:msaratwasel_user/src/app/app.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:msaratwasel_user/src/core/utils/logger.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Hide system navigation buttons (Immersive Mode)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize timeago Arabic locale
  timeago.setLocaleMessages('ar', timeago.ArMessages());

  // Initialize Sentry
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://8adfbcae8fb55fae2f47c92b23a9d4a8@o4507028168212480.ingest.us.sentry.io/4507038161747968';
      options.tracesSampleRate = 1.0;
      options.attachScreenshot = true;
      options.attachThreads = true;
    },
    appRunner: () async {
      // Handle Flutter errors
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        AppLogger.e('Flutter Error: ${details.exception}', error: details.exception, stackTrace: details.stack);
        // Send error report to Firebase Crashlytics & Sentry
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        Sentry.captureException(details.exception, stackTrace: details.stack);
      };

      // Handle platform/asynchronous errors
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.e('Unhandled Async Error: $error', error: error, stackTrace: stack);
        // Send async error report to Firebase Crashlytics & Sentry
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        Sentry.captureException(error, stackTrace: stack);
        return true; // Prevent app from crashing
      };

      try {
        AppLogger.i('🚀 MsaratWasel: Application starting...');

        // Watchdog timer: Force remove splash after 15 seconds if nothing else does
        Future.delayed(const Duration(seconds: 15), () {
          try {
            AppLogger.w('⏰ MsaratWasel: Startup Watchdog triggered (15s). Forcing splash removal.');
            FlutterNativeSplash.remove();
          } catch (_) {}
        });

        // 1. تهيئة Firebase — ضروري لـ FCM
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
        AppLogger.i('🔥 MsaratWasel: Firebase initialized successfully');

        // 2. إنشاء AppController
        AppLogger.i('🏗️ MsaratWasel: Creating AppController...');
        final controller = AppController();

        AppLogger.i('🚀 MsaratWasel: Widgets initialized. Calling runApp...');
        runApp(MsaratWaselApp(controller: controller));
        AppLogger.i('🚀 MsaratWasel: runApp called successfully');
      } catch (e, stack) {
        AppLogger.e('❌ MsaratWasel: CRITICAL Error during initialization: $e', error: e, stackTrace: stack);
        Sentry.captureException(e, stackTrace: stack);

        // Ensure splash is removed even on error to avoid hang
        try {
          FlutterNativeSplash.remove();
        } catch (_) {}

        // Fallback runApp to stop splash hang
        runApp(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error starting app:\n$e',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    },
  );
}

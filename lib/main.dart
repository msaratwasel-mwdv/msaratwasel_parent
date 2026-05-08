import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:msaratwasel_user/src/app/app.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Hide system navigation buttons (Immersive Mode)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize timeago Arabic locale
  timeago.setLocaleMessages('ar', timeago.ArMessages());

  // Handle Flutter errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log('Flutter Error: ${details.exception}', name: 'ERROR');
  };

  // Handle platform/asynchronous errors
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log(
      'Unhandled Async Error: $error',
      name: 'ERROR',
      stackTrace: stack,
    );
    return true; // Prevent app from crashing
  };

  try {
    print('🚀 MsaratWasel: Application starting...');
    developer.log('🚀 MsaratWasel: Application starting...', name: 'APP_START');

    // Watchdog timer: Force remove splash after 15 seconds if nothing else does
    Future.delayed(const Duration(seconds: 15), () {
      try {
        print(
          '⏰ MsaratWasel: Startup Watchdog triggered (15s). Forcing splash removal.',
        );
        FlutterNativeSplash.remove();
      } catch (_) {}
    });

    // 1. تهيئة Firebase — ضروري لـ FCM
    print('🔥 MsaratWasel: Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('⚠️ MsaratWasel: Firebase initialization timed out after 10s');
        return Firebase.app();
      },
    );
    print('🔥 MsaratWasel: Firebase initialized successfully');

    // 2. إنشاء AppController
    print('🏗️ MsaratWasel: Creating AppController...');
    final controller = AppController();

    print('🚀 MsaratWasel: Widgets initialized. Calling runApp...');
    runApp(MsaratWaselApp(controller: controller));
    print('🚀 MsaratWasel: runApp called successfully');
  } catch (e, stack) {
    print('❌ MsaratWasel: CRITICAL Error during initialization: $e');
    developer.log(
      'CRITICAL Error during initialization: $e',
      name: 'ERROR',
      stackTrace: stack,
    );

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
}

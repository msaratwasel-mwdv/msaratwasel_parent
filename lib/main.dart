import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:msaratwasel_user/src/app/app.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Handle Flutter errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log('Flutter Error: ${details.exception}', name: 'ERROR');
  };

  // Handle platform/asynchronous errors
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log('Unhandled Async Error: $error', name: 'ERROR', stackTrace: stack);
    return true; // Prevent app from crashing
  };

  try {
    print('🚀 MsaratWasel: Application starting...');

    // 1. تهيئة Firebase — ضروري لـ FCM
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    developer.log('🔥 Firebase initialized successfully', name: 'APP_START');

    // Print FCM Token for debugging as requested by the user
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      print("FCM TOKEN: $fcmToken");
      developer.log("FCM TOKEN: $fcmToken", name: 'FCM');
    } catch (e) {
      developer.log("Error getting FCM Token: $e", name: 'FCM');
    }

    // 2. إنشاء AppController (سيتولى تهيئة FCM بعد تسجيل الدخول)
    final controller = AppController();

    developer.log('🚀 MsaratWasel: Widgets initialized', name: 'APP_START');
    runApp(MsaratWaselApp(controller: controller));
    developer.log('🚀 MsaratWasel: runApp called', name: 'APP_START');
  } catch (e, stack) {
    developer.log('CRITICAL Error during initialization: $e', name: 'ERROR', stackTrace: stack);
    
    // Ensure splash is removed even on error to avoid hang
    FlutterNativeSplash.remove();
    
    // Fallback runApp to stop splash hang
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error starting app: $e'),
        ),
      ),
    ));
  }
}

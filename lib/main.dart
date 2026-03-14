import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:msaratwasel_user/src/app/app.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    // 1. تهيئة Firebase — ضروري لـ FCM
    await Firebase.initializeApp();

    // 2. إنشاء AppController (سيتولى تهيئة FCM بعد تسجيل الدخول)
    final controller = AppController();

    developer.log('🚀 MsaratWasel: Widgets initialized', name: 'APP_START');
    runApp(MsaratWaselApp(controller: controller));
    developer.log('🚀 MsaratWasel: runApp called', name: 'APP_START');
  } catch (e, stack) {
    developer.log('Error during initialization: $e', name: 'ERROR', stackTrace: stack);
  }
}

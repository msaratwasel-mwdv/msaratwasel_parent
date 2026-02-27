import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:msaratwasel_user/src/app/app.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'dart:developer' as developer;

void main() async {
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
}

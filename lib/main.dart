import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:msaratwasel_user/src/app/app.dart';
import 'dart:developer' as developer;

void main() {
  developer.log('🚀 MsaratWasel: Application starting...', name: 'APP_START');
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  developer.log('🚀 MsaratWasel: Widgets initialized', name: 'APP_START');
  runApp(const MsaratWaselApp());
  developer.log('🚀 MsaratWasel: runApp called', name: 'APP_START');
}

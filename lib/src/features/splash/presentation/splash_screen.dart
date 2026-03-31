import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleSplash();
  }

  void _handleSplash() async {
    // Keep the splash screen for just a short moment to transition smoothly
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      FlutterNativeSplash.remove();
      // Inform the controller we are done, assuming it waits for splash?
      // Actually standard logic is just to remove native splash, 
      // the controller itself handles routing via isBootCompleted.
      // So this screen will unmount automatically when isBootCompleted.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return a sleek centered logo with navy blue background
    return Scaffold(
      backgroundColor: const Color(0xFF062A5A),
      body: Center(
        child: Image.asset(
          'assets/images/iconApp.png',
          width: 150,
        ),
      ),
    );
  }
}

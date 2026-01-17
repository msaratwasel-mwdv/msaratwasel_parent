import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/animated_background.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Unified Background
          const AnimatedBackground(),

          // 2. Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Animation
                Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/icons/msarticon/icon.png',
                          width: 140,
                          height: 140,
                        ),
                      ),
                    )
                    .animate()
                    .scale(duration: 800.ms, curve: Curves.easeOutBack)
                    .fadeIn(duration: 500.ms)
                    .then()
                    .shimmer(
                      duration: 1500.ms,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),

                const SizedBox(height: 32),

                // Loading Indicator
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.t('loading'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1000.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

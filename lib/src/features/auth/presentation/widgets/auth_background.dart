import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [AppColors.surface, AppColors.surface],
        ),
      ),
      child: Stack(
        children: [
          // Orb 1
          Positioned(
                top: -100,
                right: -100,
                child: _orb(400, isDark ? AppColors.accent : AppColors.primary),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15)),
          // Orb 2
          Positioned(
                bottom: -60,
                left: -60,
                child: _orb(
                  320,
                  isDark ? Colors.blueAccent : Colors.cyanAccent,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(begin: Offset.zero, end: const Offset(30, -30)),
          // Glass blur
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              color: Colors.black.withValues(alpha: isDark ? .25 : .1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withValues(alpha: .4), Colors.transparent],
      ),
    ),
  );
}

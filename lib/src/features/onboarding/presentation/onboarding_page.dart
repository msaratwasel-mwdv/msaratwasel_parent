import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/shared/localization/app_strings.dart';
import 'package:msaratwasel_user/src/shared/presentation/widgets/animated_background.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/widgets/directional_icon.dart';

class OnboardingPage extends StatefulWidget {
  final AppController controller;
  const OnboardingPage({super.key, required this.controller});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    widget.controller.completeOnboarding();
  }

  void _nextPage() {
    if (_currentIndex < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      // Use extendBody: true if using bottomNavigationBar, but we are moving buttons to Stack
      // for better control over transparency and layout.
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    children: [
                      _buildPage(
                        context,
                        title: context.t('onboardingTitle1'),
                        body: context.t('onboardingBody1'),
                        icon: IconlyBold.location,
                        isDark: isDark,
                      ),
                      _buildPage(
                        context,
                        title: context.t('onboardingTitle2'),
                        body: context.t('onboardingBody2'),
                        icon: IconlyBold.notification,
                        isDark: isDark,
                      ),
                      _buildPage(
                        context,
                        title: context.t('onboardingTitle3'),
                        body: context.t('onboardingBody3'),
                        icon: IconlyBold.chat,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                // Page Indicators
                Padding(
                  padding: const EdgeInsets.only(bottom: 100), // Space for buttons
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentIndex == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Buttons (Immersive)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentIndex < 2)
                      TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.8),
                        ),
                        child: Text(
                          context.t('skip'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // High contrast
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentIndex == 2
                                ? context.t('start')
                                : (isRtl ? 'التالي' : 'Next'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_currentIndex < 2) ...[
                            const SizedBox(width: 8),
                            DirectionalIcon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required String title,
    required String body,
    required IconData icon,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    // Glassmorphism styling adaptation
    final glassColor = isDark
        ? const Color(0xFF1E293B).withValues(
            alpha: 0.6,
          ) // Dark blue-grey with opacity
        : Colors.white.withValues(alpha: 0.8);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1) // Subtle border for dark mode
        : Colors.white.withValues(alpha: 0.6);

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.05);

    final iconBgColor = isDark
        ? AppColors.primary.withValues(alpha: 0.3)
        : AppColors.primary.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              decoration: BoxDecoration(
                color: glassColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 64, color: AppColors.primary),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      // Text color handles automatically by theme usually, but we can enforce:
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    body,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

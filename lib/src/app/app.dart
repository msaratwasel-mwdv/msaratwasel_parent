import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/core/utils/logger.dart';
import 'dart:developer' as developer;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:responsive_framework/responsive_framework.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/auth/presentation/login_screen.dart';
import 'package:msaratwasel_user/src/features/dashboard/presentation/root_shell.dart';
import 'package:msaratwasel_user/src/features/onboarding/presentation/onboarding_page.dart';
import 'package:msaratwasel_user/src/shared/theme/app_theme.dart';
import 'package:msaratwasel_user/src/shared/theme/app_colors.dart';
import 'package:msaratwasel_user/src/shared/widgets/offline_banner.dart';

class MsaratWaselApp extends StatefulWidget {
  const MsaratWaselApp({super.key, this.controller});

  /// Optional pre-built controller (e.g. created in main() before runApp).
  /// If null, a fresh instance is created inside the widget.
  final AppController? controller;

  @override
  State<MsaratWaselApp> createState() => _MsaratWaselAppState();
}

class _MsaratWaselAppState extends State<MsaratWaselApp> {
  late final AppController _controller;
  late Locale _currentLocale;
  late ThemeMode _currentThemeMode;

  @override
  void initState() {
    super.initState();
    developer.log('⚡ MsaratWaselApp: initState', name: 'UI');
    _controller = widget.controller ?? AppController();
    _controller.bootstrap();
    _currentLocale = _controller.locale;
    _currentThemeMode = _controller.themeMode;
    _controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    // Only rebuild the root MaterialApp if locale or theme changes
    if (_currentLocale != _controller.locale || _currentThemeMode != _controller.themeMode) {
      setState(() {
        _currentLocale = _controller.locale;
        _currentThemeMode = _controller.themeMode;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('🎨 MsaratWaselApp: building root widget tree', name: 'UI');
    return AppScope(
      controller: _controller,
      child: MaterialApp(
        key: ValueKey(_currentLocale.languageCode),
        navigatorKey: _controller.navigatorKey,
        title: _currentLocale.languageCode == 'ar'
            ? 'مسارات واصل'
            : 'Msarat Wasel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: _currentThemeMode,
        locale: _currentLocale,
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return ResponsiveBreakpoints.builder(
            child: Builder(
              builder: (buildContext) {
                final double currentWidth = MediaQuery.sizeOf(buildContext).width;
                final double currentHeight = MediaQuery.sizeOf(buildContext).height;
                
                // جلب مسافة النظام وفرض حد أدنى بـ 24 بكسل حتماً لحماية أزرار التنقل
                final double systemPadding = MediaQuery.viewPaddingOf(buildContext).bottom;
                final double finalBottomPadding = systemPadding > 0 ? systemPadding : 24.0;
                
                final bool isHeightCompressed = currentHeight < 650;
                final bool isExtremelySmallMobile = currentWidth < 360;
                final bool needsForceScaling = isHeightCompressed || isExtremelySmallMobile;

                    final bool isDark = Theme.of(buildContext).brightness == Brightness.dark;
                    final Color exactScreenColor = isDark ? AppColors.dark.scaffold : AppColors.light.scaffold;

                    return ResponsiveScaledBox(
                      width: needsForceScaling ? 420 : null,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: exactScreenColor,
                    padding: EdgeInsets.only(bottom: finalBottomPadding), // حجز مركزي شامل للمشروع
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                      child: OfflineBannerWrapper(
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  ),
                );
              },
            ),
            breakpoints: [
              const Breakpoint(start: 0, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 900, name: TABLET),
              const Breakpoint(start: 901, end: double.infinity, name: DESKTOP),
            ],
          );
        },
        home: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => _buildHome(),
        ),
      ),
    );
  }

  Widget _buildHome() {
    // Transition State: Bootstrap is still running (showing indicator)
    if (!_controller.isBootCompleted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _controller.locale.languageCode == 'ar'
                    ? 'جاري التحميل...'
                    : 'Loading...',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    AppLogger.d('🚀 app.dart: Switching to RootShell');

    if (_controller.shouldShowOnboarding) {
      return OnboardingPage(controller: _controller);
    }

    if (!_controller.isAuthenticated) {
      return LoginScreen(controller: _controller);
    }

    return _FlushPendingChatWrapper(
      controller: _controller,
      child: const RootShell(),
    );
  }
}

/// Wrapper widget that flushes any queued chat navigation once the
/// navigator is mounted (cold-start scenario).
class _FlushPendingChatWrapper extends StatefulWidget {
  const _FlushPendingChatWrapper({
    required this.controller,
    required this.child,
  });

  final AppController controller;
  final Widget child;

  @override
  State<_FlushPendingChatWrapper> createState() =>
      _FlushPendingChatWrapperState();
}

class _FlushPendingChatWrapperState extends State<_FlushPendingChatWrapper> {
  @override
  void initState() {
    super.initState();
    // Flush after the first frame when the navigator is guaranteed to be mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.flushPendingChatRoute();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

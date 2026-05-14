import 'package:flutter/material.dart';
import 'package:msaratwasel_user/src/core/utils/logger.dart';
import 'dart:developer' as developer;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/auth/presentation/login_screen.dart';
import 'package:msaratwasel_user/src/features/dashboard/presentation/root_shell.dart';
import 'package:msaratwasel_user/src/features/onboarding/presentation/onboarding_page.dart';
import 'package:msaratwasel_user/src/shared/theme/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
    developer.log('⚡ MsaratWaselApp: initState', name: 'UI');
    // Use the externally provided controller (wired to OneSignal in main),
    // or fall back to creating a new one.
    _controller = widget.controller ?? AppController();
    _controller.bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    developer.log('🎨 MsaratWaselApp: building root widget tree', name: 'UI');
    return AppScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final locale = _controller.locale;
          final themeMode = _controller.themeMode;

          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp(
                navigatorKey: _controller.navigatorKey,
                title: locale.languageCode == 'ar'
                    ? 'مسارات واصل'
                    : 'Msarat Wasel',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                locale: locale,
                supportedLocales: const [Locale('ar'), Locale('en')],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (context, child) => GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: OfflineBannerWrapper(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
                home: _buildHome(),
              );
            },
          );
        },
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

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/features/auth/presentation/login_screen.dart';
import 'package:msaratwasel_user/src/features/dashboard/presentation/root_shell.dart';
import 'package:msaratwasel_user/src/features/splash/presentation/splash_screen.dart';
import 'package:msaratwasel_user/src/shared/theme/app_theme.dart';

class MsaratWaselApp extends StatefulWidget {
  const MsaratWaselApp({super.key});

  @override
  State<MsaratWaselApp> createState() => _MsaratWaselAppState();
}

class _MsaratWaselAppState extends State<MsaratWaselApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
    _controller.bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final locale = _controller.locale;
          final themeMode = _controller.themeMode;

          return MaterialApp(
            title: locale.languageCode == 'ar' ? 'مسارات واصل' : 'Msarat Wasel',
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
              child: child ?? const SizedBox.shrink(),
            ),
            home: _buildHome(),
          );
        },
      ),
    );
  }

  Widget _buildHome() {
    if (!_controller.isBootCompleted) {
      return SplashScreen(controller: _controller);
    }

    if (!_controller.isAuthenticated) {
      return LoginScreen(controller: _controller);
    }

    return const RootShell();
  }
}

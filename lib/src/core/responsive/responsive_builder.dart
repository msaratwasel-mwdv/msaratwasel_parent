import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'api_language_interceptor.dart';

/// [ResponsiveBuilder] هو المحرك الأساسي للتبديل بين الواجهات.
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget? desktop;
  final bool useSafeArea;
  final double tabletBreakpoint;
  final double desktopBreakpoint;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    required this.tablet,
    this.desktop,
    this.useSafeArea = true,
    this.tabletBreakpoint = 451.0,
    this.desktopBreakpoint = 801.0,
  });

  /// ميزة مزامنة اللغة مع الـ API (Dio Interceptor) بدون Context
  static Interceptor apiLanguageInterceptor() {
    return ApiLanguageInterceptor();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    Widget currentWidget;
    if (width >= desktopBreakpoint && desktop != null) {
      currentWidget = desktop!;
    } else if (width >= tabletBreakpoint) {
      currentWidget = tablet;
    } else {
      currentWidget = mobile;
    }

    return useSafeArea ? SafeArea(child: currentWidget) : currentWidget;
  }
}

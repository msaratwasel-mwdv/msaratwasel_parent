import 'dart:ui' as ui;
import 'package:dio/dio.dart';

/// [ApiLanguageInterceptor] هو محول برمجي (Interceptor) لمكتبة Dio.
/// يقوم بجلب اللغة الحالية للنظام مباشرة بدون أي [BuildContext] وحقنها في الـ Headers
/// لكل طلب API لضمان مزامنة اللغة الآمنة وتجنب تسريبات الذاكرة (Memory Leaks).
class ApiLanguageInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // جلب كود اللغة الحالي من النظام مباشرة
    final String systemLocale = ui.PlatformDispatcher.instance.locale.languageCode;
    
    // حقن اللغة في الـ Header القياسي 'Accept-Language'
    options.headers['Accept-Language'] = systemLocale;
    options.headers['Accept'] = 'application/json';
    
    return handler.next(options);
  }
}

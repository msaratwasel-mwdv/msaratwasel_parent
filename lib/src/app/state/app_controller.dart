import 'package:flutter/material.dart';

import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// FCM token registration — see _registerFcmToken below
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_user/src/core/config/app_config.dart';
import 'package:msaratwasel_user/src/core/data/sample_data.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:msaratwasel_user/src/core/services/notification_service.dart';

class AppController extends ChangeNotifier {
  AppController()
    : _students = SampleData.students,
      _tracking = Map.of(SampleData.tracking),
      _notifications = [],
      _messages = SampleData.messages,
      _attendance = List.of(SampleData.attendance),
      _trips = List.of(SampleData.trips) {
    developer.log('🏗️ AppController: Instance created', name: 'STATE');
  }

  Locale _locale = () {
    try {
      final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
      final systemLocale = platformDispatcher.locale;
      if (systemLocale.languageCode == 'en') return const Locale('en');
      // Default to Arabic for 'ar' or any other language
      return const Locale('ar');
    } catch (_) {
      return const Locale('ar');
    }
  }();
  ThemeMode _themeMode = ThemeMode.system;
  int _navIndex = 0;
  int _selectedStudentIndex = 0;
  bool _isAuthenticated = false;
  bool _bootCompleted = false;
  bool _shouldShowOnboarding = false;

  // Current user data — populated from API after login
  String _userName = '';
  String _userNameEn = '';
  String _userAvatarUrl = '';

  final List<Student> _students;
  final Map<String, TrackingSnapshot> _tracking;
  final List<AppNotification> _notifications; // mutable — fed by FCM & API
  final List<MessageItem> _messages;
  final List<AttendanceEntry> _attendance;
  final List<TripEntry> _trips;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  int get navIndex => _navIndex;
  bool get isAuthenticated => _isAuthenticated;
  bool get isBootCompleted => _bootCompleted;
  bool get shouldShowOnboarding => _shouldShowOnboarding;
  List<Student> get students => List.unmodifiable(_students);
  Student get currentStudent => _students[_selectedStudentIndex];
  TrackingSnapshot get currentTracking => _tracking[currentStudent.id]!;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<MessageItem> get messages => List.unmodifiable(_messages);
  List<AttendanceEntry> get attendance => List.unmodifiable(_attendance);
  List<TripEntry> get trips => List.unmodifiable(_trips);

  // User data getters
  String get userName => _locale.languageCode == 'ar' ? _userName : _userNameEn;
  String get userAvatarUrl => _userAvatarUrl;

  TrackingSnapshot trackingForStudent(String studentId) {
    return _tracking[studentId] ?? _tracking.values.first;
  }

  void setNavIndex(int index) {
    _navIndex = index;
    notifyListeners();
  }

  Future<void> bootstrap() async {
    try {
      // Simulate loading configuration, cached session, etc.
      await Future.delayed(const Duration(seconds: 4));

      final prefs = await SharedPreferences.getInstance();
      
      // 1. Check onboarding
      final hasSeen = prefs.getBool('has_seen_onboarding') ?? false;
      _shouldShowOnboarding = !hasSeen;

      // 2. Check Authentication
      final token = prefs.getString('auth_token');
      final savedName = prefs.getString('user_name') ?? '';
      if (token != null && savedName.isNotEmpty) {
        _isAuthenticated = true;
        _userName = savedName;
        _userNameEn = savedName;
        developer.log('🔐 AppController: Token found → Auto Login ($savedName)', name: 'AUTH');
        
        // Initialize FCM if already logged in
        final fcmToken = await NotificationService.init(
          onNotificationReceived: addNotification,
        );
        
        // Re-register FCM token just in case it changed
        if (fcmToken != null) {
          final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
          await _registerFcmToken(dio: dio, token: token, fcmToken: fcmToken);
        }
        
        // Load history
        loadNotificationsFromApi();
      } else {
        // No valid session — force login
        _isAuthenticated = false;
        await prefs.remove('auth_token');
        developer.log('🔐 AppController: No saved session → Show Login', name: 'AUTH');
      }

      _bootCompleted = true;
      print('🏁 AppController: Bootstrap completed. Onboarding needed: $_shouldShowOnboarding | Authenticated: $_isAuthenticated');
    } catch (e, st) {
      developer.log(
        '❌ AppController: Bootstrap failed',
        name: 'BOOT',
        error: e,
        stackTrace: st,
      );
      // Fallback to allow app entry (or handle error state appropriately)
      _bootCompleted = true;
    } finally {
      // Native splash is removed in SplashScreen to ensure continuity
      developer.log(
        '✨ AppController: Bootstrap sequence finished',
        name: 'BOOT',
      );
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    _shouldShowOnboarding = false;
    notifyListeners();
  }

  Future<bool> login({
    required String civilId,
    required String password,
  }) async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.defaultTimeout,
          receiveTimeout: AppConfig.defaultTimeout,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      // تسجيل الدخول عبر الـ API باستخدام الرقم المدني ورقم الجوال
      final loginData = {
        'national_id': civilId.trim(),
        'password': password.trim(),
        'device_name': 'flutter_parent_app',
      };
      developer.log('🔐 LOGIN URL  => ${AppConfig.apiBaseUrl}/api/auth/login', name: 'AUTH');
      developer.log('🔐 LOGIN BODY => $loginData', name: 'AUTH');
      final response = await dio.post('/api/auth/login', data: loginData);
      developer.log('🔐 LOGIN STATUS => ${response.statusCode}', name: 'AUTH');
      developer.log('🔐 LOGIN DATA   => ${response.data}', name: 'AUTH');

      final token = response.data['token'] as String?;
      if (token == null) return false;

      // استخراج اسم المستخدم من استجابة الـ API
      final userData = response.data['data']?['user'] ?? response.data['user'];
      final name = userData?['name'] as String? ?? '';
      _userName = name;
      _userNameEn = name;
      developer.log('👤 Logged in as: $name', name: 'AUTH');

      // حفظ التوكن والاسم محلياً
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_name', name);

      // تسجيل FCM Token في الـ backend حتى تصل إشعارات Push
      final fcmToken = await NotificationService.init(
        onNotificationReceived: addNotification,
      );
      if (fcmToken != null) {
        await _registerFcmToken(dio: dio, token: token, fcmToken: fcmToken);
      }

      _isAuthenticated = true;
      _bootCompleted = true;
      _navIndex = 0;
      notifyListeners();
      return true;
    } on DioException catch (e, st) {
      developer.log(
        '❌ LOGIN ERROR => ${e.response?.statusCode} | ${e.response?.data}',
        name: 'AUTH',
        error: e,
        stackTrace: st,
      );
      return false;
    } catch (e) {
      developer.log('❌ LOGIN UNEXPECTED => $e', name: 'AUTH');
      return false;
    }
  }

  /// يرسل FCM Token للـ backend بعد تسجيل الدخول.
  Future<void> _registerFcmToken({
    required Dio dio,
    required String token,
    required String fcmToken,
  }) async {
    try {
      await dio.post(
        '/api/auth/fcm-token',
        data: {'fcm_token': fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      developer.log('✅ FCM: token registered → $fcmToken', name: 'FCM');
    } catch (e) {
      developer.log('⚠️ FCM: failed to register token: $e', name: 'FCM');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    _isAuthenticated = false;
    _userName = '';
    _userNameEn = '';
    _navIndex = 0;
    notifyListeners();
  }

  void toggleLanguage() {
    _locale = _locale.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    notifyListeners();
  }

  void toggleTheme(bool currentIsDark) {
    _themeMode = currentIsDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  void selectStudent(int index) {
    if (index < 0 || index >= _students.length) return;
    _selectedStudentIndex = index;
    notifyListeners();
  }

  void markNotificationsRead([List<String>? ids]) {
    for (final item in _notifications) {
      if (ids == null || ids.contains(item.id)) {
        item.read = true;
      }
    }
    notifyListeners();
  }

  /// Called by [NotificationService] whenever an FCM push arrives.
  void addNotification(AppNotification notification) {
    // Avoid duplicates (can happen if the tap callback fires twice)
    final exists = _notifications.any((n) => n.id == notification.id);
    if (!exists) {
      _notifications.insert(0, notification);
      notifyListeners();
      developer.log(
        '🔔 AppController: notification added — type: ${notification.type}',
        name: 'NOTIFICATION',
      );
    }
  }

  /// Fetches the notification history from the Laravel API on app boot.
  Future<void> loadNotificationsFromApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        developer.log('⚠️ AppController: no token found to load notifications', name: 'NOTIFICATION');
        return;
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.defaultTimeout,
          receiveTimeout: AppConfig.defaultTimeout,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final repo = NotificationRepositoryImpl(dio: dio);
      final fetched = await repo.fetchNotifications();

      // Prepend fetched items, keeping any push-delivered ones already present
      final existingIds = _notifications.map((n) => n.id).toSet();
      final newOnes = fetched.where((n) => !existingIds.contains(n.id));
      _notifications.addAll(newOnes);
      _notifications.sort((a, b) => b.time.compareTo(a.time));

      notifyListeners();
      print('📋 AppController: loaded ${fetched.length} notifications from API');
    } catch (e, st) {
      developer.log(
        '⚠️ AppController: failed to load notifications from API',
        name: 'NOTIFICATION',
        error: e,
        stackTrace: st,
      );
      // Swallow error — app works with push-only notifications
    }
  }

  void addMessage(String text, {String? mediaUrl}) {
    if (text.trim().isEmpty && mediaUrl == null) return;
    _messages.add(
      MessageItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'أنت',
        text: text.trim(),
        time: DateTime.now(),
        incoming: false,
        mediaUrl: mediaUrl,
      ),
    );
    notifyListeners();
  }

  void addAbsence({
    required AttendanceDirection direction,
    required DateTime date,
    String? note,
  }) {
    _attendance.add(
      AttendanceEntry(
        date: date,
        direction: direction,
        status: 'تم الإبلاغ بعدم الذهاب',
        note: note,
      ),
    );
    notifyListeners();
  }

  void updateStudentLocation(
    String studentId,
    LatLng location, {
    String? note,
  }) {
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      final student = _students[index];
      _students[index] = Student(
        id: student.id,
        name: student.name,
        grade: student.grade,
        schoolId: student.schoolId,
        bus: student.bus,
        status: student.status,
        avatarUrl: student.avatarUrl,
        homeLocation: location,
        locationNote: note ?? student.locationNote,
      );
      notifyListeners();
    }
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!.notifier!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => notifier != oldWidget.notifier;
}

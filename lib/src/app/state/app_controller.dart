import 'package:flutter/material.dart';

import 'dart:developer' as developer;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_user/src/core/data/sample_data.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';

class AppController extends ChangeNotifier {
  AppController()
    : _students = SampleData.students,
      _tracking = Map.of(SampleData.tracking),
      _notifications = SampleData.notifications(),
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

  // Current user data (mock data - replace with API data in production)
  String _userName = 'عبدالله الأحمد';
  String _userNameEn = 'Abdullah Al-Ahmad';
  String _userAvatarUrl =
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400';

  final List<Student> _students;
  final Map<String, TrackingSnapshot> _tracking;
  final List<AppNotification> _notifications;
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
      // Playing video for 4 seconds (from 4s to 8s)
      await Future.delayed(const Duration(seconds: 4));

      final prefs = await SharedPreferences.getInstance();
      // If the key is NOT present, it means it's the first time.
      // Or we can explicitly check constraints.
      // For now: if 'has_seen_onboarding' is absent or false, show onboarding.
      final hasSeen = prefs.getBool('has_seen_onboarding') ?? false;
      _shouldShowOnboarding = !hasSeen;

      _bootCompleted = true;
      developer.log(
        '🏁 AppController: Bootstrap completed. Onboarding needed: $_shouldShowOnboarding',
        name: 'BOOT',
      );
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
    required String phoneNumber,
  }) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 900));

    _isAuthenticated = true;
    _bootCompleted = true;
    _navIndex = 0;
    notifyListeners();
    return _isAuthenticated;
  }

  void logout() {
    _isAuthenticated = false;
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

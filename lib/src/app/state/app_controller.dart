import 'package:flutter/material.dart';

import 'dart:developer' as developer;
import 'package:flutter_native_splash/flutter_native_splash.dart';
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

  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.system;
  int _navIndex = 0;
  int _selectedStudentIndex = 0;
  bool _isAuthenticated = false;
  bool _bootCompleted = false;

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
  List<Student> get students => List.unmodifiable(_students);
  Student get currentStudent => _students[_selectedStudentIndex];
  TrackingSnapshot get currentTracking => _tracking[currentStudent.id]!;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<MessageItem> get messages => List.unmodifiable(_messages);
  List<AttendanceEntry> get attendance => List.unmodifiable(_attendance);
  List<TripEntry> get trips => List.unmodifiable(_trips);

  TrackingSnapshot trackingForStudent(String studentId) {
    return _tracking[studentId] ?? _tracking.values.first;
  }

  void setNavIndex(int index) {
    _navIndex = index;
    notifyListeners();
  }

  Future<void> bootstrap() async {
    developer.log('🎬 AppController: Starting bootstrap...', name: 'BOOT');
    // Simulate loading configuration, cached session, etc.
    await Future.delayed(const Duration(seconds: 1));

    _bootCompleted = true;
    developer.log('🏁 AppController: Bootstrap completed', name: 'BOOT');

    // Remove native splash screen if it exists
    FlutterNativeSplash.remove();
    developer.log('✨ AppController: Native splash removed', name: 'BOOT');

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

  void addMessage(String text) {
    if (text.trim().isEmpty) return;
    _messages.add(
      MessageItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: 'أنت',
        text: text.trim(),
        time: DateTime.now(),
        incoming: false,
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

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import 'package:msaratwasel_user/src/core/data/sample_data.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';

class AppState {
  const AppState({
    required this.locale,
    required this.themeMode,
    required this.isAuthenticated,
    required this.isBootCompleted,
    required this.navIndex,
    required this.selectedStudentIndex,
    required this.students,
    required this.tracking,
    required this.notifications,
    required this.messages,
    required this.attendance,
    required this.trips,
  });

  factory AppState.initial() {
    return AppState(
      locale: const Locale('ar'),
      themeMode: ThemeMode.system,
      isAuthenticated: false,
      isBootCompleted: false,
      navIndex: 0,
      selectedStudentIndex: 0,
      students: List.unmodifiable(SampleData.students),
      tracking: Map.unmodifiable(SampleData.tracking),
      notifications: List.unmodifiable(SampleData.notifications()),
      messages: List.unmodifiable(SampleData.messages),
      attendance: List.unmodifiable(SampleData.attendance),
      trips: List.unmodifiable(SampleData.trips),
    );
  }

  final Locale locale;
  final ThemeMode themeMode;
  final bool isAuthenticated;
  final bool isBootCompleted;
  final int navIndex;
  final int selectedStudentIndex;
  final List<Student> students;
  final Map<String, TrackingSnapshot> tracking;
  final List<AppNotification> notifications;
  final List<MessageItem> messages;
  final List<AttendanceEntry> attendance;
  final List<TripEntry> trips;

  Student get currentStudent =>
      students[selectedStudentIndex.clamp(0, students.length - 1)];

  TrackingSnapshot? get currentTracking => tracking[currentStudent.id];

  AppState copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    bool? isAuthenticated,
    bool? isBootCompleted,
    int? navIndex,
    int? selectedStudentIndex,
    List<Student>? students,
    Map<String, TrackingSnapshot>? tracking,
    List<AppNotification>? notifications,
    List<MessageItem>? messages,
    List<AttendanceEntry>? attendance,
    List<TripEntry>? trips,
  }) {
    return AppState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isBootCompleted: isBootCompleted ?? this.isBootCompleted,
      navIndex: navIndex ?? this.navIndex,
      selectedStudentIndex: selectedStudentIndex ?? this.selectedStudentIndex,
      students: students ?? this.students,
      tracking: tracking ?? this.tracking,
      notifications: notifications ?? this.notifications,
      messages: messages ?? this.messages,
      attendance: attendance ?? this.attendance,
      trips: trips ?? this.trips,
    );
  }
}

sealed class AppEvent {
  const AppEvent();
}

class AppStarted extends AppEvent {
  const AppStarted();
}

class AppLoginRequested extends AppEvent {
  const AppLoginRequested({required this.civilId, required this.phoneNumber});
  final String civilId;
  final String phoneNumber;
}

class AppLogoutRequested extends AppEvent {
  const AppLogoutRequested();
}

class AppNavIndexChanged extends AppEvent {
  const AppNavIndexChanged(this.index);
  final int index;
}

class AppLocaleChanged extends AppEvent {
  const AppLocaleChanged(this.locale);
  final Locale locale;
}

class AppThemeToggled extends AppEvent {
  const AppThemeToggled();
}

class AppStudentSelected extends AppEvent {
  const AppStudentSelected(this.index);
  final int index;
}

class AppNotificationsMarked extends AppEvent {
  const AppNotificationsMarked({this.ids});
  final List<String>? ids;
}

class AppMessageSent extends AppEvent {
  const AppMessageSent(this.text);
  final String text;
}

class AppAbsenceReported extends AppEvent {
  const AppAbsenceReported({
    required this.direction,
    required this.date,
    this.note,
  });

  final AttendanceDirection direction;
  final DateTime date;
  final String? note;
}

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(AppState.initial()) {
    on<AppStarted>(_onStarted);
    on<AppLoginRequested>(_onLoginRequested);
    on<AppLogoutRequested>(_onLogoutRequested);
    on<AppNavIndexChanged>(_onNavIndexChanged);
    on<AppLocaleChanged>(_onLocaleChanged);
    on<AppThemeToggled>(_onThemeToggled);
    on<AppStudentSelected>(_onStudentSelected);
    on<AppNotificationsMarked>(_onNotificationsMarked);
    on<AppMessageSent>(_onMessageSent);
    on<AppAbsenceReported>(_onAbsenceReported);
  }

  Future<void> _onStarted(AppStarted event, Emitter<AppState> emit) async {
    emit(state.copyWith(isBootCompleted: false));
    await Future.delayed(const Duration(seconds: 1));
    emit(state.copyWith(isBootCompleted: true));
  }

  Future<void> _onLoginRequested(
    AppLoginRequested event,
    Emitter<AppState> emit,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));
    emit(
      state.copyWith(isAuthenticated: true, isBootCompleted: true, navIndex: 0),
    );
  }

  void _onLogoutRequested(AppLogoutRequested event, Emitter<AppState> emit) {
    emit(state.copyWith(isAuthenticated: false, navIndex: 0));
  }

  void _onNavIndexChanged(AppNavIndexChanged event, Emitter<AppState> emit) {
    emit(state.copyWith(navIndex: event.index.clamp(0, 7)));
  }

  void _onLocaleChanged(AppLocaleChanged event, Emitter<AppState> emit) {
    emit(state.copyWith(locale: event.locale));
  }

  void _onThemeToggled(AppThemeToggled event, Emitter<AppState> emit) {
    final nextTheme = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    emit(state.copyWith(themeMode: nextTheme));
  }

  void _onStudentSelected(AppStudentSelected event, Emitter<AppState> emit) {
    final idx = event.index.clamp(0, state.students.length - 1);
    emit(state.copyWith(selectedStudentIndex: idx));
  }

  void _onNotificationsMarked(
    AppNotificationsMarked event,
    Emitter<AppState> emit,
  ) {
    final ids = event.ids;
    final updated = state.notifications
        .map(
          (item) => _copyNotification(
            item,
            read: ids == null ? true : ids.contains(item.id) || item.read,
          ),
        )
        .toList(growable: false);
    emit(state.copyWith(notifications: List.unmodifiable(updated)));
  }

  void _onMessageSent(AppMessageSent event, Emitter<AppState> emit) {
    final text = event.text.trim();
    if (text.isEmpty) return;
    final newMessage = MessageItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'أنت',
      text: text,
      time: DateTime.now(),
      incoming: false,
    );
    emit(
      state.copyWith(
        messages: List.unmodifiable([...state.messages, newMessage]),
      ),
    );
  }

  void _onAbsenceReported(AppAbsenceReported event, Emitter<AppState> emit) {
    final entry = AttendanceEntry(
      date: event.date,
      direction: event.direction,
      status: 'تم الإبلاغ بعدم الذهاب',
      note: event.note,
    );
    emit(
      state.copyWith(
        attendance: List.unmodifiable([...state.attendance, entry]),
      ),
    );
  }

  AppNotification _copyNotification(AppNotification item, {bool? read}) {
    return AppNotification(
      id: item.id,
      title: item.title,
      body: item.body,
      type: item.type,
      time: item.time,
      read: read ?? item.read,
    );
  }
}

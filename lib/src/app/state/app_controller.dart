import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// FCM token registration — see _registerFcmToken below
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msaratwasel_user/src/core/config/app_config.dart';
import 'package:msaratwasel_user/src/core/data/sample_data.dart';
import 'package:msaratwasel_user/src/core/storage/storage_service.dart';
import 'package:msaratwasel_user/src/core/utils/logger.dart';
import 'package:msaratwasel_user/src/features/language/data/repositories/language_repository_impl.dart';
import 'package:msaratwasel_user/src/features/absence/domain/entities/absence_request.dart';
import 'package:msaratwasel_user/src/features/absence/data/repositories/absence_repository_impl.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/core/services/reverb_service.dart';
import 'package:msaratwasel_user/src/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:msaratwasel_user/src/core/services/notification_service.dart';

class AppController extends ChangeNotifier {
  AppController()
    : _students = [],
      _tracking = Map.of(SampleData.tracking),
      _notifications = [],
      _messages = SampleData.messages,
      _attendance = List.of(SampleData.attendance),
      _trips = List.of(SampleData.trips) {
    AppLogger.i('🏗️ AppController: Instance created');
    _initDio();
  }

  late final Dio dio;
  final StorageService _storage = StorageService();

  void _initDio() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.defaultTimeout,
        receiveTimeout: AppConfig.defaultTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          } else {
            // Try to get from secure storage if not in memory
            final savedToken = await _storage.readAccessToken();
            if (savedToken != null && savedToken.isNotEmpty) {
              _token = savedToken;
              options.headers['Authorization'] = 'Bearer $savedToken';
            }
          }
          return handler.next(options);
        },
        onError: (e, handler) {
          if (e.response?.statusCode == 401) {
            final isBroadcasting = e.requestOptions.path.contains('broadcasting/auth');
            if (isBroadcasting) {
              AppLogger.w('⚠️ Reverb Auth 401: Laravel broadcasting route unauthenticated / middleware issue.');
            } else {
              AppLogger.w('⚠️ API 401: Token expired or invalid');
              _isAuthenticated = false;
              notifyListeners();
            }
          }
          return handler.next(e);
        },
      ),
    );

    // Add logger if needed (already handled by Interceptor check in task.md)
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
  final List<int> _navHistory = [0];
  int _selectedStudentIndex = 0;
  bool _isAuthenticated = false;
  bool _bootCompleted = false;
  bool _shouldShowOnboarding = false;

  // Current user data — populated from API after login
  String _userName = '';
  String _userNameEn = '';
  String _userAvatarUrl = '';
  String _userPhone = '';
  String _userEmail = '';
  String _userNationalId = '';

  List<Student> _students;
  final Map<String, TrackingSnapshot> _tracking;
  final List<AppNotification> _notifications; // mutable — fed by FCM & API
  final List<MessageItem> _messages;
  bool _hasNewMessages = false;

  bool get hasNewMessages => _hasNewMessages;

  void clearNewMessages() {
    _hasNewMessages = false;
    notifyListeners();
  }

  final List<AttendanceEntry> _attendance;
  final List<TripEntry> _trips;
  List<AbsenceRequest> _absenceRequests = [];
  bool _isLoadingChildren = false;
  int? _userId;
  ReverbService? _reverbService;
  String _token = '';

  Locale get locale => _locale;
  String get token => _token;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  int get navIndex => _navIndex;
  bool get isAuthenticated => _isAuthenticated;
  bool get isBootCompleted => _bootCompleted;
  bool get shouldShowOnboarding => _shouldShowOnboarding;
  List<Student> get students => List.unmodifiable(_students);
  Student? get currentStudent =>
      _students.isNotEmpty ? _students[_selectedStudentIndex] : null;
  TrackingSnapshot? get currentTracking =>
      _students.isNotEmpty ? _tracking[currentStudent!.id] : null;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<MessageItem> get messages => List.unmodifiable(_messages);
  List<AttendanceEntry> get attendance => List.unmodifiable(_attendance);
  List<TripEntry> get trips => List.unmodifiable(_trips);
  List<AbsenceRequest> get absenceRequests =>
      List.unmodifiable(_absenceRequests);

  // User data getters
  String get userName => _locale.languageCode == 'ar'
      ? _userName
      : (_userNameEn.isNotEmpty ? _userNameEn : _userName);
  String get userNameAr => _userName;
  String get userNameEn => _userNameEn;
  String get userAvatarUrl => _userAvatarUrl;

  void updateLocale(Locale newLocale) async {
    _locale = newLocale;
    notifyListeners();
    // Persist to storage
    final repo = LanguageRepositoryImpl(storageService: StorageService());
    await repo.setLocale(newLocale.languageCode);
  }

  Future<({bool success, String? message})> submitAbsence({
    required String studentId,
    required String period,
    required String reason,
    required String note,
  }) async {
    try {
      final repo = AbsenceRepositoryImpl(dio: dio);

      // Period mapping: full_day, morning, afternoon
      final absenceType = period == 'morning'
          ? AbsenceType.morning
          : (period == 'afternoon' ? AbsenceType.returnOnly : AbsenceType.both);

      final request = AbsenceRequest(
        studentIds: [studentId],
        type: absenceType,
        date: DateTime.now(),
        note: '$reason: $note',
      );

      await repo.submitAbsence(request);
      loadChildrenFromApi();
      return (success: true, message: null);
    } on DioException catch (e) {
      String? errorMessage;
      if (e.response?.data is Map) {
        errorMessage = e.response?.data['message'];
      }
      return (success: false, message: errorMessage);
    } catch (e) {
      AppLogger.d('❌ submitAbsence failed: $e');
      return (success: false, message: e.toString());
    }
  }

  String get userPhone => _userPhone;
  String get userEmail => _userEmail;
  String get userNationalId => _userNationalId;
  bool get isLoadingChildren => _isLoadingChildren;

  TrackingSnapshot trackingForStudent(String studentId) {
    return _tracking[studentId] ?? _tracking.values.first;
  }

  void setNavIndex(int index) {
    if (_navIndex == index) return;
    _navIndex = index;
    _navHistory.add(index);
    if (_navHistory.length > 20) _navHistory.removeAt(0); // Limit history size
    notifyListeners();
  }

  void moveBack() {
    if (_navHistory.length > 1) {
      _navHistory.removeLast(); // Remove current
      _navIndex = _navHistory.last; // Set to previous
      notifyListeners();
    } else if (_navIndex != 0) {
      _navIndex = 0;
      _navHistory.clear();
      _navHistory.add(0);
      notifyListeners();
    }
  }

  /// تحميل أبناء ولي الأمر الحقيقيين من الـ API
  Future<void> loadChildrenFromApi() async {
    if (_isLoadingChildren) return;
    try {
      _isLoadingChildren = true;
      final prefs = await _storage.prefs;
      final token = await _storage.readAccessToken();
      if (token == null) {
        AppLogger.d('⚠️ loadChildrenFromApi: token is NULL — skipping');
        return;
      }
      AppLogger.d('👶 loadChildrenFromApi: calling /parent/children...');

      final response = await dio.get('parent/children');
      print(
        '👶 Children API => ${response.statusCode} | body: ${response.data}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> rawList = response.data['data'] as List<dynamic>;
        _students = rawList
            .map((e) => Student.fromJson(e as Map<String, dynamic>))
            .toList();

        // 🚌 الاشتراك في قنوات الباصات للأبناء لتتبع مواقعهم لحظياً
        for (var student in _students) {
          if (student.bus.id.isNotEmpty) {
            _reverbService?.subscribe('private-bus.${student.bus.id}');
          }
        }

        // LOAD PERSISTED TIMESTAMPS FOR TODAY
        final todayStr =
            "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
        for (int i = 0; i < _students.length; i++) {
          final sid = _students[i].id;
          _students[i] = _students[i].copyWith(
            waitingAtHomeTime: _parseTime(
              prefs.getString('ts_${sid}_waitingAtHome_$todayStr'),
            ),
            onBusToSchoolTime: _parseTime(
              prefs.getString('ts_${sid}_onBusToSchool_$todayStr'),
            ),
            atSchoolTime: _parseTime(
              prefs.getString('ts_${sid}_atSchool_$todayStr'),
            ),
            onBusToHomeTime: _parseTime(
              prefs.getString('ts_${sid}_onBusToHome_$todayStr'),
            ),
            arrivedHomeTime: _parseTime(
              prefs.getString('ts_${sid}_arrivedHome_$todayStr'),
            ),
          );
        }

        // Initialize tracking snapshots for real students
        for (final student in _students) {
          final busData =
              (rawList.firstWhere((e) => e['id'].toString() == student.id)
                  as Map<String, dynamic>)['bus'];
          final driverData = busData != null ? busData['driver'] : null;

          if (!_tracking.containsKey(student.id)) {
            _tracking[student.id] = TrackingSnapshot(
              lat: 24.7136,
              lng: 46.6753,
              speedKmh: 0,
              etaMinutes: 0,
              distanceKm: 0,
              studentsOnBoard: 0,
              busState:
                  (student.status == StudentStatus.onBus ||
                      student.status == StudentStatus.onBusToSchool ||
                      student.status == StudentStatus.onBusToHome)
                  ? BusState.enRoute
                  : (student.status == StudentStatus.atSchool
                        ? BusState.atSchool
                        : BusState.atHome),
              updatedAt: DateTime.now(),
              routeDescription:
                  (student.status == StudentStatus.onBus ||
                      student.status == StudentStatus.onBusToSchool ||
                      student.status == StudentStatus.onBusToHome)
                  ? 'في الطريق'
                  : 'لا توجد رحلة نشطة',
              driverName: driverData?['name'] as String?,
              driverImageUrl: driverData?['image_url'] as String?,
            );
          }
        }

        AppLogger.d('✅ Loaded ${_students.length} children and initialized tracking');
        notifyListeners();
      }
    } catch (e, st) {
      AppLogger.d('❌ loadChildrenFromApi failed: $e');
      print(st);
    } finally {
      _isLoadingChildren = false;
    }
  }

  Timer? _trackingTimer;
  int _pollCycleCount = 0;
  bool _isTrackingPolling = false;

  void startTrackingPoll() {
    _trackingTimer?.cancel();
    _pollCycleCount = 0;
    _scheduleTrackingPoll(immediate: true);
  }

  void _scheduleTrackingPoll({bool immediate = false}) {
    _trackingTimer?.cancel();
    _trackingTimer = Timer(Duration(seconds: immediate ? 0 : 10), _runTrackingPollCycle);
  }

  Future<void> _runTrackingPollCycle() async {
    // If not authenticated or no students, just wait for next cycle
    if (!_isAuthenticated || _students.isEmpty) {
      if (_trackingTimer != null) _scheduleTrackingPoll();
      return;
    }

    if (_isTrackingPolling) return;
    _isTrackingPolling = true;

    try {
      await _fetchTrackingFromApi();
      _pollCycleCount++;
      
      // Polling as fallback only (every 60s) — primary updates via WebSocket
      if (_pollCycleCount % 6 == 0) {
        await _refreshStudentStatuses();
      }
    } catch (e) {
      AppLogger.d('❌ Tracking poll cycle failed: $e');
    } finally {
      _isTrackingPolling = false;
      // Schedule next poll automatically if we haven't been stopped
      if (_trackingTimer != null) {
        _scheduleTrackingPoll();
      }
    }
  }

  void stopTrackingPoll() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }

  Future<void> _fetchTrackingFromApi() async {
    try {
      final prefs = await _storage.prefs;
      final token = await _storage.readAccessToken();
      if (token == null) return;

      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      // We need to fetch tracking for each bus our students are on
      final busIds = _students.map((s) => s.bus.id).toSet();

      bool updated = false;
      for (final busId in busIds) {
        try {
          final response = await dio.get('bus/$busId/location');
          if (response.statusCode == 200) {
            final data = response.data;
            final lat = (data['latitude'] as num?)?.toDouble();
            final lng = (data['longitude'] as num?)?.toDouble();

            if (lat != null && lng != null) {
              // Update all students on this bus
              for (final student in _students.where((s) => s.bus.id == busId)) {
                final old = _tracking[student.id];
                final driverData = data['driver'];

                // Calculate distance and ETA if home location is available
                double distanceKm = old?.distanceKm ?? 0.0;
                int etaMinutes = old?.etaMinutes ?? 0;

                if (student.homeLocation != null) {
                  distanceKm = _calculateDistance(
                    lat,
                    lng,
                    student.homeLocation!.latitude,
                    student.homeLocation!.longitude,
                  );
                  // Estimate ETA based on a fixed speed of 60 km/h (1 min per km)
                  etaMinutes = distanceKm.ceil();
                }

                _tracking[student.id] = TrackingSnapshot(
                  lat: lat,
                  lng: lng,
                  speedKmh: (data['speed_kmh'] as num?)?.toDouble() ?? 0.0,
                  etaMinutes: etaMinutes,
                  distanceKm: distanceKm,
                  studentsOnBoard:
                      (data['students_on_board'] as num?)?.toInt() ?? 0,
                  busState: _mapTripStatusToBusState(data['trip_status']),
                  updatedAt:
                      DateTime.tryParse(data['last_update'] ?? '') ??
                      DateTime.now(),
                  routeDescription: old?.routeDescription ?? 'جاري التتبع',
                  driverName: driverData?['name'] as String?,
                  driverImageUrl: driverData?['image_url'] as String?,
                  tripType: data['trip_type']?.toString() ?? old?.tripType,
                  busNumber: data['bus_number']?.toString() ?? student.bus.number,
                  plateNumber: data['plate_number']?.toString() ?? student.bus.plate,
                );
              }

              // Update student statuses from bus polling response (real-time)
              final studentStatuses =
                  data['student_statuses'] as List<dynamic>?;
              if (studentStatuses != null) {
                for (final ss in studentStatuses) {
                  final sid = ss['student_id'].toString();
                  final statusStr = ss['status'] as String? ?? 'atHome';
                  final idx = _students.indexWhere((s) => s.id == sid);
                  if (idx != -1) {
                    final newStatus = StudentStatus.values.firstWhere(
                      (e) => e.name == statusStr,
                      orElse: () => StudentStatus.atHome,
                    );
                    if (_students[idx].status != newStatus) {
                      final now = DateTime.now();
                      _students[idx] = _students[idx].copyWith(
                        status: newStatus,
                        waitingAtHomeTime:
                            (newStatus == StudentStatus.waitingAtHome)
                            ? now
                            : _students[idx].waitingAtHomeTime,
                        onBusToSchoolTime:
                            (newStatus == StudentStatus.onBusToSchool)
                            ? now
                            : _students[idx].onBusToSchoolTime,
                        atSchoolTime: (newStatus == StudentStatus.atSchool)
                            ? now
                            : _students[idx].atSchoolTime,
                        onBusToHomeTime:
                            (newStatus == StudentStatus.onBusToHome)
                            ? now
                            : _students[idx].onBusToHomeTime,
                        arrivedHomeTime:
                            (newStatus == StudentStatus.arrivedHome)
                            ? now
                            : _students[idx].arrivedHomeTime,
                      );
                      _persistTimestamps(_students[idx]);
                    }
                  }
                }
              }
              updated = true;
            }
          }
        } catch (e) {
          AppLogger.d('Failed to fetch tracking for bus $busId: $e');
        }
      }

      if (updated) {
        notifyListeners();
      }
    } catch (e) {
      AppLogger.d('Error in _fetchTrackingFromApi: $e');
    }
  }

  /// Re-fetches student data to pick up status changes (boarding/alighting)
  /// and bus updates (morning→afternoon switch) from the backend.
  Future<void> _refreshStudentStatuses() async {
    try {
      final prefs = await _storage.prefs;
      final token = await _storage.readAccessToken();
      if (token == null) return;

      final response = await dio.get('parent/children');
      if (response.statusCode == 200) {
        final List<dynamic> rawList = response.data['data'] as List<dynamic>;
        bool updated = false;

        for (final raw in rawList) {
          final studentId = raw['id'].toString();
          final idx = _students.indexWhere((s) => s.id == studentId);
          if (idx == -1) continue;

          // Update student status
          final newStatusStr = raw['status'] as String? ?? 'atHome';
          final newStatus = StudentStatus.values.firstWhere(
            (e) => e.name == newStatusStr,
            orElse: () => StudentStatus.atHome,
          );

          // Update bus info (may change between morning/afternoon)
          final newStudent = Student.fromJson(raw as Map<String, dynamic>);
          if (_students[idx].status != newStatus ||
              _students[idx].bus.id != newStudent.bus.id) {
            final now = DateTime.now();
            _students[idx] = _students[idx].copyWith(
              status: newStatus,
              bus: newStudent.bus,
              waitingAtHomeTime: (newStatus == StudentStatus.waitingAtHome)
                  ? now
                  : _students[idx].waitingAtHomeTime,
              onBusToSchoolTime: (newStatus == StudentStatus.onBusToSchool)
                  ? now
                  : _students[idx].onBusToSchoolTime,
              atSchoolTime: (newStatus == StudentStatus.atSchool)
                  ? now
                  : _students[idx].atSchoolTime,
              onBusToHomeTime: (newStatus == StudentStatus.onBusToHome)
                  ? now
                  : _students[idx].onBusToHomeTime,
              arrivedHomeTime: (newStatus == StudentStatus.arrivedHome)
                  ? now
                  : _students[idx].arrivedHomeTime,
            );
            _persistTimestamps(_students[idx]);
            updated = true;

            // Update tracking snapshot bus state
            final old = _tracking[studentId];
            if (old != null) {
              final driverData = raw['bus']?['driver'];
              _tracking[studentId] = TrackingSnapshot(
                lat: old.lat,
                lng: old.lng,
                speedKmh: old.speedKmh,
                etaMinutes: old.etaMinutes,
                distanceKm: old.distanceKm,
                studentsOnBoard: old.studentsOnBoard,
                busState: newStatus == StudentStatus.onBus
                    ? BusState.enRoute
                    : (newStatus == StudentStatus.atSchool
                          ? BusState.atSchool
                          : BusState.atHome),
                updatedAt: old.updatedAt,
                routeDescription: old.routeDescription,
                driverName: driverData?['name'] as String? ?? old.driverName,
                driverImageUrl:
                    driverData?['image_url'] as String? ?? old.driverImageUrl,
                tripType: old.tripType,
                busNumber: old.busNumber,
                plateNumber: old.plateNumber,
              );
            }
          }
        }

        if (updated) {
          developer.log(
            '🔄 Student statuses refreshed from API',
            name: 'TRACKING',
          );
          notifyListeners();
        }
      }
    } catch (e) {
      AppLogger.d('⚠️ _refreshStudentStatuses failed: $e');
    }
  }

  BusState _mapTripStatusToBusState(String? status) {
    if (status == 'morning_ongoing' ||
        status == 'afternoon_ongoing' ||
        status == 'on_route') {
      return BusState.enRoute;
    }
    return BusState.atHome;
  }

  Future<void> bootstrap() async {
    try {
      // Initialize configuration, cached session, etc.
      final prefs = await _storage.prefs;

      // 1. Check onboarding
      final hasSeen = prefs.getBool('has_seen_onboarding') ?? false;
      _shouldShowOnboarding = !hasSeen;

      // 2. Check Authentication
      final savedToken = await _storage.readAccessToken();
      final savedName = prefs.getString('user_name') ?? '';
      if (savedToken != null && savedName.isNotEmpty) {
        _token = savedToken;
        _isAuthenticated = true;
        _userName = savedName;
        _userNameEn = prefs.getString('user_name_en') ?? savedName;
        _userPhone = prefs.getString('user_phone') ?? '';
        _userEmail = prefs.getString('user_email') ?? '';
        _userNationalId = prefs.getString('user_national_id') ?? '';
        _userAvatarUrl = prefs.getString('user_avatar_url') ?? '';
        developer.log(
          '🔐 AppController: Token found → Auto Login ($savedName)',
          name: 'AUTH',
        );

        // Initialize FCM if already logged in
        final fcmToken = await NotificationService.init(
          onNotificationReceived: addNotification,
        );

        // Re-register FCM token just in case it changed
        if (fcmToken != null) {
          await _registerFcmToken(dio: dio, token: _token, fcmToken: fcmToken);
        }

        // Load history + refresh profile from API
        loadNotificationsFromApi();
        loadChildrenFromApi();
        loadProfileFromApi();

        // استعادة WebSocket إذا كان المستخدم مسجل دخول
        _userId = prefs.getInt('user_id');
        if (_userId != null && _userId! > 0) {
          _initReverb(_token);
        }
      } else {
        // No valid session — force login
        _isAuthenticated = false;
        await _storage.deleteAccessToken();
        developer.log(
          '🔐 AppController: No saved session → Show Login',
          name: 'AUTH',
        );
      }

      _bootCompleted = true;
      print(
        '🏁 AppController: Bootstrap completed. Onboarding needed: $_shouldShowOnboarding | Authenticated: $_isAuthenticated',
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
      developer.log(
        '✨ AppController: Bootstrap sequence finished',
        name: 'BOOT',
      );
      notifyListeners();

      // Remove the native splash screen smoothly after the first frame of the new route renders
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          // You will need to make sure FlutterNativeSplash is imported at the top of this file
          FlutterNativeSplash.remove();
        } catch (e) {
          AppLogger.d('AppController: Native splash already removed or error: $e');
        }
      });
    }
  }

  // ═════════════════════════════════════════════════════════════
  // 🔌 WebSocket Real-Time: تهيئة الاتصال ب~ Laravel Reverb
  // ═════════════════════════════════════════════════════════════
  void _initReverb(String token) {
    _reverbService?.dispose();
    _reverbService = ReverbService(
      token: token,
      userId: _userId!,
      dio: dio,
      onStudentStatusUpdated: _handleRealtimeStatusUpdate,
      onBusLocationUpdated: _handleRealtimeLocationUpdate,
    );
    _reverbService!.connect();

    // اشتراك في قنوات الباصات للأبناء الموجودين حالياً
    for (var student in _students) {
      if (student.bus.id.isNotEmpty) {
        _reverbService!.subscribe('private-bus.${student.bus.id}');
      }
    }

    developer.log(
      '🔌 Reverb WebSocket initialized and bus channels subscribed',
      name: 'REVERB',
    );
  }

  /// معالجة تحديث الموقع الفوري للحافلة
  void _handleRealtimeLocationUpdate(Map<String, dynamic> data) {
    final busId = data['bus_id']?.toString();
    if (busId == null) return;

    final lat = double.tryParse(data['latitude']?.toString() ?? '') ?? 0.0;
    final lng = double.tryParse(data['longitude']?.toString() ?? '') ?? 0.0;
    if (lat == 0.0 || lng == 0.0) return;

    // تحديث تتبع جميع الطلاب المرتبطين بهذا الباص
    bool updated = false;
    for (var student in _students) {
      if (student.bus.id == busId) {
        final current = _tracking[student.id];
        
        // Calculate distance and ETA if home location is available
        double distanceKm = current?.distanceKm ?? 0.0;
        int etaMinutes = current?.etaMinutes ?? 0;

        if (student.homeLocation != null) {
          distanceKm = _calculateDistance(
            lat,
            lng,
            student.homeLocation!.latitude,
            student.homeLocation!.longitude,
          );
          // Estimate ETA based on a fixed speed of 40 km/h in city (approx 1.5 min per km)
          // Or just use the 1 min per km (60km/h) as a baseline
          etaMinutes = distanceKm.ceil();
        } else {
          // Fallback to WebSocket data if available
          etaMinutes = int.tryParse(data['eta_minutes']?.toString() ?? '') ?? etaMinutes;
        }

        _tracking[student.id] = TrackingSnapshot(
          lat: lat,
          lng: lng,
          speedKmh: double.tryParse(data['speed_kmh']?.toString() ?? '') ?? 0.0,
          etaMinutes: etaMinutes,
          distanceKm: distanceKm,
          studentsOnBoard:
              int.tryParse(data['students_on_board']?.toString() ?? '') ??
              (current?.studentsOnBoard ?? 0),
          busState: _parseBusState(data['trip_status']?.toString()),
          updatedAt: DateTime.now(),
          routeDescription: current?.routeDescription ?? '',
          driverName: current?.driverName,
          driverImageUrl: current?.driverImageUrl,
          tripType: data['trip_type']?.toString() ?? current?.tripType,
          busNumber: data['bus_number']?.toString() ?? current?.busNumber,
          plateNumber: data['plate_number']?.toString() ?? current?.plateNumber,
        );
        updated = true;
      }
    }

    if (updated) {
      developer.log(
        '📍 Real-time location update for bus $busId',
        name: 'REVERB',
      );
      notifyListeners();
    }
  }

  BusState _parseBusState(String? status) {
    switch (status) {
      case 'to_school':
      case 'to_home':
      case 'on_route':
        return BusState.enRoute;
      case 'at_school':
        return BusState.atSchool;
      default:
        return BusState.atHome;
    }
  }

  /// معالجة تحديث الحالة الفوري من WebSocket
  void _handleRealtimeStatusUpdate(Map<String, dynamic> data) {
    final studentId = data['student_id']?.toString();
    if (studentId == null) return;

    final newStatusStr =
        data['new_status'] as String? ?? ''; // 'boarding' or 'alight'
    final direction = data['direction'] as String? ?? 'to_school';

    final idx = _students.indexWhere((s) => s.id == studentId);
    if (idx == -1) return;

    // تحويل حالة Reverb (boarding/alight) إلى حالات الـ 5-states المتعارف عليها في التطبيق
    StudentStatus newStatus;
    if (newStatusStr == 'boarding') {
      newStatus = (direction == 'to_school')
          ? StudentStatus.onBusToSchool
          : StudentStatus.onBusToHome;
    } else if (newStatusStr == 'alight') {
      newStatus = (direction == 'to_school')
          ? StudentStatus.atSchool
          : StudentStatus.arrivedHome;
    } else {
      // Fallback for direct enum name matching if backend sends onBus/atHome etc.
      newStatus = StudentStatus.values.firstWhere(
        (e) => e.name == newStatusStr,
        orElse: () => _students[idx].status,
      );
    }

    if (_students[idx].status != newStatus) {
      final now = DateTime.now();
      _students[idx] = _students[idx].copyWith(
        status: newStatus,
        waitingAtHomeTime: (newStatus == StudentStatus.waitingAtHome)
            ? now
            : _students[idx].waitingAtHomeTime,
        onBusToSchoolTime: (newStatus == StudentStatus.onBusToSchool)
            ? now
            : _students[idx].onBusToSchoolTime,
        atSchoolTime: (newStatus == StudentStatus.atSchool)
            ? now
            : _students[idx].atSchoolTime,
        onBusToHomeTime: (newStatus == StudentStatus.onBusToHome)
            ? now
            : _students[idx].onBusToHomeTime,
        arrivedHomeTime: (newStatus == StudentStatus.arrivedHome)
            ? now
            : _students[idx].arrivedHomeTime,
      );
      _persistTimestamps(_students[idx]);
      developer.log(
        '🔔 Real-time status update: ${_students[idx].name} ($newStatusStr + $direction) → $newStatus at $now',
        name: 'REVERB',
      );
      notifyListeners();
    }
  }

  // --- PERSISTENCE UTILS ---
  DateTime? _parseTime(String? s) => s != null ? DateTime.tryParse(s) : null;

  Future<void> _persistTimestamps(Student s) async {
    final prefs = await _storage.prefs;
    final todayStr =
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    final sid = s.id;
    if (s.waitingAtHomeTime != null)
      await prefs.setString(
        'ts_${sid}_waitingAtHome_$todayStr',
        s.waitingAtHomeTime!.toIso8601String(),
      );
    if (s.onBusToSchoolTime != null)
      await prefs.setString(
        'ts_${sid}_onBusToSchool_$todayStr',
        s.onBusToSchoolTime!.toIso8601String(),
      );
    if (s.atSchoolTime != null)
      await prefs.setString(
        'ts_${sid}_atSchool_$todayStr',
        s.atSchoolTime!.toIso8601String(),
      );
    if (s.onBusToHomeTime != null)
      await prefs.setString(
        'ts_${sid}_onBusToHome_$todayStr',
        s.onBusToHomeTime!.toIso8601String(),
      );
    if (s.arrivedHomeTime != null)
      await prefs.setString(
        'ts_${sid}_arrivedHome_$todayStr',
        s.arrivedHomeTime!.toIso8601String(),
      );
  }

  Future<void> completeOnboarding() async {
    final prefs = await _storage.prefs;
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
        'device_name': 'device_1',
        'app_context': 'parent',
      };

      developer.log(
        '🔐 LOGIN URL  => ${AppConfig.apiBaseUrl}/api/auth/login',
        name: 'AUTH',
      );
      AppLogger.d('🔐 LOGIN BODY => $loginData');

      final formData = FormData.fromMap(loginData);

      final response = await dio.post(
        'auth/login',
        data: formData,
        options: Options(headers: {'Accept': 'application/json'}),
      );
      AppLogger.d('🔐 LOGIN STATUS => ${response.statusCode}');
      AppLogger.d('🔐 LOGIN DATA   => ${response.data}');

      final token = response.data['token'] as String?;
      if (token == null) return false;

      // ✅ تعيين التوكن في الذاكرة حتى يستخدمه الـ Interceptor
      _token = token;

      // استخراج بيانات المستخدم الكاملة من استجابة الـ API
      final userData = response.data['data']?['user'] ?? response.data['user'];
      final name = userData?['name'] as String? ?? '';
      final nameEn = userData?['name_en'] as String? ?? name;
      final phone = userData?['phone'] as String? ?? '';
      final email = userData?['email'] as String? ?? '';
      final nationalId = userData?['national_id'] as String? ?? '';
      final imageUrl = userData?['image_url'] as String? ?? '';

      _userName = name;
      _userNameEn = nameEn;
      _userPhone = phone;
      _userEmail = email;
      _userNationalId = nationalId;
      _userAvatarUrl = imageUrl;
      developer.log(
        '👤 Logged in as: $name | Phone: $phone | Email: $email',
        name: 'AUTH',
      );

      // حفظ جميع البيانات محلياً
      final prefs = await _storage.prefs;
      await _storage.saveAccessToken(token);
      await prefs.setString('user_name', name);
      await prefs.setString('user_name_en', nameEn);
      await prefs.setString('user_phone', phone);
      await prefs.setString('user_email', email);
      await prefs.setString('user_national_id', nationalId);
      await prefs.setString('user_avatar_url', imageUrl);

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

      // تحميل الإشعارات وبيانات الأبناء من API بعد تسجيل الدخول
      loadNotificationsFromApi();
      loadChildrenFromApi();

      // ═══════════════════════════════════════════════════════════
      // 🔌 تهيئة WebSocket للتحديثات الفورية
      // ═══════════════════════════════════════════════════════════
      _userId = userData?['id'] as int?;
      await prefs.setInt('user_id', _userId ?? 0);
      if (_userId != null) {
        _initReverb(token);
      }

      notifyListeners();
      return true;
    } on DioException catch (e, st) {
      AppLogger.d('=== LOGIN DIO EXCEPTION ===');
      AppLogger.d('Status: ${e.response?.statusCode}');
      AppLogger.d('Data: ${e.response?.data}');
      AppLogger.d('Message: ${e.message}');
      AppLogger.d('===========================');
      developer.log(
        '❌ LOGIN ERROR => ${e.response?.statusCode} | ${e.response?.data}',
        name: 'AUTH',
        error: e,
        stackTrace: st,
      );
      return false;
    } catch (e) {
      AppLogger.d('❌ LOGIN UNEXPECTED => $e');
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
        '/auth/fcm-token',
        data: {'fcm_token': fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      AppLogger.d('✅ FCM: token registered → $fcmToken');
    } catch (e) {
      AppLogger.d('⚠️ FCM: failed to register token: $e');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await _storage.prefs;
      final token = await _storage.readAccessToken();
      if (token != null) {
        final dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          ),
        );
        await dio.post('auth/logout');
        AppLogger.d('✅ Logged out from backend');
      }
    } catch (e) {
      AppLogger.d('⚠️ Logout API call failed: $e');
    }

    final prefs = await _storage.prefs;
    await _storage.deleteAccessToken();
    await prefs.remove('user_name');
    await prefs.remove('user_name_en');
    await prefs.remove('user_phone');
    await prefs.remove('user_email');
    await prefs.remove('user_national_id');
    await prefs.remove('user_avatar_url');

    _isAuthenticated = false;
    _userName = '';
    _userNameEn = '';
    _userPhone = '';
    _userEmail = '';
    _userNationalId = '';
    _userAvatarUrl = '';
    _students = [];
    _navIndex = 0;
    notifyListeners();
  }

  /// تحميل بيانات الملف الشخصي من API
  Future<void> loadProfileFromApi() async {
    try {
      final prefs = await _storage.prefs;
      final token = await _storage.readAccessToken();
      if (token == null) return;

      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await dio.get('parent/profile');
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        _userName = data['name'] as String? ?? _userName;
        _userNameEn = data['name_en'] as String? ?? _userNameEn;
        _userPhone = data['phone'] as String? ?? _userPhone;
        _userEmail = data['email'] as String? ?? _userEmail;
        _userNationalId = data['national_id'] as String? ?? _userNationalId;
        _userAvatarUrl = data['image_url'] as String? ?? _userAvatarUrl;

        // تحديث البيانات المحلية
        await prefs.setString('user_name', _userName);
        await prefs.setString('user_name_en', _userNameEn);
        await prefs.setString('user_phone', _userPhone);
        await prefs.setString('user_email', _userEmail);
        await prefs.setString('user_national_id', _userNationalId);
        await prefs.setString('user_avatar_url', _userAvatarUrl);

        notifyListeners();
        AppLogger.d('✅ Profile loaded from API');
      }
    } catch (e) {
      AppLogger.d('⚠️ loadProfileFromApi failed: $e');
    }
  }

  /// تحديث الصورة الشخصية
  void updateAvatarUrl(String url) {
    _userAvatarUrl = url;
    _storage.prefs.then((prefs) {
      prefs.setString('user_avatar_url', url);
    });
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
    // إشعارات الشات منفصلة عن الإشعارات العامة (لا تظهر في قائمة التنبيهات)
    if (notification.type == NotificationType.chat) {
      developer.log(
        '💬 FCM: Chat notification received — skipping list addition',
        name: 'NOTIFICATION',
      );
      _hasNewMessages = true;
      notifyListeners();
      return;
    }

    // ── تحديث حالة الطالب لحظياً بناءً على بيانات الإشعار ──
    final studentId = notification.data['student_id']?.toString();
    if (studentId != null) {
      final index = _students.indexWhere((s) => s.id == studentId);
      if (index != -1) {
        StudentStatus? newStatus;
        if (notification.type == NotificationType.checkIn) {
          newStatus = StudentStatus.onBus;
        } else if (notification.type == NotificationType.checkOut) {
          final direction = notification.data['direction']?.toString();
          newStatus = (direction == 'to_school')
              ? StudentStatus.atSchool
              : StudentStatus.atHome;
        }

        if (newStatus != null) {
          _students[index] = _students[index].copyWith(status: newStatus);

          // Update tracking snapshot to reflect the new state
          final oldTracking = _tracking[studentId];
          _tracking[studentId] = TrackingSnapshot(
            lat: oldTracking?.lat ?? 24.7136,
            lng: oldTracking?.lng ?? 46.6753,
            speedKmh: newStatus == StudentStatus.onBus ? 35 : 0,
            etaMinutes: newStatus == StudentStatus.onBus ? 12 : 0,
            distanceKm: newStatus == StudentStatus.onBus ? 4.5 : 0,
            studentsOnBoard:
                (oldTracking?.studentsOnBoard ?? 0) +
                (newStatus == StudentStatus.onBus ? 1 : -1),
            busState: newStatus == StudentStatus.onBus
                ? BusState.enRoute
                : (newStatus == StudentStatus.atHome
                      ? BusState.atHome
                      : BusState.atSchool),
            updatedAt: DateTime.now(),
            routeDescription: notification.body,
          );

          developer.log(
            '🔄 FCM: Student $studentId status and tracking updated',
            name: 'NOTIFICATION',
          );
        }
      }
    }

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
      final prefs = await _storage.prefs;
      final token = await _storage.readAccessToken();

      if (token == null) {
        developer.log(
          '⚠️ AppController: no token found to load notifications',
          name: 'NOTIFICATION',
        );
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

      // تصفية إشعارات الشات حتى لا تظهر في القائمة العامة
      final filteredFetched = fetched
          .where((n) => n.type != NotificationType.chat)
          .toList();

      // Prepend fetched items, keeping any push-delivered ones already present
      final existingIds = _notifications.map((n) => n.id).toSet();
      final newOnes = filteredFetched.where((n) => !existingIds.contains(n.id));
      _notifications.addAll(newOnes);
      _notifications.sort((a, b) => b.time.compareTo(a.time));

      notifyListeners();
      print(
        '📋 AppController: loaded ${filteredFetched.length} notifications from API (filtered chat)',
      );
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

  Future<void> loadAbsenceRequestsFromApi() async {
    try {
      final prefs = await _storage.prefs;
      final token = await _storage.readAccessToken();
      if (token == null) return;

      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      final repo = AbsenceRepositoryImpl(dio: dio);
      _absenceRequests = await repo.fetchHistory();
      notifyListeners();
      developer.log(
        '📋 AppController: loaded ${_absenceRequests.length} absence requests',
        name: 'ABSENCE',
      );
    } catch (e) {
      developer.log(
        '⚠️ AppController: failed to load absence requests',
        name: 'ABSENCE',
      );
    }
  }

  Future<bool> submitAbsenceRequest({
    required List<String> studentIds,
    required AbsenceType type,
    required DateTime date,
    String? reason,
  }) async {
    try {
      final token = await _storage.readAccessToken();
      if (token == null) return false;

      final repo = AbsenceRepositoryImpl(dio: dio);
      final request = AbsenceRequest(
        studentIds: studentIds,
        type: type,
        date: date,
        note: reason,
      );

      await repo.submitAbsence(request);
      
      // Refresh local state
      await loadChildrenFromApi();
      await loadAbsenceRequestsFromApi();
      return true;
    } on DioException catch (e) {
      String message = 'فشل إرسال الطلب';
      if (e.response?.data is Map) {
        message = e.response?.data['message'] ?? message;
      }
      developer.log('❌ ABSENCE_SUBMIT_ERROR: $message', name: 'ABSENCE');
      throw message;
    } catch (e) {
      developer.log('❌ ABSENCE_SUBMIT_ERROR: $e', name: 'ABSENCE');
      rethrow;
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

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double p = 0.017453292519943295;
    final a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
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

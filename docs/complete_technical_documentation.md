# 📚 الوثائق التقنية الشاملة - نظام مسارات واصل
## Msarat Wasel - Complete Technical Documentation

---

# الفهرس
1. [نظرة عامة على النظام](#1-نظرة-عامة-على-النظام)
2. [بنية Flutter App (lib)](#2-بنية-flutter-app-lib)
3. [بنية Laravel Backend](#3-بنية-laravel-backend)
4. [قاعدة بيانات Supabase](#4-قاعدة-بيانات-supabase)
5. [وثائق API](#5-وثائق-api)
6. [تفاصيل الميزات](#6-تفاصيل-الميزات)
7. [متطلبات النشر](#7-متطلبات-النشر)

---

# 1. نظرة عامة على النظام

## 1.1 وصف المشروع
نظام متكامل لإدارة النقل المدرسي يربط بين أولياء الأمور والمشرفين والسائقين.

## 1.2 المستخدمون
| الدور | الوصف |
|-------|-------|
| **ولي الأمر** | تتبع الأبناء، التواصل، إدارة الغياب |
| **المشرف** | تسجيل الحضور، التواصل مع الأهالي |
| **السائق** | التتبع GPS، إدارة الرحلات |
| **المدير** | إدارة النظام الكامل |

## 1.3 البنية التقنية
```
┌─────────────────────────────────────────────────────────┐
│                    Mobile Apps (Flutter)                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │ Parent App  │  │ Driver App  │  │Supervisor   │      
│  │   (iOS)     │  │   (iOS)     │  │    App      │      │
│  │  (Android)  │  │  (Android)  │  │(iOS/Android)│      │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘      │
└─────────┼────────────────┼────────────────┼─────────────┘
          │                │                │
          └────────────────┼────────────────┘
                           │
                    ┌──────▼──────┐
                    │   Laravel   │
                    │   Backend   │
                    │  (API/REST) │
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
   ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐
   │  Supabase   │  │  Firebase   │  │   Redis     │
   │ (Database)  │  │    (FCM)    │  │  (Cache)    │
   │ (Storage)   │  │ (Analytics) │  │ (WebSocket) │
   └─────────────┘  └─────────────┘  └─────────────┘
```

---

# 2. بنية Flutter App (lib)

## 2.1 الهيكل الكامل
```
lib/                                    # 📁 المجلد الرئيسي
├── main.dart                           # 🚀 نقطة الدخول
│
└── src/                                # 📁 الكود المصدري
    │
    ├── app/                            # 📁 إعدادات التطبيق
    │   ├── app.dart                    # MaterialApp الرئيسي
    │   └── state/
    │       ├── app_controller.dart     # إدارة الحالة (ChangeNotifier)
    │       └── app_bloc.dart           # إدارة الحالة (BLoC)
    │
    ├── core/                           # 📁 المكونات الأساسية
    │   ├── config/
    │   │   ├── app_config.dart         # إعدادات عامة
    │   │   └── api_keys.dart           # مفاتيح API
    │   │
    │   ├── data/
    │   │   └── sample_data.dart        # بيانات تجريبية
    │   │
    │   ├── models/
    │   │   └── app_models.dart         # نماذج البيانات
    │   │
    │   ├── network/
    │   │   ├── api_client.dart         # Dio Client
    │   │   └── interceptors.dart       # Auth & Logging
    │   │
    │   ├── routing/
    │   │   └── app_router.dart         # التوجيه
    │   │
    │   ├── storage/
    │   │   ├── storage_keys.dart       # مفاتيح التخزين
    │   │   └── storage_service.dart    # SharedPreferences
    │   │
    │   └── utils/
    │       └── result.dart             # Result<T> Pattern
    │
    ├── features/                       # 📁 الميزات (18 ميزة)
    │   │
    │   ├── auth/                       # 🔐 المصادقة
    │   │   ├── data/
    │   │   │   └── repositories/
    │   │   │       └── auth_repository.dart
    │   │   ├── domain/
    │   │   │   ├── entities/
    │   │   │   │   └── auth_user.dart
    │   │   │   └── usecases/
    │   │   │       └── login_usecase.dart
    │   │   └── presentation/
    │   │       ├── login_screen.dart
    │   │       ├── otp_verification_screen.dart
    │   │       ├── forgot_password_screen.dart
    │   │       └── widgets/
    │   │           └── auth_background.dart
    │   │
    │   ├── splash/                     # 🎬 Splash Screen
    │   │   └── presentation/
    │   │       └── splash_screen.dart
    │   │
    │   ├── onboarding/                 # 📖 Introduction
    │   │   └── presentation/
    │   │       └── onboarding_page.dart
    │   │
    │   ├── dashboard/                  # 🏠 لوحة التحكم
    │   │   ├── data/
    │   │   │   └── repositories/
    │   │   │       └── dashboard_repository.dart
    │   │   ├── domain/
    │   │   │   └── entities/
    │   │   │       └── child_summary.dart
    │   │   └── presentation/
    │   │       ├── root_shell.dart     # ⭐ Shell الرئيسي
    │   │       ├── dashboard_page.dart
    │   │       ├── dashboard_screen.dart
    │   │       └── pages/
    │   │           └── parent_dashboard_page.dart
    │   │
    │   ├── home/                       # 🏡 الصفحة الرئيسية
    │   │   └── presentation/
    │   │       ├── home_screen.dart
    │   │       └── home_page.dart
    │   │
    │   ├── children/                   # 👶 إدارة الأبناء
    │   │   └── presentation/
    │   │       ├── children_screen.dart
    │   │       ├── location_picker_screen.dart
    │   │       └── pages/
    │   │           └── children_status_page.dart
    │   │
    │   ├── students/                   # 🎓 الطلاب
    │   │   ├── data/
    │   │   │   └── repositories/
    │   │   │       └── students_repository.dart
    │   │   ├── domain/
    │   │   │   └── entities/
    │   │   │       └── student.dart
    │   │   └── presentation/
    │   │       ├── child_list_screen.dart
    │   │       ├── child_detail_screen.dart
    │   │       └── pages/
    │   │           ├── child_list_page.dart
    │   │           ├── child_detail_page.dart
    │   │           └── add_child_page.dart
    │   │
    │   ├── tracking/                   # 🚌 تتبع الحافلة
    │   │   ├── data/
    │   │   │   └── repositories/
    │   │   │       └── tracking_repository.dart
    │   │   ├── domain/
    │   │   │   └── entities/
    │   │   │       └── bus_position.dart
    │   │   └── presentation/
    │   │       ├── tracking_page.dart  # ⭐ الصفحة الرئيسية
    │   │       ├── bus_tracking_screen.dart
    │   │       ├── pages/
    │   │       │   └── bus_tracking_page.dart
    │   │       └── widgets/
    │   │           └── student_marker_widget.dart
    │   │
    │   ├── notifications/              # 🔔 الإشعارات
    │   │   ├── data/
    │   │   │   └── repositories/
    │   │   │       └── notifications_repository.dart
    │   │   ├── domain/
    │   │   │   └── entities/
    │   │   │       └── app_notification.dart
    │   │   └── presentation/
    │   │       ├── notifications_page.dart
    │   │       └── pages/
    │   │           └── notifications_page.dart
    │   │
    │   ├── messages/                   # 💬 المراسلة
    │   │   └── presentation/
    │   │       └── messages_page.dart
    │   │
    │   ├── communication/              # 📞 التواصل
    │   │   ├── data/
    │   │   │   └── repositories/
    │   │   │       └── communication_repository.dart
    │   │   └── domain/
    │   │       └── entities/
    │   │           └── message_thread.dart
    │   │
    │   ├── attendance/                 # ✅ الحضور والغياب
    │   │   ├── presentation/
    │   │   │   ├── request_absence_page.dart
    │   │   │   └── attendance_history_page.dart
    │   │   └── widgets/
    │   │       └── absence_sheet.dart
    │   │
    │   ├── profile/                    # 👤 الملف الشخصي
    │   │   ├── data/
    │   │   │   └── repositories/
    │   │   │       └── profile_repository.dart
    │   │   ├── domain/
    │   │   │   └── entities/
    │   │   │       └── profile.dart
    │   │   └── presentation/
    │   │       └── parent_profile_page.dart
    │   │
    │   ├── settings/                   # ⚙️ الإعدادات
    │   │   └── presentation/
    │   │       ├── more_page.dart
    │   │       ├── about_app_page.dart
    │   │       ├── contact_us_page.dart
    │   │       ├── privacy_policy_page.dart
    │   │       └── change_password_page.dart
    │   │
    │   ├── complaints/                 # 📝 الشكاوى
    │   │   ├── data/
    │   │   │   └── repositories/
    │   │   │       └── complaints_repository.dart
    │   │   └── domain/
    │   │       └── entities/
    │   │           └── complaint.dart
    │   │
    │   └── language/                   # 🌐 اللغة
    │       ├── data/
    │       │   └── repositories/
    │       │       └── language_repository.dart
    │       ├── domain/
    │       │   └── usecases/
    │       │       └── set_locale_usecase.dart
    │       └── presentation/
    │           ├── language_selector_screen.dart
    │           └── pages/
    │               └── language_selector_page.dart
    │
    └── shared/                         # 📁 المكونات المشتركة
        │
        ├── localization/
        │   └── app_strings.dart        # 290+ مفتاح ترجمة
        │
        ├── theme/
        │   ├── app_colors.dart         # ألوان البراند
        │   ├── app_theme.dart          # Light/Dark Theme
        │   ├── app_typography.dart     # أنماط النص
        │   ├── app_spacing.dart        # المسافات
        │   └── ui_palette.dart         # لوحة الألوان
        │
        ├── presentation/
        │   └── widgets/
        │       ├── animated_background.dart
        │       └── app_sliver_header.dart
        │
        ├── widgets/
        │   ├── custom_text_field.dart
        │   ├── frosted_card.dart
        │   └── primary_button.dart
        │
        ├── services/
        │   └── places_service.dart     # Google Places API
        │
        └── utils/
            ├── date_utils.dart
            ├── labels.dart
            └── marker_generator.dart
```

## 2.2 تفاصيل الملفات الرئيسية

### main.dart
```dart
// نقطة الدخول
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: ...);
  runApp(const MsaratWaselApp());
}
```

### app_controller.dart (الأهم)
```dart
class AppController extends ChangeNotifier {
  // ═══════════════ STATE ═══════════════
  Locale _locale;              // اللغة الحالية (ar/en)
  ThemeMode _themeMode;        // الوضع (light/dark/system)
  bool _isAuthenticated;        // حالة تسجيل الدخول
  int _navIndex;               // الصفحة الحالية
  
  List<Student> _students;      // قائمة الأبناء
  List<Notification> _notifications;
  List<MessageItem> _messages;
  List<AttendanceEntry> _attendance;
  
  // ═══════════════ GETTERS ═══════════════
  String get userName;          // اسم المستخدم حسب اللغة
  String get userAvatarUrl;     // صورة الملف الشخصي
  
  // ═══════════════ METHODS ═══════════════
  Future<void> bootstrap();     // تهيئة التطبيق
  Future<void> login(...);      // تسجيل الدخول
  void logout();                // تسجيل الخروج
  void setNavIndex(int index);  // التنقل
  void setLocale(Locale);       // تغيير اللغة
  void toggleTheme();           // تبديل السمة
}
```

### root_shell.dart (Shell الرئيسي)
```dart
class RootShell extends StatefulWidget {
  // يدير:
  // - Bottom Navigation Bar (5 tabs)
  // - Side Drawer (قائمة جانبية)
  // - الـ 10 صفحات:
  //   0: HomeScreen
  //   1: ChildrenScreen
  //   2: TrackingPage
  //   3: ChildrenStatusPage
  //   4: NotificationsPage
  //   5: MessagesPage
  //   6: RequestAbsencePage
  //   7: AttendanceHistoryPage
  //   8: ParentProfilePage
  //   9: MorePage
}
```

---

# 3. بنية Laravel Backend

## 3.1 الهيكل المقترح
```
laravel-msaratwasel/
│
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── Api/
│   │   │   │   ├── AuthController.php
│   │   │   │   ├── StudentController.php
│   │   │   │   ├── TrackingController.php
│   │   │   │   ├── NotificationController.php
│   │   │   │   ├── MessageController.php
│   │   │   │   ├── AttendanceController.php
│   │   │   │   ├── TripController.php
│   │   │   │   ├── BusController.php
│   │   │   │   ├── SchoolController.php
│   │   │   │   ├── ProfileController.php
│   │   │   │   └── ComplaintController.php
│   │   │   │
│   │   │   └── WebSocket/
│   │   │       ├── TrackingHandler.php
│   │   │       └── MessageHandler.php
│   │   │
│   │   ├── Middleware/
│   │   │   ├── JwtMiddleware.php
│   │   │   ├── RoleMiddleware.php
│   │   │   └── LocaleMiddleware.php
│   │   │
│   │   ├── Requests/
│   │   │   ├── Auth/
│   │   │   │   ├── LoginRequest.php
│   │   │   │   └── VerifyOtpRequest.php
│   │   │   ├── Student/
│   │   │   │   ├── CreateStudentRequest.php
│   │   │   │   └── UpdateLocationRequest.php
│   │   │   └── Attendance/
│   │   │       └── AbsenceRequest.php
│   │   │
│   │   └── Resources/
│   │       ├── StudentResource.php
│   │       ├── NotificationResource.php
│   │       ├── MessageResource.php
│   │       └── AttendanceResource.php
│   │
│   ├── Models/
│   │   ├── User.php
│   │   ├── Parent.php
│   │   ├── Student.php
│   │   ├── School.php
│   │   ├── Bus.php
│   │   ├── Driver.php
│   │   ├── Supervisor.php
│   │   ├── Trip.php
│   │   ├── Attendance.php
│   │   ├── AbsenceRequest.php
│   │   ├── Notification.php
│   │   ├── Conversation.php
│   │   ├── Message.php
│   │   └── Complaint.php
│   │
│   ├── Services/
│   │   ├── OtpService.php
│   │   ├── NotificationService.php
│   │   ├── TrackingService.php
│   │   ├── SmsService.php
│   │   └── FirebaseService.php
│   │
│   ├── Repositories/
│   │   ├── UserRepository.php
│   │   ├── StudentRepository.php
│   │   ├── TripRepository.php
│   │   └── AttendanceRepository.php
│   │
│   ├── Events/
│   │   ├── BusLocationUpdated.php
│   │   ├── StudentPickedUp.php
│   │   ├── StudentDroppedOff.php
│   │   └── NewMessageSent.php
│   │
│   └── Listeners/
│       ├── SendPushNotification.php
│       └── UpdateParentDashboard.php
│
├── config/
│   ├── app.php
│   ├── auth.php
│   ├── database.php
│   ├── firebase.php
│   └── websockets.php
│
├── database/
│   ├── migrations/
│   │   ├── 2026_01_01_000001_create_users_table.php
│   │   ├── 2026_01_01_000002_create_schools_table.php
│   │   ├── 2026_01_01_000003_create_parents_table.php
│   │   ├── 2026_01_01_000004_create_buses_table.php
│   │   ├── 2026_01_01_000005_create_students_table.php
│   │   ├── 2026_01_01_000006_create_trips_table.php
│   │   ├── 2026_01_01_000007_create_attendances_table.php
│   │   ├── 2026_01_01_000008_create_absence_requests_table.php
│   │   ├── 2026_01_01_000009_create_notifications_table.php
│   │   ├── 2026_01_01_000010_create_conversations_table.php
│   │   ├── 2026_01_01_000011_create_messages_table.php
│   │   └── 2026_01_01_000012_create_complaints_table.php
│   │
│   └── seeders/
│       ├── DatabaseSeeder.php
│       ├── SchoolSeeder.php
│       ├── UserSeeder.php
│       └── BusSeeder.php
│
├── routes/
│   ├── api.php                 # 📍 API Routes
│   ├── channels.php            # WebSocket Channels
│   └── web.php
│
└── .env
```

## 3.2 API Routes (routes/api.php)
```php
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\*;

/*
|--------------------------------------------------------------------------
| Authentication Routes
|--------------------------------------------------------------------------
*/
Route::prefix('auth')->group(function () {
    Route::post('login', [AuthController::class, 'login']);
    Route::post('verify-otp', [AuthController::class, 'verifyOtp']);
    Route::post('resend-otp', [AuthController::class, 'resendOtp']);
    Route::post('forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('reset-password', [AuthController::class, 'resetPassword']);
    
    Route::middleware('auth:api')->group(function () {
        Route::post('refresh', [AuthController::class, 'refresh']);
        Route::post('logout', [AuthController::class, 'logout']);
    });
});

/*
|--------------------------------------------------------------------------
| Protected Routes (Require Authentication)
|--------------------------------------------------------------------------
*/
Route::middleware('auth:api')->group(function () {

    /*
    |----------------------------------------------------------------------
    | Profile Routes
    |----------------------------------------------------------------------
    */
    Route::prefix('profile')->group(function () {
        Route::get('/', [ProfileController::class, 'show']);
        Route::put('/', [ProfileController::class, 'update']);
        Route::post('avatar', [ProfileController::class, 'updateAvatar']);
        Route::put('password', [ProfileController::class, 'changePassword']);
        Route::put('fcm-token', [ProfileController::class, 'updateFcmToken']);
    });

    /*
    |----------------------------------------------------------------------
    | Students Routes (Parent Only)
    |----------------------------------------------------------------------
    */
    Route::middleware('role:parent')->group(function () {
        Route::apiResource('students', StudentController::class);
        Route::put('students/{student}/location', [StudentController::class, 'updateLocation']);
    });

    /*
    |----------------------------------------------------------------------
    | Tracking Routes
    |----------------------------------------------------------------------
    */
    Route::prefix('tracking')->group(function () {
        Route::get('bus/{bus}', [TrackingController::class, 'getBusLocation']);
        Route::get('student/{student}', [TrackingController::class, 'getStudentTracking']);
        Route::post('bus/{bus}/location', [TrackingController::class, 'updateBusLocation'])->middleware('role:driver');
    });

    /*
    |----------------------------------------------------------------------
    | Notifications Routes
    |----------------------------------------------------------------------
    */
    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'index']);
        Route::get('unread-count', [NotificationController::class, 'unreadCount']);
        Route::put('{notification}/read', [NotificationController::class, 'markAsRead']);
        Route::put('read-all', [NotificationController::class, 'markAllAsRead']);
    });

    /*
    |----------------------------------------------------------------------
    | Messages Routes
    |----------------------------------------------------------------------
    */
    Route::prefix('messages')->group(function () {
        Route::get('conversations', [MessageController::class, 'getConversations']);
        Route::get('conversations/{conversation}', [MessageController::class, 'getMessages']);
        Route::post('conversations/{conversation}', [MessageController::class, 'sendMessage']);
        Route::post('conversations', [MessageController::class, 'startConversation']);
    });

    /*
    |----------------------------------------------------------------------
    | Attendance Routes
    |----------------------------------------------------------------------
    */
    Route::prefix('attendance')->group(function () {
        Route::get('history', [AttendanceController::class, 'history']);
        Route::get('summary', [AttendanceController::class, 'summary']);
        Route::post('absence-request', [AttendanceController::class, 'requestAbsence']);
        Route::get('absence-requests', [AttendanceController::class, 'getAbsenceRequests']);
        
        // Supervisor Only
        Route::middleware('role:supervisor')->group(function () {
            Route::post('record', [AttendanceController::class, 'record']);
        });
    });

    /*
    |----------------------------------------------------------------------
    | Trips Routes
    |----------------------------------------------------------------------
    */
    Route::prefix('trips')->group(function () {
        Route::get('/', [TripController::class, 'index']);
        Route::get('{trip}', [TripController::class, 'show']);
        Route::get('active', [TripController::class, 'getActiveTrip']);
        
        // Driver/Supervisor Only
        Route::middleware('role:driver,supervisor')->group(function () {
            Route::post('start', [TripController::class, 'start']);
            Route::post('{trip}/end', [TripController::class, 'end']);
        });
    });

    /*
    |----------------------------------------------------------------------
    | Complaints Routes
    |----------------------------------------------------------------------
    */
    Route::prefix('complaints')->group(function () {
        Route::get('/', [ComplaintController::class, 'index']);
        Route::post('/', [ComplaintController::class, 'store']);
    });

    /*
    |----------------------------------------------------------------------
    | Dashboard Routes
    |----------------------------------------------------------------------
    */
    Route::get('dashboard', [DashboardController::class, 'index']);
});
```

## 3.3 Controllers الرئيسية

### AuthController.php
```php
<?php

namespace App\Http\Controllers\Api;

class AuthController extends Controller
{
    /**
     * تسجيل الدخول وإرسال OTP
     * POST /api/auth/login
     */
    public function login(LoginRequest $request)
    {
        $user = User::where('civil_id', $request->civil_id)
                    ->where('phone', $request->phone)
                    ->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'المستخدم غير موجود'
            ], 404);
        }

        // إنشاء وإرسال OTP
        $otp = $this->otpService->generate($user);
        $this->smsService->send($user->phone, "رمز التحقق: {$otp}");

        return response()->json([
            'success' => true,
            'message' => 'تم إرسال رمز التحقق',
            'data' => [
                'otp_expiry' => 300,
                'phone_masked' => $this->maskPhone($user->phone)
            ]
        ]);
    }

    /**
     * التحقق من OTP
     * POST /api/auth/verify-otp
     */
    public function verifyOtp(VerifyOtpRequest $request)
    {
        $user = User::where('civil_id', $request->civil_id)->first();
        
        if (!$this->otpService->verify($user, $request->otp)) {
            return response()->json([
                'success' => false,
                'message' => 'رمز التحقق غير صحيح أو منتهي'
            ], 401);
        }

        $token = auth()->login($user);

        return response()->json([
            'success' => true,
            'data' => [
                'access_token' => $token,
                'refresh_token' => $this->generateRefreshToken($user),
                'expires_in' => config('jwt.ttl') * 60,
                'user' => new UserResource($user)
            ]
        ]);
    }
}
```

### StudentController.php
```php
<?php

namespace App\Http\Controllers\Api;

class StudentController extends Controller
{
    /**
     * جلب قائمة الأبناء
     * GET /api/students
     */
    public function index()
    {
        $parent = auth()->user()->parent;
        $students = $parent->students()
            ->with(['school', 'bus', 'bus.driver', 'bus.supervisor'])
            ->get();

        return StudentResource::collection($students);
    }

    /**
     * تحديث موقع الاستلام
     * PUT /api/students/{student}/location
     */
    public function updateLocation(UpdateLocationRequest $request, Student $student)
    {
        $this->authorize('update', $student);

        $student->update([
            'pickup_lat' => $request->lat,
            'pickup_lng' => $request->lng,
            'pickup_address' => $request->address
        ]);

        return response()->json([
            'success' => true,
            'message' => 'تم تحديث الموقع بنجاح'
        ]);
    }
}
```

### TrackingController.php
```php
<?php

namespace App\Http\Controllers\Api;

class TrackingController extends Controller
{
    /**
     * جلب موقع الحافلة الحالي
     * GET /api/tracking/bus/{bus}
     */
    public function getBusLocation(Bus $bus)
    {
        return response()->json([
            'success' => true,
            'data' => [
                'bus_id' => $bus->id,
                'lat' => $bus->current_lat,
                'lng' => $bus->current_lng,
                'speed' => $bus->speed,
                'heading' => $bus->heading,
                'bus_state' => $bus->bus_state,
                'last_update' => $bus->last_location_update,
                'driver' => new DriverResource($bus->driver),
                'supervisor' => new SupervisorResource($bus->supervisor)
            ]
        ]);
    }

    /**
     * تحديث موقع الحافلة (للسائق)
     * POST /api/tracking/bus/{bus}/location
     */
    public function updateBusLocation(Request $request, Bus $bus)
    {
        $bus->update([
            'current_lat' => $request->lat,
            'current_lng' => $request->lng,
            'speed' => $request->speed,
            'heading' => $request->heading,
            'last_location_update' => now()
        ]);

        // بث الموقع عبر WebSocket
        broadcast(new BusLocationUpdated($bus))->toOthers();

        return response()->json(['success' => true]);
    }
}
```

---

# 4. قاعدة بيانات Supabase

## 4.1 إعداد Supabase
```bash
# 1. إنشاء مشروع جديد في supabase.com
# 2. الحصول على:
#    - Project URL
#    - anon/public key
#    - service_role key

# 3. تكوين Laravel .env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

DB_CONNECTION=pgsql
DB_HOST=db.xxxxx.supabase.co
DB_PORT=5432
DB_DATABASE=postgres
DB_USERNAME=postgres
DB_PASSWORD=your-db-password
```

## 4.2 جداول Supabase (PostgreSQL)

### الجدول 1: users
```sql
-- جدول المستخدمين الرئيسي
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    civil_id VARCHAR(12) UNIQUE NOT NULL,
    phone VARCHAR(15) NOT NULL,
    name_ar VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    email VARCHAR(100),
    password_hash VARCHAR(255),
    avatar_url TEXT,
    role VARCHAR(20) NOT NULL CHECK (role IN ('parent', 'supervisor', 'driver', 'admin')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    fcm_token TEXT,
    locale VARCHAR(5) DEFAULT 'ar',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_users_civil_id ON users(civil_id);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);

-- RLS Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id);
```

### الجدول 2: parents
```sql
CREATE TABLE parents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    home_lat DECIMAL(10, 8),
    home_lng DECIMAL(11, 8),
    home_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_parents_user_id ON parents(user_id);
```

### الجدول 3: schools
```sql
CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_ar VARCHAR(200) NOT NULL,
    name_en VARCHAR(200),
    lat DECIMAL(10, 8) NOT NULL,
    lng DECIMAL(11, 8) NOT NULL,
    address TEXT,
    phone VARCHAR(15),
    principal_name VARCHAR(100),
    logo_url TEXT,
    start_time TIME DEFAULT '07:00:00',
    end_time TIME DEFAULT '14:00:00',
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### الجدول 4: buses
```sql
CREATE TABLE buses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plate_number VARCHAR(20) UNIQUE NOT NULL,
    capacity INT DEFAULT 30,
    model VARCHAR(100),
    year INT,
    driver_id UUID REFERENCES users(id),
    supervisor_id UUID REFERENCES users(id),
    school_id UUID NOT NULL REFERENCES schools(id),
    
    -- Location Tracking
    current_lat DECIMAL(10, 8),
    current_lng DECIMAL(11, 8),
    speed DECIMAL(5, 2) DEFAULT 0,
    heading DECIMAL(5, 2) DEFAULT 0,
    
    bus_state VARCHAR(30) DEFAULT 'idle' 
        CHECK (bus_state IN ('idle', 'morning_trip', 'school_arrived', 'afternoon_trip', 'completed')),
    status VARCHAR(20) DEFAULT 'active' 
        CHECK (status IN ('active', 'maintenance', 'inactive')),
    last_location_update TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Realtime للتتبع المباشر
ALTER PUBLICATION supabase_realtime ADD TABLE buses;
```

### الجدول 5: students
```sql
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID NOT NULL REFERENCES parents(id),
    school_id UUID NOT NULL REFERENCES schools(id),
    bus_id UUID REFERENCES buses(id),
    
    name_ar VARCHAR(100) NOT NULL,
    name_en VARCHAR(100),
    grade VARCHAR(20),
    class_name VARCHAR(20),
    photo_url TEXT,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('male', 'female')),
    date_of_birth DATE,
    
    -- Pickup Location
    pickup_lat DECIMAL(10, 8),
    pickup_lng DECIMAL(11, 8),
    pickup_address TEXT,
    
    status VARCHAR(20) DEFAULT 'active' 
        CHECK (status IN ('active', 'inactive', 'graduated')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_students_parent ON students(parent_id);
CREATE INDEX idx_students_school ON students(school_id);
CREATE INDEX idx_students_bus ON students(bus_id);
```

### الجدول 6: trips
```sql
CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bus_id UUID NOT NULL REFERENCES buses(id),
    trip_type VARCHAR(20) NOT NULL CHECK (trip_type IN ('morning', 'afternoon')),
    date DATE NOT NULL,
    
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    start_lat DECIMAL(10, 8),
    start_lng DECIMAL(11, 8),
    end_lat DECIMAL(10, 8),
    end_lng DECIMAL(11, 8),
    
    total_students INT DEFAULT 0,
    picked_up_count INT DEFAULT 0,
    dropped_off_count INT DEFAULT 0,
    
    status VARCHAR(20) DEFAULT 'scheduled' 
        CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_trips_date ON trips(date);
CREATE INDEX idx_trips_bus_date ON trips(bus_id, date);
CREATE UNIQUE INDEX idx_trips_unique ON trips(bus_id, date, trip_type);
```

### الجدول 7: attendances
```sql
CREATE TABLE attendances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES students(id),
    trip_id UUID NOT NULL REFERENCES trips(id),
    
    attendance_type VARCHAR(20) NOT NULL CHECK (attendance_type IN ('pickup', 'dropoff')),
    status VARCHAR(20) NOT NULL 
        CHECK (status IN ('picked_up', 'dropped_off', 'absent', 'excused')),
    
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    recorded_by UUID REFERENCES users(id),
    lat DECIMAL(10, 8),
    lng DECIMAL(11, 8),
    notes TEXT,
    
    UNIQUE(student_id, trip_id, attendance_type)
);

CREATE INDEX idx_attendances_student ON attendances(student_id);
CREATE INDEX idx_attendances_trip ON attendances(trip_id);
```

### الجدول 8: absence_requests
```sql
CREATE TABLE absence_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES students(id),
    parent_id UUID NOT NULL REFERENCES parents(id),
    
    date_from DATE NOT NULL,
    date_to DATE NOT NULL,
    reason TEXT,
    
    status VARCHAR(20) DEFAULT 'pending' 
        CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMPTZ,
    review_notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### الجدول 9: notifications
```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    
    notification_type VARCHAR(30) NOT NULL 
        CHECK (notification_type IN (
            'trip_start', 'approaching', 'arrived', 
            'picked_up', 'dropped_off', 'alert', 'general'
        )),
    
    title_ar VARCHAR(200) NOT NULL,
    title_en VARCHAR(200),
    body_ar TEXT,
    body_en TEXT,
    
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

-- Realtime للإشعارات الفورية
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
```

### الجدول 10: conversations
```sql
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID NOT NULL REFERENCES parents(id),
    supervisor_id UUID NOT NULL REFERENCES users(id),
    
    last_message_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(parent_id, supervisor_id)
);
```

### الجدول 11: messages
```sql
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id),
    sender_id UUID NOT NULL REFERENCES users(id),
    
    text TEXT,
    media_url TEXT,
    media_type VARCHAR(20) CHECK (media_type IN ('image', 'video', 'audio', 'document')),
    
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at);

-- Realtime للرسائل الفورية
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
```

### الجدول 12: complaints
```sql
CREATE TABLE complaints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    
    subject VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50),
    
    status VARCHAR(20) DEFAULT 'open' 
        CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    
    assigned_to UUID REFERENCES users(id),
    resolution TEXT,
    resolved_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### الجدول 13: otp_codes
```sql
CREATE TABLE otp_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_otp_user ON otp_codes(user_id, is_used);
```

## 4.3 Supabase Functions

### Function: get_parent_dashboard
```sql
CREATE OR REPLACE FUNCTION get_parent_dashboard(parent_uuid UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'students_count', (
            SELECT COUNT(*) FROM students 
            WHERE parent_id = parent_uuid AND status = 'active'
        ),
        'on_bus_count', (
            SELECT COUNT(*) FROM students s
            JOIN attendances a ON s.id = a.student_id
            WHERE s.parent_id = parent_uuid 
            AND a.status = 'picked_up'
            AND a.recorded_at::DATE = CURRENT_DATE
        ),
        'unread_notifications', (
            SELECT COUNT(*) FROM notifications n
            JOIN parents p ON p.user_id = n.user_id
            WHERE p.id = parent_uuid AND n.is_read = FALSE
        ),
        'active_trips', (
            SELECT jsonb_agg(jsonb_build_object(
                'trip_id', t.id,
                'bus_id', b.id,
                'plate_number', b.plate_number,
                'bus_state', b.bus_state,
                'lat', b.current_lat,
                'lng', b.current_lng
            ))
            FROM trips t
            JOIN buses b ON t.bus_id = b.id
            JOIN students s ON s.bus_id = b.id
            WHERE s.parent_id = parent_uuid
            AND t.status = 'in_progress'
            AND t.date = CURRENT_DATE
        )
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;
```

## 4.4 Supabase Storage Buckets

```sql
-- إنشاء Buckets للملفات
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('avatars', 'avatars', true),
    ('student-photos', 'student-photos', true),
    ('message-attachments', 'message-attachments', false),
    ('school-logos', 'school-logos', true);

-- سياسات الوصول
CREATE POLICY "Anyone can view avatars"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload own avatar"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'avatars' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );
```

---

# 5. وثائق API

## 5.1 Authentication Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | تسجيل الدخول |
| POST | `/api/auth/verify-otp` | التحقق من OTP |
| POST | `/api/auth/resend-otp` | إعادة إرسال OTP |
| POST | `/api/auth/refresh` | تجديد Token |
| POST | `/api/auth/logout` | تسجيل الخروج |

## 5.2 Students Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/students` | قائمة الأبناء |
| GET | `/api/students/{id}` | تفاصيل طالب |
| PUT | `/api/students/{id}/location` | تحديث موقع الاستلام |

## 5.3 Tracking Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/tracking/bus/{id}` | موقع الحافلة |
| GET | `/api/tracking/student/{id}` | تتبع طالب محدد |
| WS | `wss://api/tracking/ws` | تتبع مباشر |

## 5.4 Full API Reference

> راجع ملف [project_documentation.md](file:///Users/abdurahmanal-hattami/.gemini/antigravity/brain/a9b16c82-7b3f-42be-8ac6-c2890e1c8a64/project_documentation.md) للوثائق الكاملة

---

# 6. تفاصيل الميزات

## ملخص الميزات (18 ميزة)

| # | الميزة | الشاشة | API |
|---|--------|--------|-----|
| 1 | Splash | splash_screen.dart | ❌ |
| 2 | Onboarding | onboarding_page.dart | ❌ |
| 3 | تسجيل الدخول | login_screen.dart | POST /auth/login |
| 4 | OTP | otp_verification_screen.dart | POST /auth/verify-otp |
| 5 | الرئيسية | home_screen.dart | GET /dashboard |
| 6 | الأبناء | children_screen.dart | GET /students |
| 7 | التتبع | tracking_page.dart | WebSocket |
| 8 | الإشعارات | notifications_page.dart | GET /notifications |
| 9 | الرسائل | messages_page.dart | WebSocket |
| 10 | طلب الغياب | request_absence_page.dart | POST /attendance/absence |
| 11 | سجل الحضور | attendance_history_page.dart | GET /attendance/history |
| 12 | الملف الشخصي | parent_profile_page.dart | GET/PUT /profile |
| 13 | الإعدادات | more_page.dart | ❌ |
| 14 | عن التطبيق | about_app_page.dart | ❌ |
| 15 | تواصل معنا | contact_us_page.dart | ❌ |
| 16 | الخصوصية | privacy_policy_page.dart | ❌ |
| 17 | تغيير كلمة المرور | change_password_page.dart | PUT /profile/password |
| 18 | اختيار الموقع | location_picker_screen.dart | Places API |

---

# 7. متطلبات النشر

## 7.1 متطلبات الخوادم

| الخدمة | المواصفات |
|--------|----------|
| **Laravel Server** | 2 CPU, 4GB RAM, Ubuntu 22.04 |
| **Supabase** | Pro Plan ($25/month) |
| **Redis** | 2GB RAM |
| **Firebase** | Blaze Plan (pay-as-you-go) |

## 7.2 متطلبات التطبيقات

| المنصة | المتطلب |
|--------|---------|
| **iOS** | iOS 12.0+, Apple Developer ($99/year) |
| **Android** | API 21+, Google Play ($25 one-time) |

## 7.3 الجدول الزمني

| المرحلة | المدة |
|---------|-------|
| إعداد Supabase | 1 يوم |
| بناء Laravel API | 5-7 أيام |
| ربط Flutter بالـ API | 3-4 أيام |
| الاختبار | 2-3 أيام |
| النشر | 1-2 أيام |

**الإجمالي: 12-17 يوم عمل**

---

*تم إعداد هذه الوثائق بتاريخ: 2026-01-17*

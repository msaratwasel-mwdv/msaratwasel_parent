import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/utils/logger.dart'; // Use project logger
import 'package:msaratwasel_user/src/core/models/app_models.dart';
import 'package:msaratwasel_user/src/features/chat/presentation/chat_page.dart';

/// Routing Matrix for Notification Deep-Linking
/// ─────────────────────────────────────────────────────────────────
/// | Event               | Category          | Target Screen       | Nav Index |
/// |─────────────────────|───────────────────|─────────────────────|───────────|
/// | Trip started        | bus_tracking      | map_page            | 2         |
/// | Student status      | student_status    | students_tracking   | 3         |
/// | Student tracking    | student_tracking  | map_page            | 2         |
/// | Chat message        | chat              | ▶ DIRECT ChatPage   | -         |
/// | Attendance          | attendance        | attendance_history  | 7         |
/// | Location request    | location_request  | location_requests   | 11        |
/// | Absence             | absence           | absence_history     | 10        |
/// | Holiday/Field trip  | admin             | notifications       | 4         |
/// | Default fallback    | -                 | -                   | 4         |
class NotificationRouter {
  // ── Tap Deduplication ──────────────────────────────────────────────────
  // LRU of last 200 handled notification IDs prevents double-tap navigation.
  static final LinkedHashSet<String> _handledTapIds = LinkedHashSet<String>();
  static const int _maxHandledIds = 200;
  static DateTime? _lastTapTime;
  static String? _lastTapId;

  /// The SINGLE entry point for handling all notification taps.
  ///
  /// Called from:
  ///   - FCM onMessageOpenedApp (background tap)
  ///   - FCM getInitialMessage (cold-start tap)
  ///   - Local notification onDidReceiveNotificationResponse (foreground tap)
  ///   - In-app notifications list tap
  static void handleNotificationTap(AppController controller, AppNotification notification) {
    developer.log(
      '🔗 [TAP DETECTED] id=${notification.id} | type=${notification.type} | target=${notification.targetScreen} | cat=${notification.category} | data=${notification.data}',
      name: 'ROUTER',
    );

    // Mark as read immediately on tap to sync UI counters
    controller.markNotificationsRead([notification.id]);

    // Defer routing to ensure the widget tree is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log('🔗 [EXECUTING ROUTE] id=${notification.id}', name: 'ROUTER');
      _doRoute(controller, notification);
    });
  }

  static void _doRoute(AppController controller, AppNotification notification) {
    // 1. CHAT MESSAGES: Direct navigation via navigatorKey
    if (_isChatNotification(notification)) {
      _navigateToChatDirectly(controller, notification);
      return;
    }

    // 2. NON-CHAT: We need to switch tabs.
    // CRITICAL: If the user is currently on a sub-page (pushed on top of RootShell),
    // we MUST pop to the root so they can actually see the tab switch.
    final navState = controller.navigatorKey.currentState;
    if (navState != null && navState.canPop()) {
      AppLogger.d('🏠 ROUTER: Navigator detected sub-pages, popping to root...');
      navState.popUntil((route) => route.isFirst);
    }

    // A. Direct check for student status / children tracking (High Priority)
    final targetScreen = notification.targetScreen ??
        notification.data['target_screen']?.toString();
    
    final isStatusUpdate = targetScreen == 'children_status' || 
                          targetScreen == 'students_tracking' ||
                          notification.type == NotificationType.checkIn ||
                          notification.type == NotificationType.checkOut ||
                          notification.type == NotificationType.arrival;

    if (isStatusUpdate) {
      AppLogger.d('🔗 ROUTER: Status update detected, forcing index 3 (ChildrenStatusPage)');
      controller.setPendingNotificationId(notification.id);
      controller.setNavIndex(3);
      return;
    }

    // B. Try other target_screen-based routing
    if (targetScreen != null && targetScreen.isNotEmpty) {
      final navIndex = _targetScreenToNavIndex(targetScreen);
      if (navIndex != null) {
        AppLogger.d('🔗 ROUTER: target_screen=$targetScreen → index=$navIndex');
        controller.setPendingNotificationId(notification.id);
        controller.setNavIndex(navIndex);
        return;
      }
    }

    // C. Try category-based routing
    final category = notification.category ??
        notification.data['category']?.toString();
    if (category != null && category.isNotEmpty) {
      final navIndex = _categoryToNavIndex(category);
      if (navIndex != null) {
        AppLogger.d('🔗 ROUTER: category=$category → index=$navIndex');
        controller.setPendingNotificationId(notification.id);
        controller.setNavIndex(navIndex);
        return;
      }
    }

    // D. Fallback: type-based routing
    AppLogger.d('🔗 ROUTER: Falling back to type-based routing for ${notification.type}');
    _routeByType(controller, notification);
  }

  /// Returns true if this notification is a chat/supervisor message.
  static bool _isChatNotification(AppNotification notification) {
    return notification.type == NotificationType.chat ||
        notification.type == NotificationType.supervisorMessage;
  }

  /// DIRECT navigation to ChatPage via the global navigatorKey.
  /// This bypasses ContactsPage entirely — no pending IDs, no intermediary.
  static void _navigateToChatDirectly(
    AppController controller,
    AppNotification notification,
  ) {
    // ── Extract conversationId ──────────────────────────────────────────
    final convIdStr = notification.data['conversation_id']?.toString() ??
        notification.data['conversationId']?.toString() ??
        notification.data['conv_id']?.toString() ??
        notification.data['chatId']?.toString() ??
        notification.data['roomId']?.toString();

    if (convIdStr == null || convIdStr.isEmpty) {
      developer.log(
        '❌ CHAT TAP: Missing conversationId in payload. '
        'Data: ${notification.data}. Ignoring tap — will NOT fallback to chat list.',
        name: 'ROUTER',
      );
      return;
    }

    final conversationId = int.tryParse(convIdStr);
    if (conversationId == null) {
      developer.log(
        '❌ CHAT TAP: Invalid conversationId "$convIdStr". Ignoring.',
        name: 'ROUTER',
      );
      return;
    }

    // Extract sender info
    final senderName = notification.senderName ??
        notification.data['sender_name']?.toString() ??
        notification.data['senderName']?.toString() ??
        notification.data['from_user_name']?.toString() ??
        '';
    final senderRole = notification.data['sender_role']?.toString() ??
        notification.data['senderRole']?.toString() ??
        (notification.type == NotificationType.supervisorMessage
            ? 'supervisor'
            : 'driver');

    developer.log(
      '🚀 CHAT TAP: Navigating directly to conversation $conversationId '
      '(sender: $senderName, role: $senderRole)',
      name: 'ROUTER',
    );

    final navKey = controller.navigatorKey;
    final navState = navKey.currentState;

    if (navState == null) {
      // Navigator not yet mounted — queue for later
      developer.log(
        '⏳ CHAT TAP: Navigator not ready. Queuing pending chat navigation.',
        name: 'ROUTER',
      );
      controller.setPendingChatRoute(
        conversationId: conversationId,
        senderName: senderName,
        senderRole: senderRole,
      );
      // Also switch to chat tab so when navigator is ready, we can flush
      controller.setNavIndex(5);
      return;
    }

    // If user is already on a ChatPage, pop it first to avoid stacking
    // We check if there's a route we can pop (i.e., we're not at root)
    if (navState.canPop()) {
      navState.popUntil((route) => route.isFirst);
    }

    // Switch to chat tab first (so back button returns to chat list)
    controller.setNavIndex(5);

    // Push ChatPage directly
    navState.push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          conversationId: conversationId,
          contactName: senderName,
          contactRole: senderRole,
        ),
      ),
    );
  }

  /// Maps `target_screen` payload value to navigation index.
  static int? _targetScreenToNavIndex(String targetScreen) {
    switch (targetScreen) {
      case 'map_page':
        return 2; // BusTrackingPage
      case 'students_tracking':
      case 'children_status':
        return 3; // ChildrenStatusPage
      case 'chat_details':
      case 'contacts':
        return 5; // ContactsPage (for non-chat-message taps that still target chat)
      case 'attendance_history':
      case 'school_attendance':
      case 'attendance_details':
        return 7; // AttendanceHistoryPage
      case 'absence_history':
      case 'absence_requests': // Added: match backend
        return 10; // AbsenceHistoryPage
      case 'location_requests':
      case 'location_request_details':
      case 'requests_history':
      case 'location_request': // Added
        return 11; // LocationRequestsPage
      case 'notifications':
        return 4; // NotificationsPage
      case 'children':
        return 1; // ChildrenScreen
      case 'home':
        return 0; // HomeScreen
      default:
        developer.log('⚠️ ROUTER: Unrecognized target_screen: $targetScreen', name: 'ROUTER');
        return null;
    }
  }

  /// Maps `category` payload value to navigation index.
  static int? _categoryToNavIndex(String category) {
    switch (category) {
      case 'bus_tracking':
        return 2;
      case 'student_status':
        return 3;
      case 'student_tracking':
        return 2;
      case 'attendance':
        return 7;
      case 'absence':
      case 'absences':
        return 10;
      case 'location_request':
      case 'location_requests':
        return 11;
      case 'admin':
      case 'school':
        return 4;
      // NOTE: 'chat' category is handled by _isChatNotification, not here
      default:
        return null;
    }
  }

  /// Legacy fallback: route based on notification type enum.
  static void _routeByType(AppController controller, AppNotification notification) {
    switch (notification.type) {
      // Chat messages → DIRECT navigation (should not reach here, but safety net)
      case NotificationType.chat:
      case NotificationType.supervisorMessage:
        _navigateToChatDirectly(controller, notification);
        return;

      // Trip/Bus events → map page
      case NotificationType.approach:
      case NotificationType.arrival:
      case NotificationType.delay:
      case NotificationType.routeChange:
      case NotificationType.tripStarted: // Added
      case NotificationType.tripEnded: // Added
        controller.setNavIndex(2);
        return;
      
      // Attendance events → attendance history
      case NotificationType.schoolAttendance: // Added
        controller.setNavIndex(7);
        return;

      // Student status events → children status
      case NotificationType.checkIn:
      case NotificationType.checkOut:
      case NotificationType.lateBoarding:
        controller.setNavIndex(3);
        return;

      // Absence events → absence history
      case NotificationType.absence:
      case NotificationType.absenceApproved:
      case NotificationType.absenceRejected:
        controller.setNavIndex(10);
        return;

      // Location events → location requests
      case NotificationType.locationRequest:
      case NotificationType.locationApproved:
      case NotificationType.locationRejected:
        controller.setNavIndex(11);
        return;

      // Everything else → Notifications page
      default:
        developer.log(
          '🔗 Routing to Notifications page for: ${notification.type}',
          name: 'ROUTER',
        );
        controller.setPendingNotificationId(notification.id);
        controller.setNavIndex(4);
        return;
    }
  }
}

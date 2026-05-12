import 'dart:developer' as developer;
import 'package:flutter/scheduler.dart';
import 'package:msaratwasel_user/src/app/state/app_controller.dart';
import 'package:msaratwasel_user/src/core/models/app_models.dart';

class NotificationRouter {
  /// Routes the user to the appropriate screen based on the notification type.
  ///
  /// Rules:
  ///  - `chat` / `supervisorMessage`  → Chat page (index 5)
  ///  - Everything else               → Notifications page (index 4)
  ///
  /// Routing is deferred to the next frame via [SchedulerBinding] so that it
  /// works correctly in ALL app lifecycle states:
  ///   ✅ App terminated  → opens on Notifications page
  ///   ✅ App in background → navigates to Notifications page
  ///   ✅ App open on another page → navigates to Notifications page
  ///   ✅ App already on Notifications page → reloads with new notification detail
  static void route(AppController controller, AppNotification notification) {
    developer.log(
      '🔗 Routing notification: ${notification.id} (Type: ${notification.type})',
      name: 'ROUTER',
    );

    // Defer routing to next frame so the widget tree is always ready
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _doRoute(controller, notification);
    });
  }

  static void _doRoute(AppController controller, AppNotification notification) {
    // Chat / Supervisor messages → open the related conversation
    if (notification.type == NotificationType.chat ||
        notification.type == NotificationType.supervisorMessage) {
      final convId = notification.data['conversation_id']?.toString();
      if (convId != null) {
        controller.setPendingConversationId(convId);
        developer.log('🔗 Setting pending conversation ID: $convId', name: 'ROUTER');
      }
      controller.setNavIndex(5); // Contacts/Chat Page
      return;
    }

    // Everything else → Notifications page
    developer.log('🔗 Routing to Notifications page for: ${notification.type}', name: 'ROUTER');
    controller.setPendingNotificationId(notification.id);
    controller.setNavIndex(4); // Notifications Page
  }
}

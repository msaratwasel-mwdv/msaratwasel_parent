import 'dart:developer' as developer;
import 'package:app_badge_plus/app_badge_plus.dart' as abp;

class AppBadgePlus {
  static Future<bool> isSupported() => abp.AppBadgePlus.isSupported();
  static Future<void> updateBadge(int count) => abp.AppBadgePlus.updateBadge(count);
  static Future<void> removeBadge() => abp.AppBadgePlus.updateBadge(0);
}

class NotificationBadgeService {
  static Future<void> sync(int unreadCount) async {
    try {
      developer.log('🏷️ NotificationBadgeService: Syncing app badge to $unreadCount', name: 'BadgeService');
      if (unreadCount <= 0) {
        await AppBadgePlus.removeBadge();
      } else {
        await AppBadgePlus.updateBadge(unreadCount);
      }
      developer.log('🏷️ NotificationBadgeService: Badge synced successfully.', name: 'BadgeService');
    } catch (e, stack) {
      developer.log('⚠️ NotificationBadgeService: Failed to sync badge: $e', name: 'BadgeService', error: e, stackTrace: stack);
    }
  }
}

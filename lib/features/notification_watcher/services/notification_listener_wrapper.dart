import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

/// Abstract wrapper around [NotificationListenerService] to enable unit testing
/// and safe cross-platform degradation on non-Android platforms.
abstract class NotificationListenerWrapper {
  /// Checks whether Notification Listener access (Special App Access) is granted in Android system settings.
  Future<bool> isPermissionGranted();

  /// Prompts the Android system settings page for Notification Listener access (Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).
  Future<bool> requestPermission();

  /// Streams incoming system notifications posted by external apps.
  Stream<ServiceNotificationEvent> get notificationsStream;
}

/// Default implementation of [NotificationListenerWrapper] delegating to [NotificationListenerService].
class DefaultNotificationListenerWrapper implements NotificationListenerWrapper {
  const DefaultNotificationListenerWrapper();

  @override
  Future<bool> isPermissionGranted() async {
    if (!Platform.isAndroid) return false;
    try {
      return await NotificationListenerService.isPermissionGranted();
    } catch (e) {
      debugPrint('Failed to check notification listener permission: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await NotificationListenerService.requestPermission();
    } catch (e) {
      debugPrint('Failed to request notification listener permission: $e');
      return false;
    }
  }

  @override
  Stream<ServiceNotificationEvent> get notificationsStream {
    if (!Platform.isAndroid) return const Stream.empty();
    try {
      return NotificationListenerService.notificationsStream;
    } catch (e) {
      debugPrint('Failed to access notifications stream: $e');
      return const Stream.empty();
    }
  }
}

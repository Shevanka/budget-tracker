import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/notification_channels.dart';

/// Contract for displaying local notifications and managing channels.
abstract class NotificationService {
  /// Whether the notification service has been initialized.
  bool get isInitialized;

  /// Initializes the local notification plugin and configures Android channels.
  Future<bool> initialize({
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  });

  /// Requests notification permissions (primarily Android 13+ and iOS).
  Future<bool> requestPermission();

  /// Checks whether notification permission is currently granted.
  Future<bool> isPermissionGranted();

  /// Displays an 80% budget threshold warning notification.
  Future<void> showBudgetWarning({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  /// Displays a 100% budget threshold exceeded alert notification.
  Future<void> showBudgetExceeded({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  /// Displays a reminder or review notification.
  Future<void> showReminder({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  /// Cancels an active notification by id.
  Future<void> cancel(int id);

  /// Cancels all active notifications.
  Future<void> cancelAll();
}

/// Default implementation of [NotificationService] using [FlutterLocalNotificationsPlugin].
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  LocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<bool> initialize({
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
  }) async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    try {
      final initialized = await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      );

      // Register Android notification channels
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        for (final channel in NotificationChannels.allChannels) {
          await androidPlugin.createNotificationChannel(channel);
        }
      }

      _isInitialized = initialized ?? true;
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize local notifications: $e');
      _isInitialized = false;
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }

      return false;
    } catch (e) {
      debugPrint('Failed to request notification permission: $e');
      return false;
    }
  }

  @override
  Future<bool> isPermissionGranted() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        return enabled ?? false;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showBudgetWarning({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: NotificationChannels.warningDetails,
    );
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show budget warning notification: $e');
    }
  }

  @override
  Future<void> showBudgetExceeded({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: NotificationChannels.exceededDetails,
    );
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show budget exceeded notification: $e');
    }
  }

  @override
  Future<void> showReminder({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const details = NotificationDetails(
      android: NotificationChannels.reminderDetails,
    );
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show reminder notification: $e');
    }
  }

  @override
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Failed to cancel notification $id: $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }
}

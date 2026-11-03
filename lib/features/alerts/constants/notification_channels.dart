import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Centralized notification channels and details configuration for Android.
abstract final class NotificationChannels {
  /// Channel for 80% budget threshold warning alerts.
  static const budgetWarning = AndroidNotificationChannel(
    'budget_warnings',
    'Budget Warnings (80%)',
    description: 'Notifications when spending reaches 80% of budget limits',
    importance: Importance.high,
  );

  /// Channel for 100% budget threshold exceeded alerts.
  static const budgetExceeded = AndroidNotificationChannel(
    'budget_exceeded',
    'Budget Exceeded (100%)',
    description: 'Critical alerts when spending exceeds 100% of budget limits',
    importance: Importance.max,
  );

  /// Channel for daily reminders and review notifications.
  static const budgetReminder = AndroidNotificationChannel(
    'budget_reminders',
    'Budget Reminders',
    description: 'Daily reminders and review notifications',
    importance: Importance.defaultImportance,
  );

  /// All notification channels registered with the system.
  static const allChannels = [
    budgetWarning,
    budgetExceeded,
    budgetReminder,
  ];

  /// Android notification details for 80% warning alerts.
  static const warningDetails = AndroidNotificationDetails(
    'budget_warnings',
    'Budget Warnings (80%)',
    channelDescription: 'Notifications when spending reaches 80% of budget limits',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  /// Android notification details for 100% exceeded alerts.
  static const exceededDetails = AndroidNotificationDetails(
    'budget_exceeded',
    'Budget Exceeded (100%)',
    channelDescription: 'Critical alerts when spending exceeds 100% of budget limits',
    importance: Importance.max,
    priority: Priority.max,
    icon: '@mipmap/ic_launcher',
  );

  /// Android notification details for reminders.
  static const reminderDetails = AndroidNotificationDetails(
    'budget_reminders',
    'Budget Reminders',
    channelDescription: 'Daily reminders and review notifications',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: '@mipmap/ic_launcher',
  );
}

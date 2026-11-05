import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/preferences_service.dart';
import '../../../database/database_provider.dart';
import '../../alerts/providers/alerts_provider.dart';
import '../models/smart_reminder_status.dart';
import '../services/smart_reminder_service.dart';

/// Preference key for the smart reminder toggle.
const smartReminderEnabledPrefKey = 'smart_reminder_enabled';

/// Preference key for smart reminder hour.
const smartReminderHourPrefKey = 'smart_reminder_hour';

/// Preference key for smart reminder minute.
const smartReminderMinutePrefKey = 'smart_reminder_minute';

/// Provides the active [SmartReminderService] instance.
final smartReminderServiceProvider = Provider<SmartReminderService>((ref) {
  final db = ref.watch(databaseProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final service = SmartReminderService(
    db: db,
    notificationService: notificationService,
  );
  ref.onDispose(service.dispose);
  return service;
});

/// State notifier managing whether daily smart spending reminders are enabled.
/// Persisted in [preferencesServiceProvider] (defaults to true).
class SmartReminderEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.getBool(smartReminderEnabledPrefKey, defaultValue: true);
  }

  void setEnabled(bool enabled) {
    state = enabled;
  }

  @override
  set state(bool value) {
    super.state = value;
    ref.read(preferencesServiceProvider).setBool(smartReminderEnabledPrefKey, value);
  }
}

/// Provides the enabled state of the daily smart spending reminder.
final smartReminderEnabledProvider =
    NotifierProvider<SmartReminderEnabledNotifier, bool>(
  SmartReminderEnabledNotifier.new,
);

/// State notifier managing the configured daily reminder time.
/// Persisted in [preferencesServiceProvider] (defaults to 20:00 / 8 PM).
class SmartReminderTimeNotifier extends Notifier<TimeOfDay> {
  @override
  TimeOfDay build() {
    final prefs = ref.watch(preferencesServiceProvider);
    final hour = prefs.getInt(smartReminderHourPrefKey, defaultValue: 20);
    final minute = prefs.getInt(smartReminderMinutePrefKey, defaultValue: 0);
    return TimeOfDay(hour: hour, minute: minute);
  }

  void setTime(TimeOfDay time) {
    state = time;
  }

  @override
  set state(TimeOfDay value) {
    super.state = value;
    ref.read(preferencesServiceProvider).setInt(smartReminderHourPrefKey, value.hour);
    ref.read(preferencesServiceProvider).setInt(smartReminderMinutePrefKey, value.minute);
  }
}

/// Provides the configured reminder time (defaults to 20:00 / 8 PM).
final smartReminderTimeProvider =
    NotifierProvider<SmartReminderTimeNotifier, TimeOfDay>(
  SmartReminderTimeNotifier.new,
);

/// Evaluates today's transaction status for smart reminders asynchronously.
final smartReminderStatusProvider =
    FutureProvider.autoDispose<SmartReminderStatus>((ref) async {
  final service = ref.watch(smartReminderServiceProvider);
  return service.evaluateAndRemind();
});

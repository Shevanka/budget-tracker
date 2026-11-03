import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_provider.dart';
import '../../alerts/providers/alerts_provider.dart';
import '../models/smart_reminder_status.dart';
import '../services/smart_reminder_service.dart';

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

/// State provider indicating whether daily smart spending reminders are enabled.
/// Defaults to true (opt-in by default for helpful assistance).
final smartReminderEnabledProvider = StateProvider<bool>((ref) => true);

/// State provider for the configured reminder time (defaults to 20:00 / 8 PM).
final smartReminderTimeProvider =
    StateProvider<TimeOfDay>((ref) => const TimeOfDay(hour: 20, minute: 0));

/// Evaluates today's transaction status for smart reminders asynchronously.
final smartReminderStatusProvider =
    FutureProvider.autoDispose<SmartReminderStatus>((ref) async {
  final service = ref.watch(smartReminderServiceProvider);
  return service.evaluateAndRemind();
});

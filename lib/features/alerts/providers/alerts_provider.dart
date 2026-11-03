import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../budget/providers/budget_provider.dart';
import '../services/budget_alert_service.dart';
import '../services/notification_service.dart';

/// Provides the active [NotificationService] instance.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});

/// Provides the active [BudgetAlertService] singleton for tracking and triggering budget alerts.
final budgetAlertServiceProvider = Provider<BudgetAlertService>((ref) {
  final budgetService = ref.watch(budgetServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return BudgetAlertService(
    budgetService: budgetService,
    notificationService: notificationService,
  );
});

/// Tracks whether the user dismissed the notification permission prompt banner during this app session.
final notificationPermissionDismissedProvider = StateProvider<bool>((ref) => false);

/// State notifier managing the runtime notification permission status (Android 13+ POST_NOTIFICATIONS).
class NotificationPermissionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final service = ref.watch(notificationServiceProvider);
    return service.isPermissionGranted();
  }

  /// Requests the runtime POST_NOTIFICATIONS permission and updates state.
  Future<bool> requestPermission() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(notificationServiceProvider);
      final granted = await service.requestPermission();
      state = AsyncValue.data(granted);
      return granted;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Refreshes permission status from the system (e.g. after returning from OS settings).
  Future<void> refresh() async {
    try {
      final service = ref.read(notificationServiceProvider);
      final granted = await service.isPermissionGranted();
      state = AsyncValue.data(granted);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provides reactive notification permission state (true if granted, false otherwise).
final notificationPermissionProvider =
    AsyncNotifierProvider<NotificationPermissionNotifier, bool>(
  NotificationPermissionNotifier.new,
);

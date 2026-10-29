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

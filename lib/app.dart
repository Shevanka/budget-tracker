import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';
import 'core/utils/currency_formatter.dart';
import 'features/alerts/providers/alerts_provider.dart';
import 'features/notification_watcher/providers/notification_watcher_provider.dart';
import 'features/notification_watcher/services/notification_watcher_service.dart';
import 'routing/app_router.dart';

/// Root application widget configuring MaterialApp.router, AppTheme,
/// and maintaining active root listeners (such as the bank/e-wallet notification watcher).
class BudgetTrackerApp extends ConsumerWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly maintain an active listener for incoming financial notifications.
    // When a transaction is automatically captured, a local notification banner is triggered.
    ref.listen<AsyncValue<IncomingNotificationPayload>>(
      processedIncomingNotificationProvider,
      (previous, next) {
        final payload = next.valueOrNull;
        if (payload != null && payload.isTransaction) {
          final parsed = payload.parsed;
          if (parsed != null) {
            final notificationService = ref.read(notificationServiceProvider);
            final formatted = CurrencyFormatter.format(
              parsed.amount,
              includeSymbol: true,
            );
            notificationService.showReminder(
              id: payload.log.id.hashCode,
              title: 'Transaksi Terdeteksi: ${parsed.source}',
              body: '$formatted di ${parsed.merchant}. Ketuk untuk meninjau.',
              payload: '/smart-recording/review',
            );
          }
        }
      },
    );

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Budget Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

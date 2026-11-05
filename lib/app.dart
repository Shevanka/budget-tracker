import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme.dart';
import 'core/utils/currency_formatter.dart';
import 'features/alerts/providers/alerts_provider.dart';
import 'features/notification_watcher/providers/notification_watcher_provider.dart';
import 'features/notification_watcher/services/notification_watcher_service.dart';
import 'routing/app_router.dart';

/// Root application widget configuring MaterialApp.router, AppTheme,
/// and maintaining active root listeners and lifecycle observers for
/// the bank/e-wallet notification watcher.
class BudgetTrackerApp extends ConsumerStatefulWidget {
  const BudgetTrackerApp({super.key});

  @override
  ConsumerState<BudgetTrackerApp> createState() => _BudgetTrackerAppState();
}

class _BudgetTrackerAppState extends ConsumerState<BudgetTrackerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial sync of active notifications sitting in the drawer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncDrawerNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationAccessPermissionProvider.notifier).refresh();
      _syncDrawerNotifications();
    }
  }

  Future<void> _syncDrawerNotifications() async {
    final isEnabled = ref.read(notificationWatcherEnabledProvider);
    if (!isEnabled) return;

    try {
      final wrapper = ref.read(notificationListenerWrapperProvider);
      final watcher = ref.read(notificationWatcherServiceProvider);
      final watchedPackages = ref.read(watchedPackagesProvider);

      final activeEvents = await wrapper.getActiveNotifications();
      for (final event in activeEvents) {
        final payload = await watcher.processEvent(
          event,
          watchedPackages: watchedPackages,
        );
        if (payload != null && payload.isTransaction) {
          _triggerAlertNotification(payload);
        }
      }
    } catch (_) {}
  }

  void _triggerAlertNotification(IncomingNotificationPayload payload) {
    final parsed = payload.parsed;
    if (parsed == null) return;

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

  @override
  Widget build(BuildContext context) {
    // Eagerly maintain an active listener for incoming financial notifications in real time.
    ref.listen<AsyncValue<IncomingNotificationPayload>>(
      processedIncomingNotificationProvider,
      (previous, next) {
        final payload = next.valueOrNull;
        if (payload != null && payload.isTransaction) {
          _triggerAlertNotification(payload);
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

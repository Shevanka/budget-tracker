import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';
import '../../../alerts/providers/alerts_provider.dart';
import '../../../notification_watcher/presentation/widgets/notification_access_dialog.dart';
import '../../../notification_watcher/providers/notification_watcher_provider.dart';

/// Settings screen providing links to budget and category management,
/// and toggles/permission controls for budget threshold notifications (Android 13+)
/// and the bank/e-wallet notification watcher (Special App Access).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationPermissionProvider.notifier).refresh();
      ref.read(notificationAccessPermissionProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Budget alerts permission
    final alertPermissionAsync = ref.watch(notificationPermissionProvider);
    final isAlertPermissionGranted = alertPermissionAsync.valueOrNull ?? false;

    // Notification watcher access permission & toggle
    final accessPermissionAsync = ref.watch(notificationAccessPermissionProvider);
    final hasNotificationAccess = accessPermissionAsync.valueOrNull ?? false;
    final isWatcherEnabled = ref.watch(notificationWatcherEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Section: Budget & Data
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Budget & Data',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categories'),
            subtitle: const Text('Manage spending and income categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoute.categoryManager.path),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: const Text('Budget Setup'),
            subtitle: const Text('Configure monthly budget limits'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoute.budgetSetup.path),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.document_scanner_outlined),
            title: const Text('Smart Recording Review'),
            subtitle: const Text('Review intercepted notifications and receipts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoute.smartRecordingReview.path),
          ),
          const Divider(),

          // Section: Notifications & Alerts (Android 13+ POST_NOTIFICATIONS)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Notifications & Alerts',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            secondary: Icon(
              isAlertPermissionGranted
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
            ),
            title: const Text('Budget Alert Notifications'),
            subtitle: Text(
              isAlertPermissionGranted
                  ? 'Enabled — 80% warning and 100% exceeded alerts active'
                  : 'Disabled — tap to request notification permission',
            ),
            value: isAlertPermissionGranted,
            onChanged: (value) async {
              if (value) {
                final granted = await ref
                    .read(notificationPermissionProvider.notifier)
                    .requestPermission();
                if (!granted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notification permission was denied. Please enable it in system settings.',
                      ),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'To disable notifications, please adjust permissions in system settings.',
                      ),
                    ),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.notification_add_outlined),
            title: const Text('Test Budget Alert'),
            subtitle: const Text('Send a sample 80% threshold notification'),
            enabled: isAlertPermissionGranted,
            onTap: isAlertPermissionGranted
                ? () async {
                    await ref.read(notificationServiceProvider).showBudgetWarning(
                          id: 999999,
                          title: 'Peringatan Anggaran: Simulasi',
                          body:
                              'Pengeluaran untuk Makanan telah mencapai 85% (Rp 850.000 dari Rp 1.000.000).',
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test notification sent!'),
                        ),
                      );
                    }
                  }
                : null,
          ),
          const Divider(),

          // Section: Notification Watcher (Bank & E-Wallet Auto-Recording)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Notification Watcher (Auto-Record)',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            secondary: Icon(
              hasNotificationAccess && isWatcherEnabled
                  ? Icons.mark_email_read_outlined
                  : Icons.mark_email_unread_outlined,
            ),
            title: const Text('Bank & E-Wallet Watcher'),
            subtitle: Text(
              !hasNotificationAccess
                  ? 'Access required — tap to grant Notification Access'
                  : isWatcherEnabled
                      ? 'Active — auto-capturing BCA, Mandiri, BNI, GoPay, etc.'
                      : 'Paused — toggle to enable automatic transaction capture',
            ),
            value: isWatcherEnabled && hasNotificationAccess,
            onChanged: (value) async {
              if (value) {
                if (!hasNotificationAccess) {
                  await NotificationAccessDialog.show(context);
                } else {
                  ref.read(notificationWatcherEnabledProvider.notifier).state = true;
                }
              } else {
                ref.read(notificationWatcherEnabledProvider.notifier).state = false;
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Notification Access Status'),
            subtitle: Text(
              hasNotificationAccess
                  ? 'Granted — passive & battery-efficient listener'
                  : 'Not Granted — special Android permission required',
            ),
            trailing: hasNotificationAccess
                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                : TextButton(
                    onPressed: () => NotificationAccessDialog.show(context),
                    child: const Text('Grant'),
                  ),
            onTap: !hasNotificationAccess
                ? () => NotificationAccessDialog.show(context)
                : null,
          ),
        ],
      ),
    );
  }
}

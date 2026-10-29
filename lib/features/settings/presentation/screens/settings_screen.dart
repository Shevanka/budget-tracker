import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';
import '../../../alerts/providers/alerts_provider.dart';

/// Settings screen providing links to budget and category management,
/// and toggles/permission controls for budget threshold notifications (Android 13+).
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final permissionAsync = ref.watch(notificationPermissionProvider);
    final isGranted = permissionAsync.valueOrNull ?? false;

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
              isGranted
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
            ),
            title: const Text('Budget Alert Notifications'),
            subtitle: Text(
              isGranted
                  ? 'Enabled — 80% warning and 100% exceeded alerts active'
                  : 'Disabled — tap to request notification permission',
            ),
            value: isGranted,
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
            enabled: isGranted,
            onTap: isGranted
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
        ],
      ),
    );
  }
}

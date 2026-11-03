import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/watched_apps.dart';
import '../../providers/notification_watcher_provider.dart';

/// Modal dialog allowing the user to selectively enable or disable individual
/// Indonesian bank and e-wallet applications watched by the notification service.
class WatchedAppsDialog extends ConsumerWidget {
  const WatchedAppsDialog({super.key});

  /// Displays the [WatchedAppsDialog].
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const WatchedAppsDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enabledAppIds = ref.watch(enabledWatchedAppIdsProvider);
    final notifier = ref.read(enabledWatchedAppIdsProvider.notifier);

    final bankApps = WatchedApps.allApps
        .where((a) => a.type == InstitutionType.bank)
        .toList();
    final eWalletApps = WatchedApps.allApps
        .where((a) => a.type == InstitutionType.eWallet)
        .toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.apps_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aplikasi Dipantau',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${enabledAppIds.length} dari ${WatchedApps.allApps.length} aktif',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.65,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              // Quick action buttons: Select All / Deselect All
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: notifier.selectAll,
                      icon: const Icon(Icons.select_all_rounded, size: 18),
                      label: const Text('Pilih Semua'),
                    ),
                    TextButton.icon(
                      onPressed: notifier.deselectAll,
                      icon: const Icon(Icons.deselect_rounded, size: 18),
                      label: const Text('Hapus Semua'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Section: Perbankan (Banks)
              _buildSectionHeader(
                context,
                title: 'Perbankan',
                icon: Icons.account_balance_outlined,
              ),
              ...bankApps.map(
                (app) => _buildAppTile(
                  context,
                  app: app,
                  isEnabled: enabledAppIds.contains(app.id),
                  onChanged: (val) => notifier.setEnabled(app.id, val ?? false),
                ),
              ),

              const SizedBox(height: 8),

              // Section: E-Wallet
              _buildSectionHeader(
                context,
                title: 'E-Wallet',
                icon: Icons.account_balance_wallet_outlined,
              ),
              ...eWalletApps.map(
                (app) => _buildAppTile(
                  context,
                  app: app,
                  isEnabled: enabledAppIds.contains(app.id),
                  onChanged: (val) => notifier.setEnabled(app.id, val ?? false),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Selesai'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppTile(
    BuildContext context, {
    required WatchedApp app,
    required bool isEnabled,
    required ValueChanged<bool?> onChanged,
  }) {
    final theme = Theme.of(context);

    return CheckboxListTile(
      value: isEnabled,
      onChanged: onChanged,
      title: Text(
        app.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        app.packageNames.join(', '),
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 11,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      dense: true,
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

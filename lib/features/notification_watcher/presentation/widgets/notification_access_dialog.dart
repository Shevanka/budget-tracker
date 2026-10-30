import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notification_watcher_provider.dart';

/// Informational dialog guiding the user through granting Android's Special App Access
/// (Notification Listener Permission) with transparent rationale and privacy guarantees.
class NotificationAccessDialog extends ConsumerWidget {
  const NotificationAccessDialog({super.key});

  /// Displays the [NotificationAccessDialog] modal.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const NotificationAccessDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
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
              Icons.notifications_active_outlined,
              color: colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Akses Notifikasi',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Untuk mendeteksi transaksi secara otomatis dari bank dan e-wallet, '
              'Budget Tracker memerlukan izin Akses Notifikasi di Pengaturan Android.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Feature points
            _buildFeatureTile(
              context,
              icon: Icons.auto_awesome_outlined,
              title: 'Pencatatan Otomatis',
              subtitle: 'Deteksi otomatis notifikasi BCA, Mandiri, BNI, GoPay, OVO, DANA, dll.',
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(
              context,
              icon: Icons.lock_outline,
              title: 'Privasi & Offline 100%',
              subtitle: 'Data notifikasi dianalisis langsung di ponsel Anda dan tidak pernah dikirim ke internet.',
            ),
            const SizedBox(height: 10),
            _buildFeatureTile(
              context,
              icon: Icons.battery_charging_full_outlined,
              title: 'Efisien & Hemat Baterai',
              subtitle: 'Layanan bersifat pasif (event-driven) tanpa proses background yang menguras baterai.',
            ),
            const SizedBox(height: 16),

            // Step-by-step
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Langkah Aktivasi:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '1. Ketuk "Buka Pengaturan" di bawah.\n'
                    '2. Temukan dan pilih "Budget Tracker".\n'
                    '3. Aktifkan sakelar "Izinkan akses notifikasi".',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: () async {
            Navigator.of(context).pop(true);
            await ref
                .read(notificationAccessPermissionProvider.notifier)
                .requestPermission();
          },
          icon: const Icon(Icons.settings_outlined, size: 18),
          label: const Text('Buka Pengaturan'),
        ),
      ],
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

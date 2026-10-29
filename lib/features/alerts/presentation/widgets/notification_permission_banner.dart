import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/alerts_provider.dart';

/// A Material 3 banner card prompting the user to grant POST_NOTIFICATIONS permission
/// on Android 13+ with an explanation of budget threshold warnings (80% / 100%).
class NotificationPermissionBanner extends ConsumerWidget {
  const NotificationPermissionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDismissed = ref.watch(notificationPermissionDismissedProvider);
    if (isDismissed) {
      return const SizedBox.shrink();
    }

    final permissionAsync = ref.watch(notificationPermissionProvider);

    return permissionAsync.when(
      data: (isGranted) {
        if (isGranted) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            color: colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aktifkan Notifikasi Anggaran',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dapatkan peringatan otomatis saat pengeluaran Anda mencapai 80% atau melebihi 100% dari batas anggaran.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: 'Tutup',
                        onPressed: () {
                          ref
                              .read(notificationPermissionDismissedProvider.notifier)
                              .state = true;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          ref
                              .read(notificationPermissionDismissedProvider.notifier)
                              .state = true;
                        },
                        child: const Text('Nanti Saja'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () async {
                          final granted = await ref
                              .read(notificationPermissionProvider.notifier)
                              .requestPermission();
                          if (context.mounted && !granted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Izin notifikasi tidak diberikan. Anda dapat mengaktifkannya di Pengaturan.',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Aktifkan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

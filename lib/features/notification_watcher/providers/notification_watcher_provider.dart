import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_listener_service/notification_event.dart';

import '../constants/watched_apps.dart';
import '../services/notification_listener_wrapper.dart';

/// Provides the active [NotificationListenerWrapper] instance.
final notificationListenerWrapperProvider = Provider<NotificationListenerWrapper>((ref) {
  return const DefaultNotificationListenerWrapper();
});

/// Controls whether the notification watcher is globally enabled by the user in Settings.
final notificationWatcherEnabledProvider = StateProvider<bool>((ref) => false);

/// Set of application package names currently selected to be watched.
final watchedPackagesProvider = StateProvider<Set<String>>((ref) {
  return Set<String>.from(WatchedApps.allPackageNames);
});

/// State notifier managing the Android Notification Access (Special App Access) permission state.
class NotificationAccessPermissionNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final wrapper = ref.watch(notificationListenerWrapperProvider);
    return wrapper.isPermissionGranted();
  }

  /// Requests Notification Access by launching the Android Special App Access settings page.
  Future<bool> requestPermission() async {
    state = const AsyncValue.loading();
    try {
      final wrapper = ref.read(notificationListenerWrapperProvider);
      final granted = await wrapper.requestPermission();
      state = AsyncValue.data(granted);
      return granted;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Refreshes the permission status (e.g. after returning from Android system settings).
  Future<void> refresh() async {
    try {
      final wrapper = ref.read(notificationListenerWrapperProvider);
      final granted = await wrapper.isPermissionGranted();
      state = AsyncValue.data(granted);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provides the current status of the Android Notification Access permission.
final notificationAccessPermissionProvider =
    AsyncNotifierProvider<NotificationAccessPermissionNotifier, bool>(
  NotificationAccessPermissionNotifier.new,
);

/// Streams incoming notification events from [notificationListenerWrapperProvider]
/// only when notification watcher is enabled and permission is granted.
final rawIncomingNotificationsStreamProvider =
    StreamProvider.autoDispose<ServiceNotificationEvent>((ref) {
  final isEnabled = ref.watch(notificationWatcherEnabledProvider);
  final isGrantedAsync = ref.watch(notificationAccessPermissionProvider);
  final isGranted = isGrantedAsync.valueOrNull ?? false;

  if (!isEnabled || !isGranted) {
    return const Stream.empty();
  }

  final wrapper = ref.watch(notificationListenerWrapperProvider);
  return wrapper.notificationsStream;
});

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_listener_service/notification_event.dart';

import '../../../database/app_database.dart';
import '../../../database/database_provider.dart';
import '../constants/watched_apps.dart';
import '../services/notification_listener_wrapper.dart';
import '../services/notification_log_service.dart';
import '../services/notification_parser.dart';
import '../services/notification_watcher_service.dart';

/// Provides the [NotificationParser] instance for parsing Indonesian bank and e-wallet notifications.
final notificationParserProvider = Provider<NotificationParser>((ref) {
  return const NotificationParser();
});

/// Provides the active [NotificationListenerWrapper] instance.
final notificationListenerWrapperProvider =
    Provider<NotificationListenerWrapper>((ref) {
  return const DefaultNotificationListenerWrapper();
});

/// Controls whether the notification watcher is globally enabled by the user in Settings.
final notificationWatcherEnabledProvider = StateProvider<bool>((ref) => false);

/// State notifier managing which Indonesian banks and e-wallets are watched.
class EnabledWatchedAppsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return {for (final app in WatchedApps.allApps) app.id};
  }

  /// Toggles whether institution [appId] is watched.
  void toggle(String appId) {
    if (state.contains(appId)) {
      state = Set.of(state)..remove(appId);
    } else {
      state = Set.of(state)..add(appId);
    }
  }

  /// Explicitly sets whether institution [appId] is watched.
  void setEnabled(String appId, bool enabled) {
    if (enabled) {
      if (!state.contains(appId)) {
        state = Set.of(state)..add(appId);
      }
    } else {
      if (state.contains(appId)) {
        state = Set.of(state)..remove(appId);
      }
    }
  }

  /// Enables all registered banking and e-wallet applications.
  void selectAll() {
    state = {for (final app in WatchedApps.allApps) app.id};
  }

  /// Deselects all applications.
  void deselectAll() {
    state = const {};
  }
}

/// Provides the set of institution IDs currently enabled for notification capture.
final enabledWatchedAppIdsProvider =
    NotifierProvider<EnabledWatchedAppsNotifier, Set<String>>(
  EnabledWatchedAppsNotifier.new,
);

/// Set of application package names currently selected to be watched.
/// Dynamically computed from [enabledWatchedAppIdsProvider].
final watchedPackagesProvider = Provider<Set<String>>((ref) {
  final enabledIds = ref.watch(enabledWatchedAppIdsProvider);
  final packages = <String>{};
  for (final app in WatchedApps.allApps) {
    if (enabledIds.contains(app.id)) {
      for (final pkg in app.packageNames) {
        packages.add(pkg.toLowerCase());
      }
    }
  }
  return packages;
});

/// Provides the [NotificationLogService] for logging and querying notification logs.
final notificationLogServiceProvider = Provider<NotificationLogService>((ref) {
  final dao = ref.watch(notificationLogDaoProvider);
  return NotificationLogService(dao);
});

/// Provides the [NotificationWatcherService] for orchestrating ingestion and parsing.
final notificationWatcherServiceProvider =
    Provider<NotificationWatcherService>((ref) {
  final logService = ref.watch(notificationLogServiceProvider);
  final parser = ref.watch(notificationParserProvider);
  return NotificationWatcherService(
    logService: logService,
    parser: parser,
  );
});

/// Streams unparsed notification logs in real time from the database.
final unparsedNotificationLogsStreamProvider =
    StreamProvider.autoDispose<List<NotificationLog>>((ref) {
  final service = ref.watch(notificationLogServiceProvider);
  return service.watchUnparsedLogs();
});

/// Streams all notification logs in real time from the database.
final allNotificationLogsStreamProvider =
    StreamProvider.autoDispose<List<NotificationLog>>((ref) {
  final service = ref.watch(notificationLogServiceProvider);
  return service.watchAllLogs();
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

/// Ingests incoming notifications into `notification_logs`, parses them, and emits
/// [IncomingNotificationPayload] for auto-recording review.
final processedIncomingNotificationProvider =
    StreamProvider.autoDispose<IncomingNotificationPayload>((ref) {
  final controller = StreamController<IncomingNotificationPayload>();
  ref.onDispose(controller.close);

  final watcher = ref.watch(notificationWatcherServiceProvider);
  final watchedPackages = ref.watch(watchedPackagesProvider);

  ref.listen<AsyncValue<ServiceNotificationEvent>>(
    rawIncomingNotificationsStreamProvider,
    (_, next) async {
      final event = next.valueOrNull;
      if (event != null) {
        final payload = await watcher.processEvent(
          event,
          watchedPackages: watchedPackages,
        );
        if (payload != null && !controller.isClosed) {
          controller.add(payload);
        }
      }
    },
  );

  return controller.stream;
});

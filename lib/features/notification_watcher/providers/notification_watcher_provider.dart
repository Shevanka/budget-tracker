import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_listener_service/notification_event.dart';

import '../../../core/services/preferences_service.dart';
import '../../../database/app_database.dart';
import '../../../database/database_provider.dart';
import '../constants/watched_apps.dart';
import '../services/notification_listener_wrapper.dart';
import '../services/notification_log_service.dart';
import '../services/notification_parser.dart';
import '../services/notification_watcher_service.dart';

/// Preference key for the notification watcher master switch.
const notificationWatcherEnabledPrefKey = 'notification_watcher_enabled';

/// Preference key for enabled watched institutions.
const enabledWatchedAppIdsPrefKey = 'enabled_watched_app_ids';

/// Provides the [NotificationParser] instance for parsing Indonesian bank and e-wallet notifications.
final notificationParserProvider = Provider<NotificationParser>((ref) {
  return const NotificationParser();
});

/// Provides the active [NotificationListenerWrapper] instance.
final notificationListenerWrapperProvider =
    Provider<NotificationListenerWrapper>((ref) {
  return const DefaultNotificationListenerWrapper();
});

/// State notifier managing whether the notification watcher is globally enabled.
/// Backed by [preferencesServiceProvider] so the setting persists across app restarts.
class NotificationWatcherEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.getBool(notificationWatcherEnabledPrefKey, defaultValue: false);
  }

  /// Sets whether the watcher is active and persists the choice.
  void setEnabled(bool enabled) {
    state = enabled;
  }

  /// Supports direct state assignment e.g. `ref.read(...notifier).state = true`.
  @override
  set state(bool value) {
    super.state = value;
    ref.read(preferencesServiceProvider).setBool(notificationWatcherEnabledPrefKey, value);
  }
}

/// Provides the globally enabled state of the notification watcher.
final notificationWatcherEnabledProvider =
    NotifierProvider<NotificationWatcherEnabledNotifier, bool>(
  NotificationWatcherEnabledNotifier.new,
);

/// State notifier managing which Indonesian banks and e-wallets are watched.
/// Persisted in [preferencesServiceProvider] so custom selections persist across app restarts.
class EnabledWatchedAppsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final prefs = ref.watch(preferencesServiceProvider);
    final saved = prefs.getStringList(enabledWatchedAppIdsPrefKey);
    if (saved != null) {
      return saved.toSet();
    }
    return {for (final app in WatchedApps.allApps) app.id};
  }

  void _persist(Set<String> newSet) {
    state = newSet;
    ref.read(preferencesServiceProvider).setStringList(
      enabledWatchedAppIdsPrefKey,
      newSet.toList(),
    );
  }

  /// Toggles whether institution [appId] is watched.
  void toggle(String appId) {
    final updated = Set.of(state);
    if (updated.contains(appId)) {
      updated.remove(appId);
    } else {
      updated.add(appId);
    }
    _persist(updated);
  }

  /// Explicitly sets whether institution [appId] is watched.
  void setEnabled(String appId, bool enabled) {
    final updated = Set.of(state);
    if (enabled) {
      updated.add(appId);
    } else {
      updated.remove(appId);
    }
    _persist(updated);
  }

  /// Enables all registered banking and e-wallet applications.
  void selectAll() {
    _persist({for (final app in WatchedApps.allApps) app.id});
  }

  /// Deselects all applications.
  void deselectAll() {
    _persist(const {});
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
    StreamProvider<ServiceNotificationEvent>((ref) {
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
    StreamProvider<IncomingNotificationPayload>((ref) {
  final controller = StreamController<IncomingNotificationPayload>();
  ref.onDispose(controller.close);

  final watcher = ref.watch(notificationWatcherServiceProvider);
  final watchedPackages = ref.watch(watchedPackagesProvider);
  final wrapper = ref.watch(notificationListenerWrapperProvider);

  // Perform an eager scan of any active notifications sitting in the status bar
  Future.microtask(() async {
    final isEnabled = ref.read(notificationWatcherEnabledProvider);
    if (!isEnabled) return;
    try {
      final activeList = await wrapper.getActiveNotifications();
      for (final event in activeList) {
        final payload = await watcher.processEvent(
          event,
          watchedPackages: watchedPackages,
        );
        if (payload != null && !controller.isClosed) {
          controller.add(payload);
        }
      }
    } catch (_) {}
  });

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

/// Checks active notifications currently sitting in the Android notification drawer,
/// logs and parses any financial transactions, and returns them.
final syncActiveNotificationsProvider =
    FutureProvider.autoDispose<List<IncomingNotificationPayload>>((ref) async {
  final isEnabled = ref.watch(notificationWatcherEnabledProvider);
  if (!isEnabled) return const [];

  final isGrantedAsync = ref.watch(notificationAccessPermissionProvider);
  final isGranted = isGrantedAsync.valueOrNull ?? false;
  if (!isGranted) return const [];

  final wrapper = ref.watch(notificationListenerWrapperProvider);
  final watcher = ref.watch(notificationWatcherServiceProvider);
  final watchedPackages = ref.watch(watchedPackagesProvider);

  final activeList = await wrapper.getActiveNotifications();
  final results = <IncomingNotificationPayload>[];

  for (final event in activeList) {
    final payload = await watcher.processEvent(
      event,
      watchedPackages: watchedPackages,
    );
    if (payload != null && payload.isTransaction) {
      results.add(payload);
    }
  }

  return results;
});

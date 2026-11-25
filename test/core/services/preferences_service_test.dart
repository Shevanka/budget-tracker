import 'package:budget_tracker/core/services/preferences_service.dart';
import 'package:budget_tracker/features/notification_watcher/constants/watched_apps.dart';
import 'package:budget_tracker/features/notification_watcher/providers/notification_watcher_provider.dart';
import 'package:budget_tracker/features/smart_recording/providers/smart_reminder_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreferencesService & State Persistence Across App Restarts', () {
    test('notificationWatcherEnabledProvider persists true state across container restarts', () {
      final sharedStorage = InMemoryPreferencesService();

      // Session 1: User launches app for the first time
      var container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(sharedStorage),
        ],
      );

      // Initially false
      expect(container.read(notificationWatcherEnabledProvider), isFalse);

      // User toggles ON in Settings
      container.read(notificationWatcherEnabledProvider.notifier).setEnabled(true);
      expect(container.read(notificationWatcherEnabledProvider), isTrue);

      // App is closed / killed
      container.dispose();

      // Session 2: User launches app again
      container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(sharedStorage),
        ],
      );
      addTearDown(container.dispose);

      // Value remains TRUE across app close and restart!
      expect(container.read(notificationWatcherEnabledProvider), isTrue);
    });

    test('enabledWatchedAppIdsProvider persists custom selections across restarts', () {
      final sharedStorage = InMemoryPreferencesService();

      // Session 1: App first launch
      var container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(sharedStorage),
        ],
      );

      // Initially all apps active
      expect(container.read(enabledWatchedAppIdsProvider).length, equals(WatchedApps.allApps.length));

      // User disables GoPay and OVO
      container.read(enabledWatchedAppIdsProvider.notifier).toggle('gopay');
      container.read(enabledWatchedAppIdsProvider.notifier).toggle('ovo');

      expect(container.read(enabledWatchedAppIdsProvider), isNot(contains('gopay')));
      expect(container.read(enabledWatchedAppIdsProvider), isNot(contains('ovo')));

      // App is closed / killed
      container.dispose();

      // Session 2: App launched next day
      container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(sharedStorage),
        ],
      );
      addTearDown(container.dispose);

      // Selections are preserved!
      final restored = container.read(enabledWatchedAppIdsProvider);
      expect(restored, isNot(contains('gopay')));
      expect(restored, isNot(contains('ovo')));
      expect(restored, contains('bca'));
    });

    test('smart reminder toggle and time persist across restarts', () {
      final sharedStorage = InMemoryPreferencesService();

      var container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(sharedStorage),
        ],
      );

      expect(container.read(smartReminderEnabledProvider), isTrue);
      expect(container.read(smartReminderTimeProvider), equals(const TimeOfDay(hour: 20, minute: 0)));

      // User updates settings: disables reminder and sets time to 21:30
      container.read(smartReminderEnabledProvider.notifier).setEnabled(false);
      container.read(smartReminderTimeProvider.notifier).setTime(const TimeOfDay(hour: 21, minute: 30));

      container.dispose();

      // Next session
      container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(sharedStorage),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(smartReminderEnabledProvider), isFalse);
      expect(container.read(smartReminderTimeProvider), equals(const TimeOfDay(hour: 21, minute: 30)));
    });
  });
}

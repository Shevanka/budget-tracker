import 'dart:async';

import 'package:budget_tracker/features/notification_watcher/providers/notification_watcher_provider.dart';
import 'package:budget_tracker/features/notification_watcher/services/notification_listener_wrapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notification_listener_service/notification_event.dart';

class MockNotificationListenerWrapper extends Mock
    implements NotificationListenerWrapper {}

void main() {
  late MockNotificationListenerWrapper mockWrapper;
  late StreamController<ServiceNotificationEvent> streamController;

  setUp(() {
    mockWrapper = MockNotificationListenerWrapper();
    streamController = StreamController<ServiceNotificationEvent>.broadcast();
    when(() => mockWrapper.notificationsStream)
        .thenAnswer((_) => streamController.stream);
  });

  tearDown(() {
    streamController.close();
  });

  group('NotificationWatcherProvider Unit Tests', () {
    test('notificationAccessPermissionProvider builds with initial wrapper value', () async {
      when(() => mockWrapper.isPermissionGranted()).thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [
          notificationListenerWrapperProvider.overrideWithValue(mockWrapper),
        ],
      );
      addTearDown(container.dispose);

      final permission = await container.read(notificationAccessPermissionProvider.future);
      expect(permission, isTrue);
      verify(() => mockWrapper.isPermissionGranted()).called(1);
    });

    test('requestPermission delegates to wrapper and updates state', () async {
      when(() => mockWrapper.isPermissionGranted()).thenAnswer((_) async => false);
      when(() => mockWrapper.requestPermission()).thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [
          notificationListenerWrapperProvider.overrideWithValue(mockWrapper),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(notificationAccessPermissionProvider.future), isFalse);

      final granted = await container
          .read(notificationAccessPermissionProvider.notifier)
          .requestPermission();

      expect(granted, isTrue);
      expect(container.read(notificationAccessPermissionProvider).value, isTrue);
      verify(() => mockWrapper.requestPermission()).called(1);
    });

    test('refresh re-checks permission status from wrapper', () async {
      var callCount = 0;
      when(() => mockWrapper.isPermissionGranted()).thenAnswer((_) async {
        callCount++;
        return callCount > 1; // false on first call, true on subsequent call
      });

      final container = ProviderContainer(
        overrides: [
          notificationListenerWrapperProvider.overrideWithValue(mockWrapper),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(notificationAccessPermissionProvider.future), isFalse);

      await container.read(notificationAccessPermissionProvider.notifier).refresh();

      expect(container.read(notificationAccessPermissionProvider).value, isTrue);
      verify(() => mockWrapper.isPermissionGranted()).called(2);
    });

    test('rawIncomingNotificationsStreamProvider is empty when watcher is disabled', () async {
      when(() => mockWrapper.isPermissionGranted()).thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [
          notificationListenerWrapperProvider.overrideWithValue(mockWrapper),
          notificationWatcherEnabledProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      final events = <ServiceNotificationEvent>[];
      final subscription = container.listen<AsyncValue<ServiceNotificationEvent>>(
        rawIncomingNotificationsStreamProvider,
        (_, next) => next.whenData(events.add),
      );

      streamController.add(ServiceNotificationEvent(
        id: 1,
        title: 'BCA',
        canReply: false,
        haveExtraPicture: false,
        hasRemoved: false,
        packageName: 'com.bca',
        content: 'Pembelian Rp 50.000',
        onGoing: false,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        appIcon: null,
        extrasPicture: null,
        largeIcon: null,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events, isEmpty);
      subscription.close();
    });

    test('rawIncomingNotificationsStreamProvider forwards events when enabled and granted', () async {
      when(() => mockWrapper.isPermissionGranted()).thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [
          notificationListenerWrapperProvider.overrideWithValue(mockWrapper),
          notificationWatcherEnabledProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(container.dispose);

      // Await permission provider
      await container.read(notificationAccessPermissionProvider.future);

      final events = <ServiceNotificationEvent>[];
      final subscription = container.listen<AsyncValue<ServiceNotificationEvent>>(
        rawIncomingNotificationsStreamProvider,
        (_, next) => next.whenData(events.add),
      );

      final testEvent = ServiceNotificationEvent(
        id: 2,
        title: 'GoPay',
        canReply: false,
        haveExtraPicture: false,
        hasRemoved: false,
        packageName: 'com.gojek.app',
        content: 'Kamu berhasil bayar Rp 35.000',
        onGoing: false,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        appIcon: null,
        extrasPicture: null,
        largeIcon: null,
      );

      streamController.add(testEvent);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events.length, 1);
      expect(events.first.packageName, 'com.gojek.app');
      expect(events.first.content, 'Kamu berhasil bayar Rp 35.000');
      subscription.close();
    });
  });
}

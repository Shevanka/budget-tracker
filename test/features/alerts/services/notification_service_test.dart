import 'package:budget_tracker/features/alerts/constants/notification_channels.dart';
import 'package:budget_tracker/features/alerts/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockAndroidFlutterLocalNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late MockAndroidFlutterLocalNotificationsPlugin mockAndroidPlugin;
  late LocalNotificationService service;

  setUpAll(() {
    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    registerFallbackValue(NotificationChannels.budgetWarning);
    registerFallbackValue(
      const NotificationDetails(
        android: NotificationChannels.warningDetails,
      ),
    );
  });

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    mockAndroidPlugin = MockAndroidFlutterLocalNotificationsPlugin();
    service = LocalNotificationService(plugin: mockPlugin);
  });

  group('LocalNotificationService Tests', () {
    test('initialize registers settings and configures Android channels', () async {
      when(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
        ),
      ).thenAnswer((_) async => true);

      when(
        () => mockPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>(),
      ).thenReturn(mockAndroidPlugin);

      when(
        () => mockAndroidPlugin.createNotificationChannel(any()),
      ).thenAnswer((_) async {});

      final result = await service.initialize();

      expect(result, isTrue);
      expect(service.isInitialized, isTrue);

      verify(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
        ),
      ).called(1);

      // Verify all 3 channels are created on Android
      verify(
        () => mockAndroidPlugin.createNotificationChannel(NotificationChannels.budgetWarning),
      ).called(1);
      verify(
        () => mockAndroidPlugin.createNotificationChannel(NotificationChannels.budgetExceeded),
      ).called(1);
      verify(
        () => mockAndroidPlugin.createNotificationChannel(NotificationChannels.budgetReminder),
      ).called(1);
    });

    test('initialize returns false when plugin initialization throws', () async {
      when(
        () => mockPlugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(named: 'onDidReceiveNotificationResponse'),
        ),
      ).thenThrow(Exception('Native plugin error'));

      final result = await service.initialize();

      expect(result, isFalse);
      expect(service.isInitialized, isFalse);
    });

    test('requestPermission delegates to AndroidFlutterLocalNotificationsPlugin', () async {
      when(
        () => mockPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>(),
      ).thenReturn(mockAndroidPlugin);

      when(
        () => mockAndroidPlugin.requestNotificationsPermission(),
      ).thenAnswer((_) async => true);

      final granted = await service.requestPermission();
      expect(granted, isTrue);
      verify(() => mockAndroidPlugin.requestNotificationsPermission()).called(1);
    });

    test('requestPermission returns false when platform plugin returns null or false', () async {
      when(
        () => mockPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>(),
      ).thenReturn(mockAndroidPlugin);

      when(
        () => mockAndroidPlugin.requestNotificationsPermission(),
      ).thenAnswer((_) async => false);

      final granted = await service.requestPermission();
      expect(granted, isFalse);
    });

    test('requestPermission returns false when Android platform plugin is unavailable', () async {
      when(
        () => mockPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>(),
      ).thenReturn(null);

      final granted = await service.requestPermission();
      expect(granted, isFalse);
    });

    test('showBudgetWarning triggers notification on warning channel', () async {
      when(
        () => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      await service.showBudgetWarning(
        id: 101,
        title: 'Budget Alert',
        body: 'You have spent 85% of your food budget.',
        payload: 'budget_food',
      );

      verify(
        () => mockPlugin.show(
          id: 101,
          title: 'Budget Alert',
          body: 'You have spent 85% of your food budget.',
          notificationDetails: const NotificationDetails(
            android: NotificationChannels.warningDetails,
          ),
          payload: 'budget_food',
        ),
      ).called(1);
    });

    test('showBudgetExceeded triggers notification on exceeded channel', () async {
      when(
        () => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      await service.showBudgetExceeded(
        id: 102,
        title: 'Budget Exceeded',
        body: 'You have exceeded 100% of your monthly budget.',
        payload: 'budget_monthly',
      );

      verify(
        () => mockPlugin.show(
          id: 102,
          title: 'Budget Exceeded',
          body: 'You have exceeded 100% of your monthly budget.',
          notificationDetails: const NotificationDetails(
            android: NotificationChannels.exceededDetails,
          ),
          payload: 'budget_monthly',
        ),
      ).called(1);
    });

    test('showReminder triggers notification on reminder channel', () async {
      when(
        () => mockPlugin.show(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          notificationDetails: any(named: 'notificationDetails'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      await service.showReminder(
        id: 103,
        title: 'Daily Reminder',
        body: 'Did you make any purchases today?',
        payload: 'reminder_daily',
      );

      verify(
        () => mockPlugin.show(
          id: 103,
          title: 'Daily Reminder',
          body: 'Did you make any purchases today?',
          notificationDetails: const NotificationDetails(
            android: NotificationChannels.reminderDetails,
          ),
          payload: 'reminder_daily',
        ),
      ).called(1);
    });

    test('cancel delegates to plugin.cancel', () async {
      when(() => mockPlugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});

      await service.cancel(101);
      verify(() => mockPlugin.cancel(id: 101)).called(1);
    });

    test('cancelAll delegates to plugin.cancelAll', () async {
      when(() => mockPlugin.cancelAll()).thenAnswer((_) async {});

      await service.cancelAll();
      verify(() => mockPlugin.cancelAll()).called(1);
    });
  });
}

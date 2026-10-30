import 'package:budget_tracker/features/alerts/providers/alerts_provider.dart';
import 'package:budget_tracker/features/alerts/services/notification_service.dart';
import 'package:budget_tracker/features/notification_watcher/presentation/widgets/notification_access_dialog.dart';
import 'package:budget_tracker/features/notification_watcher/providers/notification_watcher_provider.dart';
import 'package:budget_tracker/features/notification_watcher/services/notification_listener_wrapper.dart';
import 'package:budget_tracker/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationService extends Mock implements NotificationService {}

class MockNotificationListenerWrapper extends Mock
    implements NotificationListenerWrapper {}

void main() {
  late MockNotificationService mockNotificationService;
  late MockNotificationListenerWrapper mockListenerWrapper;

  setUp(() {
    mockNotificationService = MockNotificationService();
    mockListenerWrapper = MockNotificationListenerWrapper();

    when(() => mockListenerWrapper.isPermissionGranted()).thenAnswer((_) async => false);
    when(() => mockListenerWrapper.requestPermission()).thenAnswer((_) async => true);
  });

  Widget buildTestWidget({
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(mockNotificationService),
        notificationListenerWrapperProvider.overrideWithValue(mockListenerWrapper),
        ...overrides,
      ],
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen Widget & Permission Tests', () {
    testWidgets('renders all settings options and notification switch in disabled state',
        (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Budget Setup'), findsOneWidget);
      expect(find.text('Smart Recording Review'), findsOneWidget);
      expect(find.text('Budget Alert Notifications'), findsOneWidget);
      expect(
        find.text('Disabled — tap to request notification permission'),
        findsOneWidget,
      );

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.first.value, isFalse);

      final testAlertTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Test Budget Alert'),
      );
      expect(testAlertTile.enabled, isFalse);
    });

    testWidgets('renders notification switch in enabled state when permission granted',
        (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Budget Alert Notifications'), findsOneWidget);
      expect(
        find.text('Enabled — 80% warning and 100% exceeded alerts active'),
        findsOneWidget,
      );

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.first.value, isTrue);

      final testAlertTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Test Budget Alert'),
      );
      expect(testAlertTile.enabled, isTrue);
    });

    testWidgets('toggling alert switch ON requests notification permission',
        (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => false);
      when(() => mockNotificationService.requestPermission())
          .thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      verify(() => mockNotificationService.requestPermission()).called(1);
    });

    testWidgets('tapping Test Budget Alert sends test warning notification when enabled',
        (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => true);
      when(
        () => mockNotificationService.showBudgetWarning(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Budget Alert'));
      await tester.pumpAndSettle();

      verify(
        () => mockNotificationService.showBudgetWarning(
          id: 999999,
          title: any(named: 'title'),
          body: any(named: 'body'),
        ),
      ).called(1);

      expect(find.text('Test notification sent!'), findsOneWidget);
    });

    testWidgets('renders Notification Watcher section with access status',
        (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => false);
      when(() => mockListenerWrapper.isPermissionGranted())
          .thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll to reveal Notification Watcher section
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Notification Watcher (Auto-Record)'), findsOneWidget);
      expect(find.text('Bank & E-Wallet Watcher'), findsOneWidget);
      expect(
        find.text('Access required — tap to grant Notification Access'),
        findsOneWidget,
      );
      expect(find.text('Notification Access Status'), findsOneWidget);
      expect(find.text('Grant'), findsOneWidget);
    });

    testWidgets('toggling Bank & E-Wallet Watcher when access not granted shows dialog',
        (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => false);
      when(() => mockListenerWrapper.isPermissionGranted())
          .thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll to reveal Notification Watcher section
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Find the second switch (Watcher switch)
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));

      await tester.tap(switches.last);
      await tester.pumpAndSettle();

      // Should open NotificationAccessDialog
      expect(find.byType(NotificationAccessDialog), findsOneWidget);
      expect(find.text('Akses Notifikasi'), findsOneWidget);
    });

    testWidgets('toggling Bank & E-Wallet Watcher when access granted toggles enabled state',
        (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => true);
      when(() => mockListenerWrapper.isPermissionGranted())
          .thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll to reveal Notification Watcher section
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(
        find.text('Granted — passive & battery-efficient listener'),
        findsOneWidget,
      );

      final switches = find.byType(Switch);
      await tester.tap(switches.last);
      await tester.pumpAndSettle();

      expect(
        find.text('Active — auto-capturing BCA, Mandiri, BNI, GoPay, etc.'),
        findsOneWidget,
      );
    });
  });
}

import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/database_provider.dart';
import 'package:budget_tracker/features/alerts/providers/alerts_provider.dart';
import 'package:budget_tracker/features/alerts/services/notification_service.dart';
import 'package:budget_tracker/features/notification_watcher/presentation/widgets/notification_access_dialog.dart';
import 'package:budget_tracker/features/notification_watcher/presentation/widgets/watched_apps_dialog.dart';
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
  late AppDatabase db;
  late MockNotificationService mockNotificationService;
  late MockNotificationListenerWrapper mockListenerWrapper;

  setUp(() {
    db = AppDatabase.inMemory(seedDefaults: true);
    mockNotificationService = MockNotificationService();
    mockListenerWrapper = MockNotificationListenerWrapper();

    when(() => mockListenerWrapper.isPermissionGranted()).thenAnswer((_) async => false);
    when(() => mockListenerWrapper.requestPermission()).thenAnswer((_) async => true);
    when(() => mockNotificationService.cancel(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget({
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
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

      final alertSwitch = find.descendant(
        of: find.widgetWithText(SwitchListTile, 'Budget Alert Notifications'),
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(alertSwitch).value, isFalse);

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

      final alertSwitch = find.descendant(
        of: find.widgetWithText(SwitchListTile, 'Budget Alert Notifications'),
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(alertSwitch).value, isTrue);

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

      final alertSwitch = find.descendant(
        of: find.widgetWithText(SwitchListTile, 'Budget Alert Notifications'),
        matching: find.byType(Switch),
      );
      await tester.tap(alertSwitch);
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
          title: 'Peringatan Anggaran: Simulasi',
          body:
              'Pengeluaran untuk Makanan telah mencapai 85% (Rp 850.000 dari Rp 1.000.000).',
        ),
      ).called(1);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Test notification sent!'), findsOneWidget);
    });

    testWidgets('renders daily spending reminder switch and toggles state', (tester) async {
      when(() => mockNotificationService.isPermissionGranted()).thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Daily Spending Reminder'),
        50,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Daily Spending Reminder'), findsOneWidget);
      expect(find.textContaining('"Did you spend today?"'), findsOneWidget);

      final reminderSwitch = find.descendant(
        of: find.widgetWithText(SwitchListTile, 'Daily Spending Reminder'),
        matching: find.byType(Switch),
      );
      expect(reminderSwitch, findsOneWidget);

      // Toggle OFF
      await tester.tap(reminderSwitch);
      await tester.pumpAndSettle();

      expect(find.textContaining('Disabled — toggle to receive reminders'), findsOneWidget);
    });

    testWidgets('tapping Test Spending Reminder evaluates and displays confirmation snackbar', (tester) async {
      when(() => mockNotificationService.isPermissionGranted()).thenAnswer((_) async => true);
      when(
        () => mockNotificationService.showReminder(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Test Spending Reminder'),
        50,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Test Spending Reminder'), findsOneWidget);
      await tester.tap(find.text('Test Spending Reminder'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('Reminder sent'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders Notification Watcher section with access status',
        (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => true);
      when(() => mockListenerWrapper.isPermissionGranted())
          .thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll to reveal Notification Watcher section
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Notification Watcher (Auto-Record)'), findsOneWidget);
      expect(find.text('Bank & E-Wallet Watcher'), findsOneWidget);
      expect(find.text('Notification Access Status'), findsOneWidget);
      expect(
        find.text('Access required — tap to grant Notification Access'),
        findsOneWidget,
      );
      expect(find.text('Grant'), findsOneWidget);
    });

    testWidgets('toggling Bank & E-Wallet Watcher when access not granted shows dialog',
        (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => true);
      when(() => mockListenerWrapper.isPermissionGranted())
          .thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll to reveal Notification Watcher section
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Find the watcher switch
      final watcherSwitch = find.descendant(
        of: find.widgetWithText(SwitchListTile, 'Bank & E-Wallet Watcher'),
        matching: find.byType(Switch),
      );
      expect(watcherSwitch, findsOneWidget);

      await tester.tap(watcherSwitch);
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

      final watcherSwitch = find.descendant(
        of: find.widgetWithText(SwitchListTile, 'Bank & E-Wallet Watcher'),
        matching: find.byType(Switch),
      );
      expect(watcherSwitch, findsOneWidget);

      await tester.tap(watcherSwitch);
      await tester.pumpAndSettle();

      expect(
        find.text('Active — auto-capturing BCA, Mandiri, BNI, GoPay, etc.'),
        findsOneWidget,
      );
    });

    testWidgets('renders Watched Applications tile and opens WatchedAppsDialog on tap',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll to bottom
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Watched Applications'), findsOneWidget);
      expect(
        find.text('All 9 banks & e-wallets active (BCA, Mandiri, GoPay, etc.)'),
        findsOneWidget,
      );
      expect(find.text('9'), findsOneWidget);

      // Tap Watched Applications
      await tester.tap(find.text('Watched Applications'));
      await tester.pumpAndSettle();

      expect(find.byType(WatchedAppsDialog), findsOneWidget);
    });

    testWidgets('renders Watched Applications tile with partial count when apps are disabled',
        (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            enabledWatchedAppIdsProvider.overrideWith(
              () => _TestCustomWatchedAppsNotifier({'bca', 'gopay'}),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('2 of 9 institutions active'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });
}

class _TestCustomWatchedAppsNotifier extends EnabledWatchedAppsNotifier {
  final Set<String> _initial;
  _TestCustomWatchedAppsNotifier(this._initial);

  @override
  Set<String> build() => _initial;
}

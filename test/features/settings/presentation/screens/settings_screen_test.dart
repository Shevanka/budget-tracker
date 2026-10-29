import 'package:budget_tracker/features/alerts/providers/alerts_provider.dart';
import 'package:budget_tracker/features/alerts/services/notification_service.dart';
import 'package:budget_tracker/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockNotificationService mockNotificationService;

  setUp(() {
    mockNotificationService = MockNotificationService();
  });

  Widget buildTestWidget({
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(mockNotificationService),
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

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);

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

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);

      final testAlertTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Test Budget Alert'),
      );
      expect(testAlertTile.enabled, isTrue);
    });

    testWidgets('toggling switch ON requests notification permission',
        (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => false);
      when(() => mockNotificationService.requestPermission())
          .thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
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
  });
}

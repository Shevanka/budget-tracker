import 'package:budget_tracker/features/alerts/presentation/widgets/notification_permission_banner.dart';
import 'package:budget_tracker/features/alerts/providers/alerts_provider.dart';
import 'package:budget_tracker/features/alerts/services/notification_service.dart';
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
        home: Scaffold(
          body: NotificationPermissionBanner(),
        ),
      ),
    );
  }

  group('NotificationPermissionBanner Widget Tests', () {
    testWidgets('renders banner with rationale when permission is not granted',
        (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Notifikasi Anggaran'), findsOneWidget);
      expect(
        find.text(
          'Dapatkan peringatan otomatis saat pengeluaran Anda mencapai 80% atau melebihi 100% dari batas anggaran.',
        ),
        findsOneWidget,
      );
      expect(find.text('Aktifkan'), findsOneWidget);
      expect(find.text('Nanti Saja'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
    });

    testWidgets('hides banner (SizedBox.shrink) when permission is already granted',
        (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Notifikasi Anggaran'), findsNothing);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('tapping Aktifkan calls requestPermission and refreshes banner',
        (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => false);
      when(() => mockNotificationService.requestPermission())
          .thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan'), findsOneWidget);

      await tester.tap(find.text('Aktifkan'));
      await tester.pumpAndSettle();

      verify(() => mockNotificationService.requestPermission()).called(1);
      // Once permission is granted, banner should disappear
      expect(find.text('Aktifkan Notifikasi Anggaran'), findsNothing);
    });

    testWidgets('tapping Nanti Saja dismisses banner for session', (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Nanti Saja'), findsOneWidget);

      await tester.tap(find.text('Nanti Saja'));
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Notifikasi Anggaran'), findsNothing);
    });

    testWidgets('tapping close icon dismisses banner for session', (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final closeButton = find.byTooltip('Tutup');
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.text('Aktifkan Notifikasi Anggaran'), findsNothing);
    });

    testWidgets('shows snackbar when permission request is denied', (tester) async {
      when(() => mockNotificationService.isPermissionGranted())
          .thenAnswer((_) async => false);
      when(() => mockNotificationService.requestPermission())
          .thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Aktifkan'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Izin notifikasi tidak diberikan. Anda dapat mengaktifkannya di Pengaturan.',
        ),
        findsOneWidget,
      );
    });
  });
}

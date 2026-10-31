import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/features/notification_watcher/models/draft_transaction.dart';
import 'package:budget_tracker/features/notification_watcher/models/parsed_notification.dart';
import 'package:budget_tracker/features/notification_watcher/presentation/widgets/detected_transaction_banner.dart';
import 'package:budget_tracker/features/notification_watcher/providers/draft_transaction_provider.dart';
import 'package:budget_tracker/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  DraftTransaction createDraft({
    String id = 'draft-1',
    String packageName = 'com.bca',
    String source = 'BCA',
    int amount = 45000,
    String merchant = 'INDOMARET',
  }) {
    return DraftTransaction(
      log: NotificationLog(
        id: id,
        appPackage: packageName,
        title: source,
        body: 'Pembelian di $merchant Rp $amount',
        receivedAt: DateTime.utc(2026, 10, 30, 14, 0),
        parsed: false,
        transactionId: null,
      ),
      parsed: ParsedNotification(
        amount: amount,
        merchant: merchant,
        source: source,
        rawText: 'Pembelian di $merchant Rp $amount',
        timestamp: DateTime.utc(2026, 10, 30, 14, 0),
      ),
    );
  }

  Widget buildTestWidget({
    required List<DraftTransaction> drafts,
    GoRouter? router,
  }) {
    final defaultRouter = router ??
        GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(
                body: DetectedTransactionBanner(),
              ),
            ),
            GoRoute(
              path: AppRoute.smartRecordingReview.path,
              builder: (context, state) => const Scaffold(
                body: Text('Review Screen Page'),
              ),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        pendingDraftTransactionsProvider.overrideWith((ref) => Stream.value(drafts)),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: defaultRouter,
      ),
    );
  }

  group('DetectedTransactionBanner Widget Tests', () {
    testWidgets('renders SizedBox.shrink when drafts list is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(drafts: []));
      await tester.pumpAndSettle();

      expect(find.text('Transaksi Baru Terdeteksi'), findsNothing);
      expect(find.byType(DetectedTransactionBanner), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('renders single detected transaction details and review button', (tester) async {
      final draft = createDraft();

      await tester.pumpWidget(buildTestWidget(drafts: [draft]));
      await tester.pumpAndSettle();

      expect(find.text('Transaksi Baru Terdeteksi'), findsOneWidget);
      expect(find.textContaining('Rp 45.000 di INDOMARET (BCA)'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('renders multiple detected transactions summary count', (tester) async {
      final draft1 = createDraft(id: 'd1', merchant: 'INDOMARET');
      final draft2 = createDraft(id: 'd2', merchant: 'ALFAMART');

      await tester.pumpWidget(buildTestWidget(drafts: [draft1, draft2]));
      await tester.pumpAndSettle();

      expect(find.text('2 Transaksi Baru Terdeteksi'), findsOneWidget);
      expect(find.textContaining('Ketuk untuk meninjau dan mengonfirmasi'), findsOneWidget);
    });

    testWidgets('tapping Review button navigates to Smart Recording Review Screen', (tester) async {
      final draft = createDraft();

      await tester.pumpWidget(buildTestWidget(drafts: [draft]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();

      expect(find.text('Review Screen Page'), findsOneWidget);
    });
  });
}

import 'package:budget_tracker/core/constants/default_categories.dart';
import 'package:budget_tracker/core/theme/app_theme.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/categories/providers/categories_provider.dart';
import 'package:budget_tracker/features/notification_watcher/models/draft_transaction.dart';
import 'package:budget_tracker/features/notification_watcher/models/parsed_notification.dart';
import 'package:budget_tracker/features/notification_watcher/providers/draft_transaction_provider.dart';
import 'package:budget_tracker/features/smart_recording/presentation/screens/smart_recording_review_screen.dart';
import 'package:budget_tracker/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockDraftTransactionController extends AutoDisposeAsyncNotifier<void>
    with Mock
    implements DraftTransactionController {}

class FakeDraftTransaction extends Fake implements DraftTransaction {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDraftTransaction());
  });

  final testCategories = [
    Category(
      id: DefaultCategories.foodId,
      name: DefaultCategories.foodName,
      icon: 'restaurant',
      color: 0xFF43A047,
      type: TransactionType.expense,
      isDefault: true,
      isActive: true,
      sortOrder: 0,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
    Category(
      id: DefaultCategories.shoppingId,
      name: DefaultCategories.shoppingName,
      icon: 'shopping_bag',
      color: 0xFFFB8C00,
      type: TransactionType.expense,
      isDefault: true,
      isActive: true,
      sortOrder: 1,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  ];

  DraftTransaction createDraft({
    String id = 'draft-1',
    String packageName = 'com.bca',
    String source = 'BCA',
    int amount = 45000,
    String merchant = 'INDOMARET',
    String? categoryId = DefaultCategories.shoppingId,
    String? categoryName = DefaultCategories.shoppingName,
  }) {
    return DraftTransaction(
      log: NotificationLog(
        id: id,
        appPackage: packageName,
        title: source,
        body: 'Pembelian di $merchant Rp 45.000,00 di rek *1234',
        receivedAt: DateTime.utc(2026, 10, 30, 14, 0),
        parsed: false,
        transactionId: null,
      ),
      parsed: ParsedNotification(
        amount: amount,
        merchant: merchant,
        source: source,
        suggestedCategoryId: categoryId,
        suggestedCategoryName: categoryName,
        rawText: 'Pembelian di $merchant Rp 45.000,00 di rek *1234',
        timestamp: DateTime.utc(2026, 10, 30, 14, 0),
      ),
    );
  }

  Widget buildTestWidget({
    required List<DraftTransaction> drafts,
    DraftTransactionController? controller,
    GoRouter? router,
  }) {
    final defaultRouter = router ??
        GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const SmartRecordingReviewScreen(),
            ),
            GoRoute(
              path: AppRoute.addTransaction.path,
              builder: (context, state) => Scaffold(
                body: Text('AddEdit Screen: ${state.extra}'),
              ),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        pendingDraftTransactionsProvider.overrideWith((ref) => Stream.value(drafts)),
        activeCategoriesProvider.overrideWith((ref) => Stream.value(testCategories)),
        activeCategoriesByTypeProvider(TransactionType.expense)
            .overrideWith((ref) => Stream.value(testCategories)),
        if (controller != null)
          draftTransactionControllerProvider.overrideWith(() => controller),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: defaultRouter,
      ),
    );
  }

  group('SmartRecordingReviewScreen Widget Tests', () {
    testWidgets('renders empty state when there are no draft transactions', (tester) async {
      await tester.pumpWidget(buildTestWidget(drafts: []));
      await tester.pumpAndSettle();

      expect(find.text('All Caught Up!'), findsOneWidget);
      expect(find.textContaining('No pending draft transactions'), findsOneWidget);
      expect(find.byIcon(Icons.task_alt_rounded), findsOneWidget);
    });

    testWidgets('renders draft transaction card details', (tester) async {
      final draft = createDraft();

      await tester.pumpWidget(buildTestWidget(drafts: [draft]));
      await tester.pumpAndSettle();

      expect(find.text('BCA'), findsOneWidget);
      expect(find.text('Rp 45.000'), findsOneWidget);
      expect(find.text('INDOMARET'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);
      expect(find.textContaining('Auto-suggested from "Shopping"'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('tapping Confirm calls controller and displays feedback snackbar', (tester) async {
      final draft = createDraft();
      final mockController = MockDraftTransactionController();

      when(() => mockController.confirmDraft(
            draft: any(named: 'draft'),
            categoryId: any(named: 'categoryId'),
          )).thenAnswer((_) async => true);

      await tester.pumpWidget(
        buildTestWidget(
          drafts: [draft],
          controller: mockController,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pump();

      verify(() => mockController.confirmDraft(
            draft: any(named: 'draft'),
            categoryId: any(named: 'categoryId'),
          )).called(1);

      await tester.pumpAndSettle();
      expect(find.textContaining('Saved: Rp 45.000 at INDOMARET'), findsOneWidget);
    });

    testWidgets('tapping Skip calls dismissDraft on controller', (tester) async {
      final draft = createDraft();
      final mockController = MockDraftTransactionController();

      when(() => mockController.dismissDraft(draft.id)).thenAnswer((_) async => true);

      await tester.pumpWidget(
        buildTestWidget(
          drafts: [draft],
          controller: mockController,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pump();

      verify(() => mockController.dismissDraft(draft.id)).called(1);

      await tester.pumpAndSettle();
      expect(find.text('Notification dismissed'), findsOneWidget);
    });

    testWidgets('shows Confirm All button in AppBar when multiple drafts exist', (tester) async {
      final draft1 = createDraft(id: 'd1', merchant: 'INDOMARET');
      final draft2 = createDraft(id: 'd2', merchant: 'ALFAMART');
      final mockController = MockDraftTransactionController();

      when(() => mockController.confirmAll(any())).thenAnswer((_) async => 2);

      await tester.pumpWidget(
        buildTestWidget(
          drafts: [draft1, draft2],
          controller: mockController,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirm All'), findsOneWidget);

      await tester.tap(find.text('Confirm All'));
      await tester.pumpAndSettle();

      verify(() => mockController.confirmAll(any())).called(1);
      expect(find.text('2 transactions confirmed'), findsOneWidget);
    });

    testWidgets('tapping Edit navigates to AddEditTransactionScreen with pre-filled extra', (tester) async {
      final draft = createDraft();

      await tester.pumpWidget(buildTestWidget(drafts: [draft]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.textContaining('AddEdit Screen:'), findsOneWidget);
      expect(find.textContaining('INDOMARET'), findsOneWidget);
      expect(find.textContaining('45000'), findsOneWidget);
    });
  });
}

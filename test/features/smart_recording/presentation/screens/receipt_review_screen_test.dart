import 'package:budget_tracker/core/constants/default_categories.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/database_provider.dart';
import 'package:budget_tracker/features/categories/providers/categories_provider.dart';
import 'package:budget_tracker/features/smart_recording/models/parsed_receipt.dart';
import 'package:budget_tracker/features/smart_recording/presentation/screens/receipt_review_screen.dart';
import 'package:budget_tracker/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late AppDatabase db;

  final foodCategory = Category(
    id: DefaultCategories.foodId,
    name: 'Food',
    icon: 'restaurant',
    color: 0xFF43A047,
    type: TransactionType.expense,
    isDefault: true,
    isActive: true,
    sortOrder: 0,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  final shoppingCategory = Category(
    id: DefaultCategories.shoppingId,
    name: 'Shopping',
    icon: 'shopping_bag',
    color: 0xFFFB8C00,
    type: TransactionType.expense,
    isDefault: true,
    isActive: true,
    sortOrder: 1,
    createdAt: DateTime.utc(2026, 10, 1),
  );

  final sampleReceipt = ParsedReceipt(
    amount: 45000,
    merchant: 'INDOMARET',
    date: DateTime.utc(2026, 10, 30, 14, 30),
    suggestedCategoryId: DefaultCategories.shoppingId,
    suggestedCategoryName: DefaultCategories.shoppingName,
    rawText: 'INDOMARET\nTOTAL BELANJA: Rp 45.000\n30/10/2026',
    imagePath: '/mock/receipt.jpg',
    lines: const [
      'INDOMARET',
      'TOTAL BELANJA: Rp 45.000',
      '30/10/2026',
    ],
  );

  setUp(() async {
    db = AppDatabase.inMemory(seedDefaults: true);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget({ParsedReceipt? receipt}) {
    final router = GoRouter(
      initialLocation: AppRoute.receiptReview.path,
      routes: [
        GoRoute(
          path: AppRoute.receiptReview.path,
          builder: (context, state) => ReceiptReviewScreen(
            initialReceipt: receipt,
          ),
        ),
        GoRoute(
          path: AppRoute.receiptPicker.path,
          builder: (context, state) => const Scaffold(
            body: Text('Receipt Picker Screen Target'),
          ),
        ),
        GoRoute(
          path: AppRoute.addTransaction.path,
          builder: (context, state) => const Scaffold(
            body: Text('Add Transaction Screen Target'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        activeCategoriesProvider.overrideWith(
          (ref) => Stream.value([foodCategory, shoppingCategory]),
        ),
        activeCategoriesByTypeProvider.overrideWith(
          (ref, type) => Stream.value(
            [foodCategory, shoppingCategory]
                .where((c) => c.type == type)
                .toList(),
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('ReceiptReviewScreen Widget Tests', () {
    testWidgets('renders empty state when no parsed receipt is provided', (tester) async {
      await tester.pumpWidget(buildTestWidget(receipt: null));
      await tester.pumpAndSettle();

      expect(find.text('Tinjau Data Struk'), findsOneWidget);
      expect(find.text('Tidak ada data struk yang dipilih'), findsOneWidget);
      expect(find.text('Pindai Struk Sekarang'), findsOneWidget);

      await tester.tap(find.text('Pindai Struk Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Receipt Picker Screen Target'), findsOneWidget);
    });

    testWidgets('pre-populates amount, merchant, category, and date from parsed receipt',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(receipt: sampleReceipt));
      await tester.pumpAndSettle();

      expect(find.text('Tinjau Data Struk'), findsOneWidget);
      expect(find.text('Teks Berhasil Dikenali'), findsOneWidget);
      expect(find.textContaining('3 baris teks terdeteksi'), findsOneWidget);

      // Amount field contains 45.000
      final amountField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Total Belanja'),
      );
      expect(amountField.controller?.text, '45.000');

      // Merchant field contains INDOMARET
      final merchantField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Nama Toko / Merchant'),
      );
      expect(merchantField.controller?.text, 'INDOMARET');

      // Category is Shopping
      expect(find.text('Shopping'), findsOneWidget);
      expect(
        find.text('Saran otomatis untuk Shopping'),
        findsOneWidget,
      );

      // Default payment method is Cash
      final sourceField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Metode Pembayaran'),
      );
      expect(sourceField.controller?.text, 'Cash');

      // Action buttons
      expect(find.text('Konfirmasi & Simpan Transaksi'), findsOneWidget);
      expect(find.text('Gunakan Data di Form Tambah'), findsOneWidget);
    });

    testWidgets('allows editing merchant, amount, and payment method chips',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(receipt: sampleReceipt));
      await tester.pumpAndSettle();

      // Change amount to 60.000
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Total Belanja'),
        '60000',
      );

      // Change merchant
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama Toko / Merchant'),
        'Alfamidi Dago',
      );

      // Select BCA chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'BCA'));
      await tester.pumpAndSettle();

      final sourceField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Metode Pembayaran'),
      );
      expect(sourceField.controller?.text, 'BCA');
    });

    testWidgets('confirms and saves transaction directly to database', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(receipt: sampleReceipt));
      await tester.pumpAndSettle();

      // Tap Confirm & Save
      await tester.tap(find.text('Konfirmasi & Simpan Transaksi'));
      await tester.pumpAndSettle();

      // Verify transaction in DB
      final transactions = await db.transactionDao.getTransactionsWithCategory();
      expect(transactions.length, 1);
      final savedTx = transactions.first.transaction;
      expect(savedTx.amount, 45000);
      expect(savedTx.type, TransactionType.expense);
      expect(savedTx.categoryId, DefaultCategories.shoppingId);
      expect(savedTx.source, 'Cash');
      expect(savedTx.note, 'INDOMARET');

      // SnackBar displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Transaksi disimpan:'), findsOneWidget);
    });

    testWidgets('opens full transaction editor when action icon is tapped', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(receipt: sampleReceipt));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.open_in_new_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction Screen Target'), findsOneWidget);
    });
  });
}

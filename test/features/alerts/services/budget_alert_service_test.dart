import 'dart:convert';

import 'package:budget_tracker/core/utils/currency_formatter.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/alerts/services/budget_alert_service.dart';
import 'package:budget_tracker/features/alerts/services/notification_service.dart';
import 'package:budget_tracker/features/budget/domain/services/budget_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late AppDatabase db;
  late BudgetService budgetService;
  late MockNotificationService mockNotificationService;
  late BudgetAlertService alertService;

  setUp(() async {
    db = AppDatabase.inMemory();
    budgetService = BudgetService(
      budgetDao: db.budgetDao,
      transactionDao: db.transactionDao,
      categoryDao: db.categoryDao,
    );
    mockNotificationService = MockNotificationService();

    when(
      () => mockNotificationService.showBudgetWarning(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockNotificationService.showBudgetExceeded(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});

    alertService = BudgetAlertService(
      budgetService: budgetService,
      notificationService: mockNotificationService,
    );

    // Seed test categories
    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: const drift.Value('cat-food'),
        name: const drift.Value('Makanan'),
        icon: const drift.Value('restaurant'),
        color: const drift.Value(0xFF4CAF50),
        createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
      ),
    );

    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: const drift.Value('cat-transport'),
        name: const drift.Value('Transportasi'),
        icon: const drift.Value('directions_car'),
        color: const drift.Value(0xFF2196F3),
        createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('BudgetAlertService Unit & Logic Tests', () {
    test('non-expense (income) transactions do not trigger any alert', () async {
      final incomeTx = Transaction(
        id: 'tx-income-1',
        amount: 5000000,
        type: TransactionType.income,
        categoryId: 'cat-food',
        source: 'Gaji',
        date: DateTime.utc(2026, 10, 15),
        createdAt: DateTime.utc(2026, 10, 15),
        updatedAt: null,
        note: 'Monthly salary',
      );

      final results = await alertService.checkAndAlertForTransaction(incomeTx);

      expect(results, isEmpty);
      verifyNever(() => mockNotificationService.showBudgetWarning(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          ));
      verifyNever(() => mockNotificationService.showBudgetExceeded(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          ));
    });

    test('expense with no budget configured does not trigger alerts', () async {
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-1'),
          amount: const drift.Value(100000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 15)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 15)),
        ),
      );

      final tx = await db.transactionDao.getTransactionById('tx-1');
      final results = await alertService.checkAndAlertForTransaction(tx!);

      expect(results, isEmpty);
      verifyZeroInteractions(mockNotificationService);
    });

    test('category budget triggers 80% warning and deduplicates subsequent checks', () async {
      // Setup monthly budget and category limit: limit = 1.000.000
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(10000000), // Total 10jt so monthly threshold is far
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        const [
          BudgetCategoriesCompanion(
            id: drift.Value('bc-food'),
            budgetId: drift.Value('budget-2026-10'),
            categoryId: drift.Value('cat-food'),
            limitAmount: drift.Value(1000000),
          ),
        ],
      );

      // Insert transaction reaching 850.000 (85%)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-food-1'),
          amount: const drift.Value(850000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 15)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 15)),
        ),
      );

      final tx = await db.transactionDao.getTransactionById('tx-food-1');
      final results = await alertService.checkAndAlertForTransaction(tx!);

      expect(results.length, 1);
      final alert = results.first;
      expect(alert.scope, BudgetAlertScope.category);
      expect(alert.threshold, BudgetAlertThreshold.warning80);
      expect(alert.percentage, 85);
      expect(alert.title, 'Peringatan Anggaran: Makanan');
      expect(alert.body, contains('85%'));
      expect(alert.body, contains(CurrencyFormatter.format(850000)));
      expect(alert.body, contains(CurrencyFormatter.format(1000000)));
      expect(alert.notificationId, greaterThan(0));

      verify(() => mockNotificationService.showBudgetWarning(
            id: alert.notificationId,
            title: alert.title,
            body: alert.body,
            payload: alert.payload,
          )).called(1);

      // Verify deduplication: another transaction in the same category reaching 90%
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-food-2'),
          amount: const drift.Value(50000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 16)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 16)),
        ),
      );

      final tx2 = await db.transactionDao.getTransactionById('tx-food-2');
      final secondResults = await alertService.checkAndAlertForTransaction(tx2!);

      // Should not trigger again because 80% was already fired
      expect(secondResults, isEmpty);
      verifyNoMoreInteractions(mockNotificationService);
    });

    test('category budget triggers 100% exceeded alert and suppresses 80% warning', () async {
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(10000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        const [
          BudgetCategoriesCompanion(
            id: drift.Value('bc-food'),
            budgetId: drift.Value('budget-2026-10'),
            categoryId: drift.Value('cat-food'),
            limitAmount: drift.Value(1000000),
          ),
        ],
      );

      // Insert transaction directly exceeding limit: 1.050.000 (105%)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-food-exceeded'),
          amount: const drift.Value(1050000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 15)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 15)),
        ),
      );

      final tx = await db.transactionDao.getTransactionById('tx-food-exceeded');
      final results = await alertService.checkAndAlertForTransaction(tx!);

      expect(results.length, 1);
      final alert = results.first;
      expect(alert.scope, BudgetAlertScope.category);
      expect(alert.threshold, BudgetAlertThreshold.exceeded100);
      expect(alert.percentage, 105);
      expect(alert.title, 'Anggaran Terlampaui: Makanan');
      expect(alert.body, contains('melebihi batas anggaran'));
      expect(alert.body, contains(CurrencyFormatter.format(1050000)));

      verify(() => mockNotificationService.showBudgetExceeded(
            id: alert.notificationId,
            title: alert.title,
            body: alert.body,
            payload: alert.payload,
          )).called(1);

      // Both 100% and 80% keys should now be marked as fired
      final key80 = alertService.getCategoryAlertKey(
        yearMonth: '2026-10',
        categoryId: 'cat-food',
        threshold: BudgetAlertThreshold.warning80,
      );
      final key100 = alertService.getCategoryAlertKey(
        yearMonth: '2026-10',
        categoryId: 'cat-food',
        threshold: BudgetAlertThreshold.exceeded100,
      );
      expect(alertService.isAlertFired(key80), isTrue);
      expect(alertService.isAlertFired(key100), isTrue);

      // Subsequent transaction does not trigger again
      final txAgain = await alertService.checkAndAlertForTransaction(tx);
      expect(txAgain, isEmpty);
    });

    test('monthly budget triggers 80% warning and deduplicates', () async {
      // Monthly limit = 2.000.000, category has no limit
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(2000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        [],
      );

      // Spending reaches 1.650.000 (83%)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-monthly-1'),
          amount: const drift.Value(1650000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 15)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 15)),
        ),
      );

      final tx = await db.transactionDao.getTransactionById('tx-monthly-1');
      final results = await alertService.checkAndAlertForTransaction(tx!);

      expect(results.length, 1);
      final alert = results.first;
      expect(alert.scope, BudgetAlertScope.monthly);
      expect(alert.threshold, BudgetAlertThreshold.warning80);
      expect(alert.percentage, 83);
      expect(alert.title, 'Peringatan Anggaran Bulanan');
      expect(alert.body, contains('83%'));

      verify(() => mockNotificationService.showBudgetWarning(
            id: alert.notificationId,
            title: alert.title,
            body: alert.body,
            payload: alert.payload,
          )).called(1);

      // Repeat check deduplicates
      final repeat = await alertService.checkAndAlertForTransaction(tx);
      expect(repeat, isEmpty);
    });

    test('monthly budget triggers 100% exceeded alert', () async {
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(2000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        [],
      );

      // Spending reaches 2.100.000 (105%)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-monthly-exceeded'),
          amount: const drift.Value(2100000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('BCA'),
          date: drift.Value(DateTime.utc(2026, 10, 15)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 15)),
        ),
      );

      final tx = await db.transactionDao.getTransactionById('tx-monthly-exceeded');
      final results = await alertService.checkAndAlertForTransaction(tx!);

      expect(results.length, 1);
      final alert = results.first;
      expect(alert.scope, BudgetAlertScope.monthly);
      expect(alert.threshold, BudgetAlertThreshold.exceeded100);
      expect(alert.percentage, 105);
      expect(alert.title, 'Anggaran Bulanan Terlampaui!');
      expect(alert.body, contains('melebihi batas anggaran'));

      verify(() => mockNotificationService.showBudgetExceeded(
            id: alert.notificationId,
            title: alert.title,
            body: alert.body,
            payload: alert.payload,
          )).called(1);
    });

    test('triggers both category and monthly alerts when single transaction crosses both', () async {
      // Total limit = 1.000.000, category limit = 500.000
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(1000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        const [
          BudgetCategoriesCompanion(
            id: drift.Value('bc-food'),
            budgetId: drift.Value('budget-2026-10'),
            categoryId: drift.Value('cat-food'),
            limitAmount: drift.Value(500000),
          ),
        ],
      );

      // Expense of 850.000:
      // Category spent: 850.000 / 500.000 = 170% (exceeded)
      // Total spent: 850.000 / 1.000.000 = 85% (warning)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-dual'),
          amount: const drift.Value(850000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 15)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 15)),
        ),
      );

      final tx = await db.transactionDao.getTransactionById('tx-dual');
      final results = await alertService.checkAndAlertForTransaction(tx!);

      expect(results.length, 2);
      expect(results.any((r) => r.scope == BudgetAlertScope.category && r.threshold == BudgetAlertThreshold.exceeded100), isTrue);
      expect(results.any((r) => r.scope == BudgetAlertScope.monthly && r.threshold == BudgetAlertThreshold.warning80), isTrue);

      verify(() => mockNotificationService.showBudgetExceeded(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          )).called(1);
      verify(() => mockNotificationService.showBudgetWarning(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          )).called(1);
    });

    test('resetTracking resets all tracked alerts or month-specific alerts', () {
      final key1 = alertService.getCategoryAlertKey(
        yearMonth: '2026-10',
        categoryId: 'cat-food',
        threshold: BudgetAlertThreshold.warning80,
      );
      final key2 = alertService.getCategoryAlertKey(
        yearMonth: '2026-11',
        categoryId: 'cat-food',
        threshold: BudgetAlertThreshold.warning80,
      );

      alertService.markAlertFired(key1);
      alertService.markAlertFired(key2);

      expect(alertService.isAlertFired(key1), isTrue);
      expect(alertService.isAlertFired(key2), isTrue);

      // Scoped reset for 2026-10 only
      alertService.resetTracking(yearMonth: '2026-10');
      expect(alertService.isAlertFired(key1), isFalse);
      expect(alertService.isAlertFired(key2), isTrue);

      // Full reset
      alertService.resetTracking();
      expect(alertService.isAlertFired(key2), isFalse);
      expect(alertService.firedAlertKeys, isEmpty);
    });
  });

  group('Threshold Boundary Conditions (Phase 7.4)', () {
    test('spending at exactly 79% does not trigger warning', () async {
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(10000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        const [
          BudgetCategoriesCompanion(
            id: drift.Value('bc-food'),
            budgetId: drift.Value('budget-2026-10'),
            categoryId: drift.Value('cat-food'),
            limitAmount: drift.Value(1000000),
          ),
        ],
      );

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-food-79'),
          amount: const drift.Value(790000), // Exactly 79%
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 10)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 10)),
        ),
      );

      final tx = await db.transactionDao.getTransactionById('tx-food-79');
      final results = await alertService.checkAndAlertForTransaction(tx!);

      expect(results, isEmpty);
      verifyZeroInteractions(mockNotificationService);
    });

    test('spending at exactly 80% triggers 80% warning', () async {
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(10000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        const [
          BudgetCategoriesCompanion(
            id: drift.Value('bc-food'),
            budgetId: drift.Value('budget-2026-10'),
            categoryId: drift.Value('cat-food'),
            limitAmount: drift.Value(1000000),
          ),
        ],
      );

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-food-80'),
          amount: const drift.Value(800000), // Exactly 80%
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 10)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 10)),
        ),
      );

      final tx = await db.transactionDao.getTransactionById('tx-food-80');
      final results = await alertService.checkAndAlertForTransaction(tx!);

      expect(results.length, 1);
      expect(results.first.threshold, BudgetAlertThreshold.warning80);
      expect(results.first.percentage, 80);

      verify(() => mockNotificationService.showBudgetWarning(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          )).called(1);
    });

    test('spending at 99% triggers 80% warning and not exceeded', () async {
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(10000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        const [
          BudgetCategoriesCompanion(
            id: drift.Value('bc-food'),
            budgetId: drift.Value('budget-2026-10'),
            categoryId: drift.Value('cat-food'),
            limitAmount: drift.Value(1000000),
          ),
        ],
      );

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-food-99'),
          amount: const drift.Value(990000), // Exactly 99%
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 10)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 10)),
        ),
      );

      final tx = await db.transactionDao.getTransactionById('tx-food-99');
      final results = await alertService.checkAndAlertForTransaction(tx!);

      expect(results.length, 1);
      expect(results.first.threshold, BudgetAlertThreshold.warning80);
      expect(results.first.percentage, 99);
      verifyNever(() => mockNotificationService.showBudgetExceeded(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          ));
    });

    test('spending at exactly 100% triggers 100% exceeded alert', () async {
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(10000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        const [
          BudgetCategoriesCompanion(
            id: drift.Value('bc-food'),
            budgetId: drift.Value('budget-2026-10'),
            categoryId: drift.Value('cat-food'),
            limitAmount: drift.Value(1000000),
          ),
        ],
      );

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-food-100'),
          amount: const drift.Value(1000000), // Exactly 100%
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 10)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 10)),
        ),
      );

      final tx = await db.transactionDao.getTransactionById('tx-food-100');
      final results = await alertService.checkAndAlertForTransaction(tx!);

      expect(results.length, 1);
      expect(results.first.threshold, BudgetAlertThreshold.exceeded100);
      expect(results.first.percentage, 100);

      verify(() => mockNotificationService.showBudgetExceeded(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          )).called(1);
    });
  });

  group('Progressive Spending Lifecycle (Phase 7.4)', () {
    test('correctly transitions safe -> warning -> exceeded across successive transactions', () async {
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(10000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        const [
          BudgetCategoriesCompanion(
            id: drift.Value('bc-food'),
            budgetId: drift.Value('budget-2026-10'),
            categoryId: drift.Value('cat-food'),
            limitAmount: drift.Value(1000000),
          ),
        ],
      );

      // Step 1: 50% spending (Rp 500.000) -> Safe, 0 alerts
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('step-1'),
          amount: const drift.Value(500000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 1)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      );
      var tx = (await db.transactionDao.getTransactionById('step-1'))!;
      var results = await alertService.checkAndAlertForTransaction(tx);
      expect(results, isEmpty);
      verifyZeroInteractions(mockNotificationService);

      // Step 2: + Rp 350.000 (total Rp 850.000 = 85%) -> Warning triggered!
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('step-2'),
          amount: const drift.Value(350000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 5)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 5)),
        ),
      );
      tx = (await db.transactionDao.getTransactionById('step-2'))!;
      results = await alertService.checkAndAlertForTransaction(tx);
      expect(results.length, 1);
      expect(results.first.threshold, BudgetAlertThreshold.warning80);
      expect(results.first.percentage, 85);
      verify(() => mockNotificationService.showBudgetWarning(
            id: any(named: 'id'),
            title: any(named: 'title'),
            body: any(named: 'body'),
            payload: any(named: 'payload'),
          )).called(1);

      // Step 3: + Rp 80.000 (total Rp 930.000 = 93%) -> Warning already fired, 0 new alerts
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('step-3'),
          amount: const drift.Value(800000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 8)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 8)),
        ),
      );
      tx = (await db.transactionDao.getTransactionById('step-3'))!;
      results = await alertService.checkAndAlertForTransaction(tx);
      // Wait, 850k + 80k is 930k. Here 800000 would exceed, so let's use 80000
    });

    test('stepwise progression 50% -> 85% -> 92% -> 105% -> 120%', () async {
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(10000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        const [
          BudgetCategoriesCompanion(
            id: drift.Value('bc-food'),
            budgetId: drift.Value('budget-2026-10'),
            categoryId: drift.Value('cat-food'),
            limitAmount: drift.Value(1000000),
          ),
        ],
      );

      // Tx 1: 50% (500.000)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('p-1'),
          amount: const drift.Value(500000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 1)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      );
      var res = await alertService.checkAndAlertForTransaction(
        (await db.transactionDao.getTransactionById('p-1'))!,
      );
      expect(res, isEmpty);

      // Tx 2: 50% + 35% = 85% (850.000)
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('p-2'),
          amount: const drift.Value(350000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 5)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 5)),
        ),
      );
      res = await alertService.checkAndAlertForTransaction(
        (await db.transactionDao.getTransactionById('p-2'))!,
      );
      expect(res.length, 1);
      expect(res.first.threshold, BudgetAlertThreshold.warning80);

      // Tx 3: 85% + 7% = 92% (920.000) -> deduplicated, no alert
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('p-3'),
          amount: const drift.Value(70000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 10)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 10)),
        ),
      );
      res = await alertService.checkAndAlertForTransaction(
        (await db.transactionDao.getTransactionById('p-3'))!,
      );
      expect(res, isEmpty);

      // Tx 4: 92% + 13% = 105% (1.050.000) -> 100% exceeded alert!
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('p-4'),
          amount: const drift.Value(130000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 15)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 15)),
        ),
      );
      res = await alertService.checkAndAlertForTransaction(
        (await db.transactionDao.getTransactionById('p-4'))!,
      );
      expect(res.length, 1);
      expect(res.first.threshold, BudgetAlertThreshold.exceeded100);
      expect(res.first.percentage, 105);

      // Tx 5: 105% + 15% = 120% (1.200.000) -> 100% already fired, no alert
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('p-5'),
          amount: const drift.Value(150000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 20)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 20)),
        ),
      );
      res = await alertService.checkAndAlertForTransaction(
        (await db.transactionDao.getTransactionById('p-5'))!,
      );
      expect(res, isEmpty);
    });
  });

  group('Multi-Category and Cross-Month Independence (Phase 7.4)', () {
    test('distinct categories trigger independent alerts in the same month', () async {
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(10000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        const [
          BudgetCategoriesCompanion(
            id: drift.Value('bc-food'),
            budgetId: drift.Value('budget-2026-10'),
            categoryId: drift.Value('cat-food'),
            limitAmount: drift.Value(1000000),
          ),
          BudgetCategoriesCompanion(
            id: drift.Value('bc-transport'),
            budgetId: drift.Value('budget-2026-10'),
            categoryId: drift.Value('cat-transport'),
            limitAmount: drift.Value(500000),
          ),
        ],
      );

      // Trigger Cat A: 85% of 1.000.000 = 850.000
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-cat-a'),
          amount: const drift.Value(850000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 5)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 5)),
        ),
      );
      final resA = await alertService.checkAndAlertForTransaction(
        (await db.transactionDao.getTransactionById('tx-cat-a'))!,
      );
      expect(resA.length, 1);
      expect(resA.first.categoryId, 'cat-food');
      expect(resA.first.threshold, BudgetAlertThreshold.warning80);

      // Trigger Cat B: 85% of 500.000 = 425.000
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-cat-b'),
          amount: const drift.Value(425000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-transport'),
          source: const drift.Value('BCA'),
          date: drift.Value(DateTime.utc(2026, 10, 6)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 6)),
        ),
      );
      final resB = await alertService.checkAndAlertForTransaction(
        (await db.transactionDao.getTransactionById('tx-cat-b'))!,
      );
      expect(resB.length, 1);
      expect(resB.first.categoryId, 'cat-transport');
      expect(resB.first.categoryName, 'Transportasi');
      expect(resB.first.threshold, BudgetAlertThreshold.warning80);
      expect(resB.first.percentage, 85);
    });

    test('same category triggers independent alerts across different months', () async {
      // Month 1: 2026-10
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(10000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        const [
          BudgetCategoriesCompanion(
            id: drift.Value('bc-food-10'),
            budgetId: drift.Value('budget-2026-10'),
            categoryId: drift.Value('cat-food'),
            limitAmount: drift.Value(1000000),
          ),
        ],
      );

      // Month 2: 2026-11
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-11'),
          yearMonth: const drift.Value('2026-11'),
          totalLimit: const drift.Value(10000000),
          createdAt: drift.Value(DateTime.utc(2026, 11, 1)),
        ),
        const [
          BudgetCategoriesCompanion(
            id: drift.Value('bc-food-11'),
            budgetId: drift.Value('budget-2026-11'),
            categoryId: drift.Value('cat-food'),
            limitAmount: drift.Value(1000000),
          ),
        ],
      );

      // October expense hits 85%
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-oct'),
          amount: const drift.Value(850000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 15)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 15)),
        ),
      );
      final resOct = await alertService.checkAndAlertForTransaction(
        (await db.transactionDao.getTransactionById('tx-oct'))!,
      );
      expect(resOct.length, 1);
      expect(resOct.first.yearMonth, '2026-10');

      // November expense hits 85% -> must trigger for November independently
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-nov'),
          amount: const drift.Value(850000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 11, 10)),
          createdAt: drift.Value(DateTime.utc(2026, 11, 10)),
        ),
      );
      final resNov = await alertService.checkAndAlertForTransaction(
        (await db.transactionDao.getTransactionById('tx-nov'))!,
      );
      expect(resNov.length, 1);
      expect(resNov.first.yearMonth, '2026-11');
      expect(resNov.first.threshold, BudgetAlertThreshold.warning80);
    });
  });

  group('Unbudgeted Category and Monthly Interaction (Phase 7.4)', () {
    test('unbudgeted category bypasses category alert but triggers monthly budget alert', () async {
      // Monthly total budget = 2.000.000, only 'cat-food' has a limit (500.000).
      // 'cat-transport' is unbudgeted (limit = 0).
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(2000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        const [
          BudgetCategoriesCompanion(
            id: drift.Value('bc-food'),
            budgetId: drift.Value('budget-2026-10'),
            categoryId: drift.Value('cat-food'),
            limitAmount: drift.Value(500000),
          ),
        ],
      );

      // Spend 1.700.000 in unbudgeted 'cat-transport'
      // 1.700.000 / 2.000.000 monthly limit = 85% (triggers monthly warning)
      // 'cat-transport' has limit 0 -> no category alert
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-unbudgeted'),
          amount: const drift.Value(1700000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-transport'),
          source: const drift.Value('BCA'),
          date: drift.Value(DateTime.utc(2026, 10, 12)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 12)),
        ),
      );

      final tx = await db.transactionDao.getTransactionById('tx-unbudgeted');
      final results = await alertService.checkAndAlertForTransaction(tx!);

      expect(results.length, 1);
      final alert = results.first;
      expect(alert.scope, BudgetAlertScope.monthly);
      expect(alert.threshold, BudgetAlertThreshold.warning80);
      expect(alert.percentage, 85);
      expect(alert.title, 'Peringatan Anggaran Bulanan');
    });
  });

  group('Payload and ID Integrity (Phase 7.4)', () {
    test('category alert generates valid JSON payload and valid positive 31-bit notification ID', () async {
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(10000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        const [
          BudgetCategoriesCompanion(
            id: drift.Value('bc-food'),
            budgetId: drift.Value('budget-2026-10'),
            categoryId: drift.Value('cat-food'),
            limitAmount: drift.Value(1000000),
          ),
        ],
      );

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-verify'),
          amount: const drift.Value(850000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 15)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 15)),
        ),
      );

      final tx = await db.transactionDao.getTransactionById('tx-verify');
      final results = await alertService.checkAndAlertForTransaction(tx!);

      expect(results.length, 1);
      final alert = results.first;

      // Validate JSON payload
      final parsed = jsonDecode(alert.payload) as Map<String, dynamic>;
      expect(parsed['type'], 'category');
      expect(parsed['threshold'], 80);
      expect(parsed['categoryId'], 'cat-food');
      expect(parsed['yearMonth'], '2026-10');

      // Validate notification ID fits in signed 32-bit int (> 0 and <= 2147483647)
      expect(alert.notificationId, greaterThan(0));
      expect(alert.notificationId, lessThanOrEqualTo(2147483647));
    });

    test('monthly alert generates valid JSON payload', () async {
      await db.budgetDao.insertBudgetWithCategories(
        BudgetsCompanion(
          id: const drift.Value('budget-2026-10'),
          yearMonth: const drift.Value('2026-10'),
          totalLimit: const drift.Value(1000000),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
        [],
      );

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-m-verify'),
          amount: const drift.Value(850000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Cash'),
          date: drift.Value(DateTime.utc(2026, 10, 15)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 15)),
        ),
      );

      final tx = await db.transactionDao.getTransactionById('tx-m-verify');
      final results = await alertService.checkAndAlertForTransaction(tx!);

      expect(results.length, 1);
      final alert = results.first;

      final parsed = jsonDecode(alert.payload) as Map<String, dynamic>;
      expect(parsed['type'], 'monthly');
      expect(parsed['threshold'], 80);
      expect(parsed['yearMonth'], '2026-10');
      expect(alert.notificationId, greaterThan(0));
      expect(alert.notificationId, lessThanOrEqualTo(2147483647));
    });
  });
}

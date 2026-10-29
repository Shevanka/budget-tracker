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

    // Seed test category
    await db.categoryDao.insertCategory(
      CategoriesCompanion(
        id: const drift.Value('cat-food'),
        name: const drift.Value('Makanan'),
        icon: const drift.Value('restaurant'),
        color: const drift.Value(0xFF4CAF50),
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
}

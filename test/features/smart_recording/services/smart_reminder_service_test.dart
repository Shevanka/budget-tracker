import 'package:budget_tracker/core/constants/default_categories.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/alerts/services/notification_service.dart';
import 'package:budget_tracker/features/smart_recording/models/smart_reminder_status.dart';
import 'package:budget_tracker/features/smart_recording/services/smart_reminder_service.dart';
import 'package:budget_tracker/routing/app_routes.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late AppDatabase db;
  late MockNotificationService mockNotificationService;
  late SmartReminderService service;

  final fixedDate = DateTime(2026, 10, 30, 20, 0);

  setUp(() async {
    db = AppDatabase.inMemory(seedDefaults: true);
    mockNotificationService = MockNotificationService();

    when(
      () => mockNotificationService.showReminder(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockNotificationService.cancel(any()),
    ).thenAnswer((_) async {});

    service = SmartReminderService(
      db: db,
      notificationService: mockNotificationService,
      clock: () => fixedDate,
    );
  });

  tearDown(() async {
    service.dispose();
    await db.close();
  });

  group('SmartReminderService', () {
    test('sends notification when no transactions exist today', () async {
      final status = await service.evaluateAndRemind();

      expect(status.didNotify, isTrue);
      expect(status.todayExpenseCount, 0);
      expect(status.todayExpenseSum, 0);
      expect(status.hasExpensesToday, isFalse);
      expect(status.notificationTitle, equals(SmartReminderService.defaultTitle));
      expect(status.notificationBody, equals(SmartReminderService.defaultBody));

      verify(
        () => mockNotificationService.showReminder(
          id: SmartReminderService.reminderNotificationId,
          title: SmartReminderService.defaultTitle,
          body: SmartReminderService.defaultBody,
          payload: AppRoute.addTransaction.path,
        ),
      ).called(1);
    });

    test('sends reminder when only income transactions exist today', () async {
      // Insert income transaction today
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-income-1'),
          amount: const drift.Value(5000000),
          type: const drift.Value(TransactionType.income),
          categoryId: const drift.Value(DefaultCategories.salaryId),
          source: const drift.Value('BCA'),
          date: drift.Value(fixedDate),
          createdAt: drift.Value(fixedDate),
        ),
      );

      final status = await service.evaluateAndRemind();

      expect(status.didNotify, isTrue);
      expect(status.todayExpenseCount, 0);
      expect(status.hasExpensesToday, isFalse);

      verify(
        () => mockNotificationService.showReminder(
          id: SmartReminderService.reminderNotificationId,
          title: SmartReminderService.defaultTitle,
          body: SmartReminderService.defaultBody,
          payload: AppRoute.addTransaction.path,
        ),
      ).called(1);
    });

    test('skips notification when expense transactions exist today', () async {
      // Insert expense transaction today
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-expense-1'),
          amount: const drift.Value(45000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value(DefaultCategories.foodId),
          source: const drift.Value('GoPay'),
          date: drift.Value(fixedDate),
          createdAt: drift.Value(fixedDate),
        ),
      );

      final status = await service.evaluateAndRemind();

      expect(status.didNotify, isFalse);
      expect(status.todayExpenseCount, 1);
      expect(status.todayExpenseSum, 45000);
      expect(status.hasExpensesToday, isTrue);

      verifyNever(
        () => mockNotificationService.showReminder(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      );
    });

    test('ignores expenses from yesterday or other dates', () async {
      // Insert expense from yesterday
      final yesterday = fixedDate.subtract(const Duration(days: 1));
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-expense-yesterday'),
          amount: const drift.Value(75000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value(DefaultCategories.foodId),
          source: const drift.Value('GoPay'),
          date: drift.Value(yesterday),
          createdAt: drift.Value(yesterday),
        ),
      );

      final status = await service.evaluateAndRemind();

      expect(status.didNotify, isTrue);
      expect(status.todayExpenseCount, 0);

      verify(
        () => mockNotificationService.showReminder(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).called(1);
    });

    test('sends notification when force is true even if expenses exist', () async {
      // Insert 2 expense transactions today
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-expense-1'),
          amount: const drift.Value(30000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value(DefaultCategories.foodId),
          source: const drift.Value('GoPay'),
          date: drift.Value(fixedDate),
          createdAt: drift.Value(fixedDate),
        ),
      );
      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-expense-2'),
          amount: const drift.Value(20000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value(DefaultCategories.transportId),
          source: const drift.Value('OVO'),
          date: drift.Value(fixedDate),
          createdAt: drift.Value(fixedDate),
        ),
      );

      final status = await service.evaluateAndRemind(force: true);

      expect(status.didNotify, isTrue);
      expect(status.todayExpenseCount, 2);
      expect(status.todayExpenseSum, 50000);
      expect(status.message, contains('2 expense(s) already logged'));

      verify(
        () => mockNotificationService.showReminder(
          id: SmartReminderService.reminderNotificationId,
          title: SmartReminderService.defaultTitle,
          body: any(named: 'body', that: contains('2 expenses today')),
          payload: AppRoute.addTransaction.path,
        ),
      ).called(1);
    });

    test('starts and cancels periodic reminder timer', () async {
      expect(service.isPeriodicRunning, isFalse);

      service.startPeriodicReminder(interval: const Duration(seconds: 1));
      expect(service.isPeriodicRunning, isTrue);

      await service.cancelReminder();
      expect(service.isPeriodicRunning, isFalse);

      verify(() => mockNotificationService.cancel(SmartReminderService.reminderNotificationId)).called(1);
    });

    test('SmartReminderStatus model properties and equality', () {
      const s1 = SmartReminderStatus(
        didNotify: true,
        todayExpenseCount: 0,
        todayExpenseSum: 0,
        message: 'No expenses',
        notificationTitle: 'Title',
        notificationBody: 'Body',
      );
      const s2 = SmartReminderStatus(
        didNotify: true,
        todayExpenseCount: 0,
        todayExpenseSum: 0,
        message: 'No expenses',
        notificationTitle: 'Title',
        notificationBody: 'Body',
      );
      const s3 = SmartReminderStatus(
        didNotify: false,
        todayExpenseCount: 1,
        todayExpenseSum: 50000,
        message: 'Has expenses',
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
      expect(s1.hasExpensesToday, isFalse);
      expect(s3.hasExpensesToday, isTrue);
      expect(s1.toString(), contains('didNotify: true'));
    });
  });
}

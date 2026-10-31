import 'package:budget_tracker/core/constants/default_categories.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/database_provider.dart';
import 'package:budget_tracker/features/notification_watcher/providers/draft_transaction_provider.dart';
import 'package:budget_tracker/features/notification_watcher/providers/notification_watcher_provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.inMemory();
    await db.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        id: DefaultCategories.foodId,
        name: DefaultCategories.foodName,
        icon: 'restaurant',
        color: 0xFF43A047,
        type: const drift.Value(TransactionType.expense),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await db.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        id: DefaultCategories.shoppingId,
        name: DefaultCategories.shoppingName,
        icon: 'shopping_bag',
        color: 0xFFFB8C00,
        type: const drift.Value(TransactionType.expense),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('DraftTransaction & draftTransactionProvider', () {
    test('pendingDraftTransactionsProvider parses unparsed logs into DraftTransactions', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final logService = container.read(notificationLogServiceProvider);

      // Insert 2 raw logs
      await logService.logRaw(
        appPackage: 'com.bca',
        title: 'm-BCA',
        body: 'Pembelian di INDOMARET Rp 45.000,00 di rek *1234',
      );
      await logService.logRaw(
        appPackage: 'id.co.bankmandiri.livin',
        body: 'Pembayaran QRIS sebesar Rp 35.000 di WARUNG KOPI berhasil.',
      );

      final drafts = await container.read(pendingDraftTransactionsProvider.future);
      expect(drafts.length, 2);

      final bcaDraft = drafts.firstWhere((d) => d.appPackage == 'com.bca');
      expect(bcaDraft.isRecognized, isTrue);
      expect(bcaDraft.source, equals('BCA'));
      expect(bcaDraft.amount, equals(45000));
      expect(bcaDraft.merchant, equals('INDOMARET'));
      expect(bcaDraft.suggestedCategoryId, equals(DefaultCategories.shoppingId));

      final mandiriDraft = drafts.firstWhere((d) => d.appPackage == 'id.co.bankmandiri.livin');
      expect(mandiriDraft.isRecognized, isTrue);
      expect(mandiriDraft.source, equals('Mandiri'));
      expect(mandiriDraft.amount, equals(35000));
      expect(mandiriDraft.merchant, equals('WARUNG KOPI'));
      expect(mandiriDraft.suggestedCategoryId, equals(DefaultCategories.foodId));
    });

    test('confirmDraft creates transaction and marks log as parsed', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final logService = container.read(notificationLogServiceProvider);
      final rawLog = await logService.logRaw(
        appPackage: 'com.bca',
        body: 'Pembelian di INDOMARET Rp 45.000,00 di rek *1234',
      );
      expect(rawLog, isNotNull);

      final drafts = await container.read(pendingDraftTransactionsProvider.future);
      expect(drafts.length, 1);
      final draft = drafts.first;

      final success = await container
          .read(draftTransactionControllerProvider.notifier)
          .confirmDraft(
            draft: draft,
            categoryId: DefaultCategories.shoppingId,
          );

      expect(success, isTrue);

      // Verify transaction exists in database
      final allTx = await db.transactionDao.getTransactionsWithCategory();
      expect(allTx.length, 1);
      expect(allTx.first.transaction.amount, equals(45000));
      expect(allTx.first.transaction.source, equals('BCA'));
      expect(allTx.first.transaction.note, equals('INDOMARET'));
      expect(allTx.first.transaction.categoryId, equals(DefaultCategories.shoppingId));

      // Verify notification log is now marked parsed
      final updatedLog = await logService.getLogById(rawLog!.id);
      expect(updatedLog!.parsed, isTrue);
      expect(updatedLog.transactionId, equals(allTx.first.transaction.id));
    });

    test('dismissDraft removes unconfirmed notification log from database', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final logService = container.read(notificationLogServiceProvider);
      final rawLog = await logService.logRaw(
        appPackage: 'id.dana',
        body: 'Bayar Rp 50.000 ke PLN Prabayar berhasil.',
      );
      expect(rawLog, isNotNull);

      final success = await container
          .read(draftTransactionControllerProvider.notifier)
          .dismissDraft(rawLog!.id);

      expect(success, isTrue);

      final deletedLog = await logService.getLogById(rawLog.id);
      expect(deletedLog, isNull);
    });

    test('confirmAll confirms all recognized drafts in batch', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final logService = container.read(notificationLogServiceProvider);
      await logService.logRaw(
        appPackage: 'com.bca',
        body: 'Pembelian di INDOMARET Rp 45.000,00 di rek *1234',
      );
      await logService.logRaw(
        appPackage: 'id.co.bankmandiri.livin',
        body: 'Pembayaran QRIS sebesar Rp 35.000 di WARUNG KOPI berhasil.',
      );

      final drafts = await container.read(pendingDraftTransactionsProvider.future);
      expect(drafts.length, 2);

      final confirmedCount = await container
          .read(draftTransactionControllerProvider.notifier)
          .confirmAll(drafts);

      expect(confirmedCount, equals(2));

      final allTx = await db.transactionDao.getTransactionsWithCategory();
      expect(allTx.length, 2);

      final remainingUnparsed = await logService.getUnparsedLogs();
      expect(remainingUnparsed, isEmpty);
    });
  });
}

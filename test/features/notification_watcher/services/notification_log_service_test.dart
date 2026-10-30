import 'package:budget_tracker/core/constants/default_categories.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/features/notification_watcher/constants/watched_apps.dart';
import 'package:budget_tracker/features/notification_watcher/services/notification_log_service.dart';
import 'package:budget_tracker/features/notification_watcher/services/notification_parser.dart';
import 'package:budget_tracker/features/notification_watcher/services/notification_watcher_service.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:notification_listener_service/notification_event.dart';

void main() {
  late AppDatabase db;
  late NotificationLogService logService;
  late NotificationWatcherService watcherService;

  setUp(() {
    db = AppDatabase.inMemory();
    logService = NotificationLogService(db.notificationLogDao);
    watcherService = NotificationWatcherService(
      logService: logService,
      parser: const NotificationParser(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  ServiceNotificationEvent createEvent({
    int id = 1,
    String packageName = 'com.bca',
    String title = 'm-BCA',
    String content = 'Pembelian di INDOMARET Rp 45.000,00 di rek *1234',
    bool hasRemoved = false,
    int? timestamp,
  }) {
    return ServiceNotificationEvent(
      id: id,
      packageName: packageName,
      title: title,
      content: content,
      hasRemoved: hasRemoved,
      canReply: false,
      haveExtraPicture: false,
      onGoing: false,
      timestamp: timestamp ?? DateTime.utc(2026, 10, 30, 14, 0).millisecondsSinceEpoch,
      appIcon: null,
      extrasPicture: null,
      largeIcon: null,
    );
  }

  group('NotificationLogService', () {
    test('logNotificationEvent persists valid notification into database', () async {
      final event = createEvent();

      final log = await logService.logNotificationEvent(event);

      expect(log, isNotNull);
      expect(log!.appPackage, equals('com.bca'));
      expect(log.title, equals('m-BCA'));
      expect(log.body, equals('Pembelian di INDOMARET Rp 45.000,00 di rek *1234'));
      expect(log.parsed, isFalse);
      expect(log.transactionId, isNull);

      final fromDb = await logService.getLogById(log.id);
      expect(fromDb, isNotNull);
      expect(fromDb!.id, equals(log.id));
    });

    test('logNotificationEvent ignores dismissed / removed notifications', () async {
      final event = createEvent(hasRemoved: true);

      final log = await logService.logNotificationEvent(event);
      expect(log, isNull);

      final unparsed = await logService.getUnparsedLogs();
      expect(unparsed, isEmpty);
    });

    test('logNotificationEvent filters out packages not in watchedPackages', () async {
      final event = createEvent(packageName: 'com.whatsapp');

      final log = await logService.logNotificationEvent(
        event,
        watchedPackages: WatchedApps.allPackageNames,
      );

      expect(log, isNull);

      final allLogs = await logService.getAllLogs();
      expect(allLogs, isEmpty);
    });

    test('logNotificationEvent allows packages in watchedPackages (case-insensitive)', () async {
      final event = createEvent(packageName: 'COM.BCA');

      final log = await logService.logNotificationEvent(
        event,
        watchedPackages: {'com.bca', 'id.co.gopay'},
      );

      expect(log, isNotNull);
      expect(log!.appPackage, equals('COM.BCA'));
    });

    test('logNotificationEvent ignores notifications with empty title and empty body', () async {
      final event = createEvent(title: '   ', content: '');

      final log = await logService.logNotificationEvent(event);
      expect(log, isNull);
    });

    test('logRaw inserts and retrieves logs directly', () async {
      final log = await logService.logRaw(
        appPackage: 'id.co.bankmandiri.livin',
        title: 'Livin',
        body: 'Pembayaran QRIS sebesar Rp 35.000 di WARUNG KOPI berhasil.',
      );

      expect(log, isNotNull);
      expect(log!.appPackage, equals('id.co.bankmandiri.livin'));
      expect(log.body, contains('WARUNG KOPI'));

      final unparsed = await logService.getUnparsedLogs();
      expect(unparsed.length, 1);
    });

    test('markAsParsed updates parsed flag and links transaction ID', () async {
      // Seed category and transaction first to satisfy foreign key
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: const drift.Value('cat-food'),
          name: const drift.Value('Food'),
          icon: const drift.Value('restaurant'),
          color: const drift.Value(0xFF43A047),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      );

      await db.transactionDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value('tx-100'),
          amount: const drift.Value(35000),
          type: const drift.Value(TransactionType.expense),
          categoryId: const drift.Value('cat-food'),
          source: const drift.Value('Mandiri'),
          date: drift.Value(DateTime.utc(2026, 10, 30)),
          createdAt: drift.Value(DateTime.utc(2026, 10, 30)),
        ),
      );

      final log = await logService.logRaw(
        appPackage: 'id.co.bankmandiri.livin',
        body: 'Pembayaran QRIS sebesar Rp 35.000 di WARUNG KOPI berhasil.',
      );
      expect(log, isNotNull);

      await logService.markAsParsed(
        logId: log!.id,
        transactionId: 'tx-100',
      );

      final updated = await logService.getLogById(log.id);
      expect(updated!.parsed, isTrue);
      expect(updated.transactionId, equals('tx-100'));

      final unparsed = await logService.getUnparsedLogs();
      expect(unparsed, isEmpty);
    });

    test('deleteLog removes the entry from the database', () async {
      final log = await logService.logRaw(
        appPackage: 'id.dana',
        body: 'Bayar Rp 50.000 ke PLN Prabayar berhasil.',
      );
      expect(log, isNotNull);

      await logService.deleteLog(log!.id);

      final deleted = await logService.getLogById(log.id);
      expect(deleted, isNull);
    });

    test('watchUnparsedLogs and watchAllLogs emit stream updates', () async {
      await logService.logRaw(
        appPackage: 'ovo.id',
        body: 'Berhasil bayar Rp 20.000 di Kopi Kenangan.',
      );

      final unparsed = await logService.watchUnparsedLogs().first;
      expect(unparsed.length, 1);
      expect(unparsed.first.appPackage, equals('ovo.id'));

      final all = await logService.watchAllLogs().first;
      expect(all.length, 1);
      expect(all.first.body, contains('Kopi Kenangan'));
    });
  });

  group('NotificationWatcherService', () {
    test('processEvent logs raw notification and parses recognized financial transaction', () async {
      final event = createEvent(
        packageName: 'com.bca',
        title: 'BCA Mobile',
        content: 'Pembelian di INDOMARET Rp 45.000,00 di rek *1234',
      );

      final payload = await watcherService.processEvent(
        event,
        watchedPackages: WatchedApps.allPackageNames,
      );

      expect(payload, isNotNull);
      expect(payload!.isTransaction, isTrue);
      expect(payload.log.appPackage, equals('com.bca'));
      expect(payload.log.parsed, isFalse);

      expect(payload.parsed, isNotNull);
      expect(payload.parsed!.source, equals('BCA'));
      expect(payload.parsed!.amount, equals(45000));
      expect(payload.parsed!.merchant, equals('INDOMARET'));
      expect(payload.parsed!.suggestedCategoryId, equals(DefaultCategories.shoppingId));
    });

    test('processEvent logs non-financial notification but marks parsed as null', () async {
      final promoEvent = createEvent(
        packageName: 'com.gojek.app',
        title: 'Promo GoPay',
        content: 'Dapatkan diskon 50% untuk pesanan makanan kamu hari ini!',
      );

      final payload = await watcherService.processEvent(
        promoEvent,
        watchedPackages: WatchedApps.allPackageNames,
      );

      expect(payload, isNotNull);
      expect(payload!.isTransaction, isFalse);
      expect(payload.parsed, isNull);

      // Log was still safely recorded in the database
      final fromDb = await logService.getLogById(payload.log.id);
      expect(fromDb, isNotNull);
      expect(fromDb!.body, contains('Dapatkan diskon 50%'));
    });

    test('processEvent returns null when event is dismissed or unwatched', () async {
      final unwatchedEvent = createEvent(
        packageName: 'com.random.app',
        content: 'Hello world',
      );

      final payload = await watcherService.processEvent(
        unwatchedEvent,
        watchedPackages: WatchedApps.allPackageNames,
      );

      expect(payload, isNull);
    });
  });
}

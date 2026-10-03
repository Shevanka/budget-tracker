// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_log_dao.dart';

// ignore_for_file: type=lint
mixin _$NotificationLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  $NotificationLogsTable get notificationLogs =>
      attachedDatabase.notificationLogs;
  NotificationLogDaoManager get managers => NotificationLogDaoManager(this);
}

class NotificationLogDaoManager {
  final _$NotificationLogDaoMixin _db;
  NotificationLogDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
  $$NotificationLogsTableTableManager get notificationLogs =>
      $$NotificationLogsTableTableManager(
        _db.attachedDatabase,
        _db.notificationLogs,
      );
}

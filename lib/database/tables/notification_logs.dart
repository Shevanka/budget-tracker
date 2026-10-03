import 'package:drift/drift.dart';
import 'transactions.dart';

/// Notification logs table to store incoming bank/e-wallet notifications.
@TableIndex(name: 'idx_notification_logs_received_at', columns: {#receivedAt})
class NotificationLogs extends Table {
  TextColumn get id => text()();
  TextColumn get appPackage => text()();
  TextColumn get title => text().nullable()();
  TextColumn get body => text().nullable()();
  DateTimeColumn get receivedAt => dateTime()();
  BoolColumn get parsed => boolean().withDefault(const Constant(false))();
  TextColumn get transactionId =>
      text().nullable().references(Transactions, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

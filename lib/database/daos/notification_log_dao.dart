import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/notification_logs.dart';

part 'notification_log_dao.g.dart';

@DriftAccessor(tables: [NotificationLogs])
class NotificationLogDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationLogDaoMixin {
  NotificationLogDao(super.db);

  /// Normalizes DateTime fields in [entry] to UTC.
  NotificationLogsCompanion _normalizeUtc(NotificationLogsCompanion entry) {
    return entry.copyWith(
      receivedAt: entry.receivedAt.present
          ? Value(entry.receivedAt.value.toUtc())
          : const Value.absent(),
    );
  }

  /// Inserts a newly intercepted system notification log with UTC-normalized receivedAt.
  Future<int> insertLog(NotificationLogsCompanion entry) {
    return into(notificationLogs).insert(_normalizeUtc(entry));
  }

  /// Fetches a notification log by id.
  Future<NotificationLog?> getLogById(String id) {
    return (select(notificationLogs)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Fetches unparsed notification logs ordered by receivedAt descending.
  Future<List<NotificationLog>> getUnparsedLogs() {
    return (select(notificationLogs)
          ..where((tbl) => tbl.parsed.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.receivedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Streams unparsed notification logs.
  Stream<List<NotificationLog>> watchUnparsedLogs() {
    return (select(notificationLogs)
          ..where((tbl) => tbl.parsed.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
                expression: tbl.receivedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Marks a log as parsed and links it to the confirmed transaction ID.
  Future<int> markAsParsed(String logId, String transactionId) {
    return (update(notificationLogs)..where((tbl) => tbl.id.equals(logId)))
        .write(
      NotificationLogsCompanion(
        parsed: const Value(true),
        transactionId: Value(transactionId),
      ),
    );
  }

  /// Deletes a notification log.
  Future<int> deleteLog(String id) {
    return (delete(notificationLogs)..where((tbl) => tbl.id.equals(id))).go();
  }
}

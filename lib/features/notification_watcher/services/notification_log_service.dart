import 'package:drift/drift.dart';
import 'package:notification_listener_service/notification_event.dart';

import '../../../core/utils/id_generator.dart';
import '../../../database/app_database.dart';
import '../../../database/daos/notification_log_dao.dart';

/// Service responsible for recording, querying, and managing raw incoming notifications
/// in the [NotificationLogs] database table.
class NotificationLogService {
  final NotificationLogDao _dao;

  const NotificationLogService(this._dao);

  /// Validates and records an incoming [ServiceNotificationEvent] into [NotificationLogs].
  ///
  /// Filters out:
  /// - Dismissed/removed notification events (`event.hasRemoved == true`).
  /// - Events without a valid package name.
  /// - Events whose package is not present in [watchedPackages] (if specified).
  /// - Empty events with neither title nor content.
  ///
  /// Returns the saved [NotificationLog], or `null` if the event was ignored.
  Future<NotificationLog?> logNotificationEvent(
    ServiceNotificationEvent event, {
    Set<String>? watchedPackages,
  }) async {
    if (event.hasRemoved == true) return null;

    final packageName = event.packageName.trim();
    if (packageName.isEmpty) return null;

    if (watchedPackages != null &&
        !watchedPackages.any((p) => p.toLowerCase() == packageName.toLowerCase())) {
      return null;
    }

    final title = event.title.trim();
    final body = event.content.trim();

    if (title.isEmpty && body.isEmpty) {
      return null;
    }

    final receivedAt = event.timestamp > 0
        ? DateTime.fromMillisecondsSinceEpoch(event.timestamp, isUtc: true)
        : DateTime.now().toUtc();

    return logRaw(
      appPackage: packageName,
      title: title.isNotEmpty ? title : null,
      body: body.isNotEmpty ? body : null,
      receivedAt: receivedAt,
    );
  }

  /// Inserts a raw notification log entry with explicit fields.
  Future<NotificationLog?> logRaw({
    required String appPackage,
    String? title,
    String? body,
    DateTime? receivedAt,
    Set<String>? watchedPackages,
  }) async {
    final cleanPackage = appPackage.trim();
    if (cleanPackage.isEmpty) return null;

    if (watchedPackages != null &&
        !watchedPackages.any((p) => p.toLowerCase() == cleanPackage.toLowerCase())) {
      return null;
    }

    final cleanTitle = title?.trim();
    final cleanBody = body?.trim();

    if ((cleanTitle == null || cleanTitle.isEmpty) &&
        (cleanBody == null || cleanBody.isEmpty)) {
      return null;
    }

    final id = IdGenerator.generate();
    final timestamp = (receivedAt ?? DateTime.now()).toUtc();

    final companion = NotificationLogsCompanion(
      id: Value(id),
      appPackage: Value(cleanPackage),
      title: Value(cleanTitle),
      body: Value(cleanBody),
      receivedAt: Value(timestamp),
      parsed: const Value(false),
      transactionId: const Value(null),
    );

    await _dao.insertLog(companion);
    return _dao.getLogById(id);
  }

  /// Fetches a specific notification log by its [id].
  Future<NotificationLog?> getLogById(String id) => _dao.getLogById(id);

  /// Retrieves unparsed notification logs ordered by receipt timestamp descending.
  Future<List<NotificationLog>> getUnparsedLogs() => _dao.getUnparsedLogs();

  /// Watches unparsed notification logs in real time.
  Stream<List<NotificationLog>> watchUnparsedLogs() => _dao.watchUnparsedLogs();

  /// Retrieves recent notification logs up to [limit].
  Future<List<NotificationLog>> getAllLogs({int limit = 50}) =>
      _dao.getAllLogs(limit: limit);

  /// Watches recent notification logs up to [limit] in real time.
  Stream<List<NotificationLog>> watchAllLogs({int limit = 50}) =>
      _dao.watchAllLogs(limit: limit);

  /// Marks a notification log as confirmed/parsed and links it to [transactionId].
  Future<int> markAsParsed({
    required String logId,
    required String transactionId,
  }) {
    return _dao.markAsParsed(logId, transactionId);
  }

  /// Deletes a notification log entry by [id].
  Future<int> deleteLog(String id) => _dao.deleteLog(id);
}

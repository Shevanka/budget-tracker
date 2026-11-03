import 'package:notification_listener_service/notification_event.dart';

import '../../../database/app_database.dart';
import '../models/parsed_notification.dart';
import 'notification_log_service.dart';
import 'notification_parser.dart';

/// Encapsulates an intercepted notification log along with any financial
/// transaction data parsed from it.
class IncomingNotificationPayload {
  /// The persisted database record representing the raw notification.
  final NotificationLog log;

  /// The parsed financial transaction details, or `null` if the notification
  /// was promotional or did not match any banking/e-wallet transaction format.
  final ParsedNotification? parsed;

  const IncomingNotificationPayload({
    required this.log,
    this.parsed,
  });

  /// Whether this notification represents a recognized financial transaction.
  bool get isTransaction => parsed != null;

  @override
  String toString() =>
      'IncomingNotificationPayload(logId: ${log.id}, isTransaction: $isTransaction, parsed: $parsed)';
}

/// Coordinates the processing of incoming system notifications: persists raw notifications
/// into [NotificationLogs] via [NotificationLogService], and runs [NotificationParser]
/// to extract financial transaction details.
class NotificationWatcherService {
  final NotificationLogService _logService;
  final NotificationParser _parser;

  const NotificationWatcherService({
    required NotificationLogService logService,
    required NotificationParser parser,
  })  : _logService = logService,
          _parser = parser;

  /// Processes an intercepted [ServiceNotificationEvent]:
  /// 1. Persists the raw event to the database via [NotificationLogService].
  /// 2. If valid and saved, parses the body/title with [NotificationParser].
  /// 3. Returns an [IncomingNotificationPayload] combining the saved log and parsed result.
  Future<IncomingNotificationPayload?> processEvent(
    ServiceNotificationEvent event, {
    Set<String>? watchedPackages,
  }) async {
    final log = await _logService.logNotificationEvent(
      event,
      watchedPackages: watchedPackages,
    );

    if (log == null) return null;

    final parsed = _parser.parse(
      body: log.body ?? '',
      title: log.title,
      appPackage: log.appPackage,
      timestamp: log.receivedAt,
    );

    return IncomingNotificationPayload(
      log: log,
      parsed: parsed,
    );
  }
}

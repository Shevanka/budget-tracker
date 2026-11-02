import 'dart:async';

import '../../../database/app_database.dart';
import '../../../database/converters/transaction_type.dart';
import '../../../routing/app_routes.dart';
import '../../alerts/services/notification_service.dart';
import '../models/smart_reminder_status.dart';

/// Service responsible for periodic smart reminder notifications ("Did you spend today?").
///
/// Evaluates daily transaction recording and reminds users if they haven't logged
/// any expenses for the day.
class SmartReminderService {
  final AppDatabase _db;
  final NotificationService _notificationService;
  final DateTime Function() _clock;

  Timer? _periodicTimer;

  /// Default notification ID for the smart reminder.
  static const int reminderNotificationId = 888888;

  /// Standard English notification title and body.
  static const String defaultTitle = 'Did you spend today?';
  static const String defaultBody =
      "You haven't recorded any expenses today. Tap to add your spending before the day ends!";

  /// Standard Indonesian notification title and body.
  static const String defaultIndonesianTitle = 'Sudah catat pengeluaran hari ini?';
  static const String defaultIndonesianBody =
      'Kamu belum mencatat pengeluaran hari ini. Ketuk untuk mencatat transaksi sebelum hari berganti!';

  SmartReminderService({
    required AppDatabase db,
    required NotificationService notificationService,
    DateTime Function()? clock,
  })  : _db = db,
        _notificationService = notificationService,
        _clock = clock ?? DateTime.now;

  /// Whether a periodic reminder timer is actively running.
  bool get isPeriodicRunning => _periodicTimer != null && _periodicTimer!.isActive;

  /// Evaluates today's transactions and sends a smart reminder notification if no expenses
  /// were recorded, or if [force] is true (e.g. for testing / simulation from settings).
  Future<SmartReminderStatus> evaluateAndRemind({bool force = false}) async {
    final now = _clock();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    final todayTransactions =
        await _db.transactionDao.getTransactionsByDateRange(startOfDay, endOfDay);

    final todayExpenses = todayTransactions
        .where((t) => t.type == TransactionType.expense)
        .toList();

    final expenseCount = todayExpenses.length;
    final expenseSum = todayExpenses.fold<int>(0, (sum, t) => sum + t.amount);

    if (expenseCount == 0 || force) {
      const title = defaultTitle;
      final body = expenseCount == 0
          ? defaultBody
          : 'Great job! You have logged $expenseCount expense${expenseCount > 1 ? 's' : ''} today.';

      await _notificationService.showReminder(
        id: reminderNotificationId,
        title: title,
        body: body,
        payload: AppRoute.addTransaction.path,
      );

      return SmartReminderStatus(
        didNotify: true,
        todayExpenseCount: expenseCount,
        todayExpenseSum: expenseSum,
        notificationTitle: title,
        notificationBody: body,
        message: expenseCount == 0
            ? 'Reminder sent: No expenses recorded today.'
            : 'Simulated reminder sent: $expenseCount expense(s) already logged.',
      );
    }

    return SmartReminderStatus(
      didNotify: false,
      todayExpenseCount: expenseCount,
      todayExpenseSum: expenseSum,
      message: 'Reminder skipped: User already logged $expenseCount expense(s) today.',
    );
  }

  /// Starts a periodic reminder check timer (e.g. daily interval).
  void startPeriodicReminder({
    Duration interval = const Duration(hours: 24),
  }) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) {
      evaluateAndRemind();
    });
  }

  /// Cancels any active periodic timer and clears the active reminder notification.
  Future<void> cancelReminder() async {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    await _notificationService.cancel(reminderNotificationId);
  }

  /// Disposes timer resources.
  void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}

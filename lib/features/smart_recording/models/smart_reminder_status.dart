/// Represents the result of evaluating whether to send a daily smart spending reminder.
class SmartReminderStatus {
  /// Whether a reminder notification was dispatched to the system.
  final bool didNotify;

  /// The count of expenses recorded today at the time of evaluation.
  final int todayExpenseCount;

  /// The sum of expenses recorded today in whole Rupiah.
  final int todayExpenseSum;

  /// The title of the notification displayed (if notified).
  final String? notificationTitle;

  /// The message body of the notification displayed (if notified).
  final String? notificationBody;

  /// Explanation message describing the reminder evaluation.
  final String message;

  const SmartReminderStatus({
    required this.didNotify,
    required this.todayExpenseCount,
    required this.todayExpenseSum,
    required this.message,
    this.notificationTitle,
    this.notificationBody,
  });

  /// Whether any expenses have been recorded today.
  bool get hasExpensesToday => todayExpenseCount > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartReminderStatus &&
          runtimeType == other.runtimeType &&
          didNotify == other.didNotify &&
          todayExpenseCount == other.todayExpenseCount &&
          todayExpenseSum == other.todayExpenseSum &&
          notificationTitle == other.notificationTitle &&
          notificationBody == other.notificationBody &&
          message == other.message;

  @override
  int get hashCode => Object.hash(
        didNotify,
        todayExpenseCount,
        todayExpenseSum,
        notificationTitle,
        notificationBody,
        message,
      );

  @override
  String toString() =>
      'SmartReminderStatus(didNotify: $didNotify, count: $todayExpenseCount, message: "$message")';
}

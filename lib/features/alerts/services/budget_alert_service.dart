import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/year_month_utils.dart';
import '../../../../database/app_database.dart';
import '../../../../database/converters/transaction_type.dart';
import '../../budget/domain/services/budget_service.dart';
import 'notification_service.dart';

/// Semantic threshold levels for triggering budget notifications.
enum BudgetAlertThreshold {
  /// 80% to 99% budget consumption warning.
  warning80,

  /// 100% or more budget consumption exceeded.
  exceeded100,
}

/// Scope of a budget alert: either an individual category or the total monthly budget.
enum BudgetAlertScope {
  category,
  monthly,
}

/// Information about a triggered budget alert notification.
class BudgetAlertResult {
  final BudgetAlertScope scope;
  final BudgetAlertThreshold threshold;
  final String yearMonth;
  final String? categoryId;
  final String? categoryName;
  final int spent;
  final int limit;
  final int percentage;
  final String title;
  final String body;
  final String payload;
  final int notificationId;

  const BudgetAlertResult({
    required this.scope,
    required this.threshold,
    required this.yearMonth,
    this.categoryId,
    this.categoryName,
    required this.spent,
    required this.limit,
    required this.percentage,
    required this.title,
    required this.body,
    required this.payload,
    required this.notificationId,
  });

  @override
  String toString() =>
      'BudgetAlertResult(scope: ${scope.name}, threshold: ${threshold.name}, yearMonth: $yearMonth, category: $categoryName, percentage: $percentage%)';
}

/// Service evaluating budget thresholds after transaction mutations and
/// triggering local notifications when 80% warning or 100% exceeded thresholds are hit.
class BudgetAlertService {
  final BudgetService _budgetService;
  final NotificationService _notificationService;
  final Set<String> _firedAlertKeys;

  BudgetAlertService({
    required BudgetService budgetService,
    required NotificationService notificationService,
    Set<String>? firedAlertKeys,
  })  : _budgetService = budgetService,
        _notificationService = notificationService,
        _firedAlertKeys = firedAlertKeys ?? <String>{};

  /// Set of deduplication keys that have already been fired.
  Set<String> get firedAlertKeys => Set.unmodifiable(_firedAlertKeys);

  /// Key for category alert deduplication.
  String getCategoryAlertKey({
    required String yearMonth,
    required String categoryId,
    required BudgetAlertThreshold threshold,
  }) =>
      'category:${threshold.name}:$yearMonth:$categoryId';

  /// Key for monthly alert deduplication.
  String getMonthlyAlertKey({
    required String yearMonth,
    required BudgetAlertThreshold threshold,
  }) =>
      'monthly:${threshold.name}:$yearMonth';

  /// Returns true if the alert identified by [key] has already fired.
  bool isAlertFired(String key) => _firedAlertKeys.contains(key);

  /// Manually marks an alert key as fired.
  void markAlertFired(String key) => _firedAlertKeys.add(key);

  /// Resets tracked alerts. If [yearMonth] is specified, only resets alerts
  /// belonging to that month; otherwise clears all tracking.
  void resetTracking({String? yearMonth}) {
    if (yearMonth == null) {
      _firedAlertKeys.clear();
    } else {
      _firedAlertKeys.removeWhere((key) => key.contains(yearMonth));
    }
  }

  /// Evaluates budget thresholds for [transaction] and dispatches notifications
  /// if 80% or 100% thresholds are crossed and have not yet been notified.
  ///
  /// Returns a list of [BudgetAlertResult] for any alerts triggered.
  Future<List<BudgetAlertResult>> checkAndAlertForTransaction(
    Transaction transaction,
  ) async {
    // Only expense transactions consume budget and trigger alerts
    if (transaction.type != TransactionType.expense) {
      return const [];
    }

    final yearMonth = YearMonthUtils.toYearMonth(transaction.date);
    final triggeredAlerts = <BudgetAlertResult>[];

    // 1. Check category-level budget alert
    try {
      final categoryAlert = await _checkCategoryAlert(
        yearMonth: yearMonth,
        categoryId: transaction.categoryId,
      );
      if (categoryAlert != null) {
        triggeredAlerts.add(categoryAlert);
      }
    } catch (e) {
      debugPrint('Failed to evaluate category budget alert: $e');
    }

    // 2. Check monthly-level budget alert
    try {
      final monthlyAlert = await _checkMonthlyAlert(yearMonth: yearMonth);
      if (monthlyAlert != null) {
        triggeredAlerts.add(monthlyAlert);
      }
    } catch (e) {
      debugPrint('Failed to evaluate monthly budget alert: $e');
    }

    return triggeredAlerts;
  }

  Future<BudgetAlertResult?> _checkCategoryAlert({
    required String yearMonth,
    required String categoryId,
  }) async {
    final status = await _budgetService.getCategoryBudgetStatus(
      yearMonth,
      categoryId,
    );

    if (status == null || !status.hasLimit) {
      return null;
    }

    final categoryName = status.category.name;
    final percentage = status.percentage;
    final spentFormatted = CurrencyFormatter.format(status.spent);
    final limitFormatted = CurrencyFormatter.format(status.limit);

    // Evaluate 100% exceeded first
    if (status.isExceeded || percentage >= 100) {
      final key100 = getCategoryAlertKey(
        yearMonth: yearMonth,
        categoryId: categoryId,
        threshold: BudgetAlertThreshold.exceeded100,
      );

      if (!_firedAlertKeys.contains(key100)) {
        _firedAlertKeys.add(key100);
        // Also suppress 80% warning once exceeded has fired
        final key80 = getCategoryAlertKey(
          yearMonth: yearMonth,
          categoryId: categoryId,
          threshold: BudgetAlertThreshold.warning80,
        );
        _firedAlertKeys.add(key80);

        final notificationId = _generateNotificationId(
          'cat_100_${yearMonth}_$categoryId',
        );
        final title = 'Anggaran Terlampaui: $categoryName';
        final body =
            'Pengeluaran untuk $categoryName telah melebihi batas anggaran! Total: $spentFormatted dari $limitFormatted ($percentage%).';
        final payload = jsonEncode({
          'type': 'category',
          'threshold': 100,
          'categoryId': categoryId,
          'yearMonth': yearMonth,
        });

        await _notificationService.showBudgetExceeded(
          id: notificationId,
          title: title,
          body: body,
          payload: payload,
        );

        return BudgetAlertResult(
          scope: BudgetAlertScope.category,
          threshold: BudgetAlertThreshold.exceeded100,
          yearMonth: yearMonth,
          categoryId: categoryId,
          categoryName: categoryName,
          spent: status.spent,
          limit: status.limit,
          percentage: percentage,
          title: title,
          body: body,
          payload: payload,
          notificationId: notificationId,
        );
      }
    } else if (status.isNearLimit || percentage >= 80) {
      final key80 = getCategoryAlertKey(
        yearMonth: yearMonth,
        categoryId: categoryId,
        threshold: BudgetAlertThreshold.warning80,
      );

      if (!_firedAlertKeys.contains(key80)) {
        _firedAlertKeys.add(key80);

        final notificationId = _generateNotificationId(
          'cat_80_${yearMonth}_$categoryId',
        );
        final title = 'Peringatan Anggaran: $categoryName';
        final body =
            'Pengeluaran untuk $categoryName telah mencapai $percentage% ($spentFormatted dari $limitFormatted).';
        final payload = jsonEncode({
          'type': 'category',
          'threshold': 80,
          'categoryId': categoryId,
          'yearMonth': yearMonth,
        });

        await _notificationService.showBudgetWarning(
          id: notificationId,
          title: title,
          body: body,
          payload: payload,
        );

        return BudgetAlertResult(
          scope: BudgetAlertScope.category,
          threshold: BudgetAlertThreshold.warning80,
          yearMonth: yearMonth,
          categoryId: categoryId,
          categoryName: categoryName,
          spent: status.spent,
          limit: status.limit,
          percentage: percentage,
          title: title,
          body: body,
          payload: payload,
          notificationId: notificationId,
        );
      }
    }

    return null;
  }

  Future<BudgetAlertResult?> _checkMonthlyAlert({
    required String yearMonth,
  }) async {
    final status = await _budgetService.getMonthlyBudgetStatus(yearMonth);
    if (!status.hasBudget) {
      return null;
    }

    final percentage = status.percentage;
    final spentFormatted = CurrencyFormatter.format(status.totalSpent);
    final limitFormatted = CurrencyFormatter.format(status.totalLimit);

    if (status.isExceeded || percentage >= 100) {
      final key100 = getMonthlyAlertKey(
        yearMonth: yearMonth,
        threshold: BudgetAlertThreshold.exceeded100,
      );

      if (!_firedAlertKeys.contains(key100)) {
        _firedAlertKeys.add(key100);
        // Also suppress 80% warning once exceeded has fired
        final key80 = getMonthlyAlertKey(
          yearMonth: yearMonth,
          threshold: BudgetAlertThreshold.warning80,
        );
        _firedAlertKeys.add(key80);

        final notificationId = _generateNotificationId(
          'monthly_100_$yearMonth',
        );
        const title = 'Anggaran Bulanan Terlampaui!';
        final body =
            'Total pengeluaran bulan ini telah melebihi batas anggaran! Total: $spentFormatted dari $limitFormatted ($percentage%).';
        final payload = jsonEncode({
          'type': 'monthly',
          'threshold': 100,
          'yearMonth': yearMonth,
        });

        await _notificationService.showBudgetExceeded(
          id: notificationId,
          title: title,
          body: body,
          payload: payload,
        );

        return BudgetAlertResult(
          scope: BudgetAlertScope.monthly,
          threshold: BudgetAlertThreshold.exceeded100,
          yearMonth: yearMonth,
          spent: status.totalSpent,
          limit: status.totalLimit,
          percentage: percentage,
          title: title,
          body: body,
          payload: payload,
          notificationId: notificationId,
        );
      }
    } else if (status.isNearLimit || percentage >= 80) {
      final key80 = getMonthlyAlertKey(
        yearMonth: yearMonth,
        threshold: BudgetAlertThreshold.warning80,
      );

      if (!_firedAlertKeys.contains(key80)) {
        _firedAlertKeys.add(key80);

        final notificationId = _generateNotificationId(
          'monthly_80_$yearMonth',
        );
        const title = 'Peringatan Anggaran Bulanan';
        final body =
            'Total pengeluaran bulan ini telah mencapai $percentage% ($spentFormatted dari $limitFormatted).';
        final payload = jsonEncode({
          'type': 'monthly',
          'threshold': 80,
          'yearMonth': yearMonth,
        });

        await _notificationService.showBudgetWarning(
          id: notificationId,
          title: title,
          body: body,
          payload: payload,
        );

        return BudgetAlertResult(
          scope: BudgetAlertScope.monthly,
          threshold: BudgetAlertThreshold.warning80,
          yearMonth: yearMonth,
          spent: status.totalSpent,
          limit: status.totalLimit,
          percentage: percentage,
          title: title,
          body: body,
          payload: payload,
          notificationId: notificationId,
        );
      }
    }

    return null;
  }

  /// Generates a positive 31-bit integer notification ID suitable for Android.
  int _generateNotificationId(String key) {
    final hash = key.hashCode.abs() % 2147483647;
    return hash == 0 ? 1 : hash;
  }
}

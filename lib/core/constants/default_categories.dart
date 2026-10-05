import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../database/converters/transaction_type.dart';

/// Predefined default categories for the Budget Tracker app.
abstract final class DefaultCategories {
  // Expense category IDs
  static const String foodId = 'c1000001-0000-4000-8000-000000000001';
  static const String transportId = 'c1000002-0000-4000-8000-000000000002';
  static const String billsId = 'c1000003-0000-4000-8000-000000000003';
  static const String shoppingId = 'c1000004-0000-4000-8000-000000000004';
  static const String healthId = 'c1000005-0000-4000-8000-000000000005';
  static const String entertainmentId = 'c1000006-0000-4000-8000-000000000006';
  static const String otherId = 'c1000007-0000-4000-8000-000000000007';

  // Income category IDs
  static const String salaryId = 'c1000008-0000-4000-8000-000000000008';
  static const String investmentId = 'c1000009-0000-4000-8000-000000000009';
  static const String allowanceId = 'c1000010-0000-4000-8000-000000000010';
  static const String freelanceId = 'c1000011-0000-4000-8000-000000000011';
  static const String otherIncomeId = 'c1000012-0000-4000-8000-000000000012';

  // Expense category names
  static const String foodName = 'Food';
  static const String transportName = 'Transport';
  static const String billsName = 'Bills';
  static const String shoppingName = 'Shopping';
  static const String healthName = 'Health';
  static const String entertainmentName = 'Entertainment';
  static const String otherName = 'Other';

  // Income category names
  static const String salaryName = 'Salary';
  static const String investmentName = 'Investment';
  static const String allowanceName = 'Bonus & Allowance';
  static const String freelanceName = 'Side Job';
  static const String otherIncomeName = 'Other Income';

  /// Standard list of default expense category names.
  static const List<String> expenseNames = [
    foodName,
    transportName,
    billsName,
    shoppingName,
    healthName,
    entertainmentName,
    otherName,
  ];

  /// Standard list of default income category names.
  static const List<String> incomeNames = [
    salaryName,
    investmentName,
    allowanceName,
    freelanceName,
    otherIncomeName,
  ];

  /// Combined list of all default category names.
  static const List<String> allNames = [
    ...expenseNames,
    ...incomeNames,
  ];

  /// Helper to convert a stored icon codePoint string or named identifier back to [IconData].
  static IconData getIconData(
    String codePointStr, {
    IconData fallback = Icons.category,
  }) {
    final codePoint = int.tryParse(codePointStr);
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }
    return switch (codePointStr) {
      'restaurant' => Icons.restaurant,
      'directions_car' => Icons.directions_car,
      'receipt' || 'receipt_long' => Icons.receipt_long,
      'shopping_cart' || 'shopping_bag' => Icons.shopping_bag,
      'medical_services' || 'health_and_safety' => Icons.medical_services,
      'movie' || 'theater_comedy' => Icons.movie,
      'more_horiz' || 'category' => Icons.category,
      'attach_money' || 'payments' => Icons.payments,
      'trending_up' => Icons.trending_up,
      'card_giftcard' || 'redeem' => Icons.card_giftcard,
      'work' => Icons.work,
      'savings' || 'account_balance_wallet' => Icons.savings,
      _ => fallback,
    };
  }

  /// Generates the default category companions to seed into Drift DB.
  /// If [type] is specified, returns only companions for that type.
  static List<CategoriesCompanion> getCompanions({
    DateTime? createdAt,
    TransactionType? type,
  }) {
    final now = createdAt ?? DateTime.now().toUtc();

    final expenseCompanions = [
      CategoriesCompanion(
        id: const Value(foodId),
        name: const Value(foodName),
        icon: Value(Icons.restaurant.codePoint.toString()),
        color: const Value(0xFF43A047), // Green
        type: const Value(TransactionType.expense),
        isDefault: const Value(true),
        isActive: const Value(true),
        sortOrder: const Value(0),
        createdAt: Value(now),
      ),
      CategoriesCompanion(
        id: const Value(transportId),
        name: const Value(transportName),
        icon: Value(Icons.directions_car.codePoint.toString()),
        color: const Value(0xFF1E88E5), // Blue
        type: const Value(TransactionType.expense),
        isDefault: const Value(true),
        isActive: const Value(true),
        sortOrder: const Value(1),
        createdAt: Value(now),
      ),
      CategoriesCompanion(
        id: const Value(billsId),
        name: const Value(billsName),
        icon: Value(Icons.receipt_long.codePoint.toString()),
        color: const Value(0xFFE53935), // Red
        type: const Value(TransactionType.expense),
        isDefault: const Value(true),
        isActive: const Value(true),
        sortOrder: const Value(2),
        createdAt: Value(now),
      ),
      CategoriesCompanion(
        id: const Value(shoppingId),
        name: const Value(shoppingName),
        icon: Value(Icons.shopping_bag.codePoint.toString()),
        color: const Value(0xFFFB8C00), // Orange
        type: const Value(TransactionType.expense),
        isDefault: const Value(true),
        isActive: const Value(true),
        sortOrder: const Value(3),
        createdAt: Value(now),
      ),
      CategoriesCompanion(
        id: const Value(healthId),
        name: const Value(healthName),
        icon: Value(Icons.medical_services.codePoint.toString()),
        color: const Value(0xFF00897B), // Teal
        type: const Value(TransactionType.expense),
        isDefault: const Value(true),
        isActive: const Value(true),
        sortOrder: const Value(4),
        createdAt: Value(now),
      ),
      CategoriesCompanion(
        id: const Value(entertainmentId),
        name: const Value(entertainmentName),
        icon: Value(Icons.movie.codePoint.toString()),
        color: const Value(0xFF8E24AA), // Purple
        type: const Value(TransactionType.expense),
        isDefault: const Value(true),
        isActive: const Value(true),
        sortOrder: const Value(5),
        createdAt: Value(now),
      ),
      CategoriesCompanion(
        id: const Value(otherId),
        name: const Value(otherName),
        icon: Value(Icons.more_horiz.codePoint.toString()),
        color: const Value(0xFF546E7A), // Blue Grey
        type: const Value(TransactionType.expense),
        isDefault: const Value(true),
        isActive: const Value(true),
        sortOrder: const Value(6),
        createdAt: Value(now),
      ),
    ];

    final incomeCompanions = [
      CategoriesCompanion(
        id: const Value(salaryId),
        name: const Value(salaryName),
        icon: Value(Icons.payments.codePoint.toString()),
        color: const Value(0xFF2E7D32), // Dark Green
        type: const Value(TransactionType.income),
        isDefault: const Value(true),
        isActive: const Value(true),
        sortOrder: const Value(0),
        createdAt: Value(now),
      ),
      CategoriesCompanion(
        id: const Value(investmentId),
        name: const Value(investmentName),
        icon: Value(Icons.trending_up.codePoint.toString()),
        color: const Value(0xFF00897B), // Teal
        type: const Value(TransactionType.income),
        isDefault: const Value(true),
        isActive: const Value(true),
        sortOrder: const Value(1),
        createdAt: Value(now),
      ),
      CategoriesCompanion(
        id: const Value(allowanceId),
        name: const Value(allowanceName),
        icon: Value(Icons.card_giftcard.codePoint.toString()),
        color: const Value(0xFF1E88E5), // Blue
        type: const Value(TransactionType.income),
        isDefault: const Value(true),
        isActive: const Value(true),
        sortOrder: const Value(2),
        createdAt: Value(now),
      ),
      CategoriesCompanion(
        id: const Value(freelanceId),
        name: const Value(freelanceName),
        icon: Value(Icons.work.codePoint.toString()),
        color: const Value(0xFFFB8C00), // Orange
        type: const Value(TransactionType.income),
        isDefault: const Value(true),
        isActive: const Value(true),
        sortOrder: const Value(3),
        createdAt: Value(now),
      ),
      CategoriesCompanion(
        id: const Value(otherIncomeId),
        name: const Value(otherIncomeName),
        icon: Value(Icons.savings.codePoint.toString()),
        color: const Value(0xFF5E35B1), // Deep Purple
        type: const Value(TransactionType.income),
        isDefault: const Value(true),
        isActive: const Value(true),
        sortOrder: const Value(4),
        createdAt: Value(now),
      ),
    ];

    if (type == TransactionType.expense) return expenseCompanions;
    if (type == TransactionType.income) return incomeCompanions;
    return [...expenseCompanions, ...incomeCompanions];
  }
}

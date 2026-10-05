import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../database/app_database.dart';

/// Predefined default categories for the Budget Tracker app.
abstract final class DefaultCategories {
  static const String foodId = 'c1000001-0000-4000-8000-000000000001';
  static const String transportId = 'c1000002-0000-4000-8000-000000000002';
  static const String billsId = 'c1000003-0000-4000-8000-000000000003';
  static const String shoppingId = 'c1000004-0000-4000-8000-000000000004';
  static const String healthId = 'c1000005-0000-4000-8000-000000000005';
  static const String entertainmentId = 'c1000006-0000-4000-8000-000000000006';
  static const String otherId = 'c1000007-0000-4000-8000-000000000007';

  static const String foodName = 'Food';
  static const String transportName = 'Transport';
  static const String billsName = 'Bills';
  static const String shoppingName = 'Shopping';
  static const String healthName = 'Health';
  static const String entertainmentName = 'Entertainment';
  static const String otherName = 'Other';

  /// Standard list of default category names.
  static const List<String> allNames = [
    foodName,
    transportName,
    billsName,
    shoppingName,
    healthName,
    entertainmentName,
    otherName,
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
      'work' => Icons.work,
      _ => fallback,
    };
  }

  /// Generates the 7 default category companions to seed into Drift DB.
  static List<CategoriesCompanion> getCompanions({DateTime? createdAt}) {
    final now = createdAt ?? DateTime.now().toUtc();

    return [
      CategoriesCompanion(
        id: const Value(foodId),
        name: const Value(foodName),
        icon: Value(Icons.restaurant.codePoint.toString()),
        color: const Value(0xFF43A047), // Green
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
        isDefault: const Value(true),
        isActive: const Value(true),
        sortOrder: const Value(6),
        createdAt: Value(now),
      ),
    ];
  }
}

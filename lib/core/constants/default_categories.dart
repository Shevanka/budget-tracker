import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../database/app_database.dart';

/// Predefined default categories for the Budget Tracker app.
abstract final class DefaultCategories {
  static const String foodId = 'default_cat_food';
  static const String transportId = 'default_cat_transport';
  static const String billsId = 'default_cat_bills';
  static const String shoppingId = 'default_cat_shopping';
  static const String healthId = 'default_cat_health';
  static const String entertainmentId = 'default_cat_entertainment';
  static const String otherId = 'default_cat_other';

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

  /// Helper to convert a stored icon codePoint string back to [IconData].
  static IconData getIconData(
    String codePointStr, {
    IconData fallback = Icons.category,
  }) {
    final codePoint = int.tryParse(codePointStr);
    if (codePoint == null) {
      return fallback;
    }
    return IconData(codePoint, fontFamily: 'MaterialIcons');
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

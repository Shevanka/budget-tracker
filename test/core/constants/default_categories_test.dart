import 'package:budget_tracker/core/constants/default_categories.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultCategories definitions', () {
    test('contains exactly 7 standard default categories', () {
      final companions = DefaultCategories.getCompanions();
      expect(companions.length, 7);

      final names = companions.map((c) => c.name.value).toList();
      expect(
        names,
        equals([
          'Food',
          'Transport',
          'Bills',
          'Shopping',
          'Health',
          'Entertainment',
          'Other',
        ]),
      );
    });

    test('all companions have valid fields, isDefault=true, and unique sortOrder', () {
      final companions = DefaultCategories.getCompanions();
      final ids = <String>{};
      final sortOrders = <int>{};

      for (int i = 0; i < companions.length; i++) {
        final c = companions[i];
        expect(c.id.present, isTrue);
        expect(c.isDefault.value, isTrue);
        expect(c.isActive.value, isTrue);
        expect(c.sortOrder.value, equals(i));

        ids.add(c.id.value);
        sortOrders.add(c.sortOrder.value);
      }

      expect(ids.length, 7);
      expect(sortOrders.length, 7);
    });

    test('getIconData converts codePoint string to IconData and falls back', () {
      final icon = DefaultCategories.getIconData(
        Icons.restaurant.codePoint.toString(),
      );
      expect(icon.codePoint, Icons.restaurant.codePoint);

      final fallback = DefaultCategories.getIconData('invalid-code');
      expect(fallback.codePoint, Icons.category.codePoint);
    });
  });

  group('DefaultCategories Database Seeding', () {
    test('AppDatabase with seedDefaults=true seeds 7 categories on creation', () async {
      final db = AppDatabase.inMemory(seedDefaults: true);

      final categories = await db.categoryDao.getActiveCategories();
      expect(categories.length, 7);

      final names = categories.map((c) => c.name).toList();
      expect(names, containsAll(DefaultCategories.allNames));

      for (final cat in categories) {
        expect(cat.isDefault, isTrue);
        expect(cat.isActive, isTrue);
      }

      await db.close();
    });

    test('seeding is idempotent (duplicate insertOrIgnore does not fail or duplicate)', () async {
      final db = AppDatabase.inMemory(seedDefaults: true);

      expect(await db.categoryDao.countActiveCategories(), 7);

      // Attempt to seed again
      await db.categoryDao.seedCategories(DefaultCategories.getCompanions());
      expect(await db.categoryDao.countActiveCategories(), 7);

      await db.close();
    });

    test('seedDefaultCategoriesIfEmpty seeds only when table is empty', () async {
      final db = AppDatabase.inMemory(seedDefaults: false);

      expect(await db.categoryDao.countTotalCategories(), 0);

      await db.categoryDao.seedDefaultCategoriesIfEmpty(
        defaultEntries: DefaultCategories.getCompanions(),
      );
      expect(await db.categoryDao.countTotalCategories(), 7);

      // Calling again when not empty does not add duplicates
      await db.categoryDao.seedDefaultCategoriesIfEmpty(
        defaultEntries: DefaultCategories.getCompanions(),
      );
      expect(await db.categoryDao.countTotalCategories(), 7);

      await db.close();
    });
  });
}

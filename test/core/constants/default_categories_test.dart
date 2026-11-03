import 'package:budget_tracker/core/constants/default_categories.dart';
import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultCategories definitions', () {
    test('contains exactly 12 default categories (7 expense and 5 income)', () {
      final companions = DefaultCategories.getCompanions();
      expect(companions.length, 12);

      final names = companions.map((c) => c.name.value).toList();
      expect(names, equals(DefaultCategories.allNames));

      final expenseCompanions = DefaultCategories.getCompanions(type: TransactionType.expense);
      expect(expenseCompanions.length, 7);
      expect(
        expenseCompanions.map((c) => c.name.value).toList(),
        equals(DefaultCategories.expenseNames),
      );

      final incomeCompanions = DefaultCategories.getCompanions(type: TransactionType.income);
      expect(incomeCompanions.length, 5);
      expect(
        incomeCompanions.map((c) => c.name.value).toList(),
        equals(DefaultCategories.incomeNames),
      );
    });

    test('all companions have valid fields, isDefault=true, and unique IDs', () {
      final companions = DefaultCategories.getCompanions();
      final ids = <String>{};

      final uuidV4Regex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      for (int i = 0; i < companions.length; i++) {
        final c = companions[i];
        expect(c.id.present, isTrue);
        expect(uuidV4Regex.hasMatch(c.id.value), isTrue);
        expect(c.isDefault.value, isTrue);
        expect(c.isActive.value, isTrue);
        expect(c.type.present, isTrue);

        ids.add(c.id.value);
      }

      expect(ids.length, 12);
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
    test('AppDatabase with seedDefaults=true seeds 12 categories on creation', () async {
      final db = AppDatabase.inMemory(seedDefaults: true);

      final categories = await db.categoryDao.getActiveCategories();
      expect(categories.length, 12);

      final names = categories.map((c) => c.name).toList();
      expect(names, containsAll(DefaultCategories.allNames));

      final expenseCats = await db.categoryDao.getActiveCategories(type: TransactionType.expense);
      expect(expenseCats.length, 7);

      final incomeCats = await db.categoryDao.getActiveCategories(type: TransactionType.income);
      expect(incomeCats.length, 5);

      for (final cat in categories) {
        expect(cat.isDefault, isTrue);
        expect(cat.isActive, isTrue);
      }

      await db.close();
    });

    test('seeding is idempotent (duplicate insertOrIgnore does not fail or duplicate)', () async {
      final db = AppDatabase.inMemory(seedDefaults: true);

      expect(await db.categoryDao.countActiveCategories(), 12);

      // Attempt to seed again
      await db.categoryDao.seedCategories(DefaultCategories.getCompanions());
      expect(await db.categoryDao.countActiveCategories(), 12);

      await db.close();
    });

    test('seedDefaultCategoriesIfEmpty seeds only when table is empty', () async {
      final db = AppDatabase.inMemory(seedDefaults: false);

      expect(await db.categoryDao.countTotalCategories(), 0);

      await db.categoryDao.seedDefaultCategoriesIfEmpty(
        defaultEntries: DefaultCategories.getCompanions(),
      );
      expect(await db.categoryDao.countTotalCategories(), 12);

      // Calling again when not empty does not add duplicates
      await db.categoryDao.seedDefaultCategoriesIfEmpty(
        defaultEntries: DefaultCategories.getCompanions(),
      );
      expect(await db.categoryDao.countTotalCategories(), 12);

      await db.close();
    });
  });
}

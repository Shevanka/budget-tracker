import 'package:budget_tracker/database/app_database.dart';
import 'package:budget_tracker/database/converters/transaction_type.dart';
import 'package:budget_tracker/database/database_provider.dart';
import 'package:budget_tracker/features/categories/providers/categories_provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = AppDatabase.inMemory();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('CategoryController', () {
    test('createCategory inserts new category with generated UUID v4 and UTC date', () async {
      final controller = container.read(categoryControllerProvider.notifier);

      final created = await controller.createCategory(
        name: 'Gym & Fitness',
        icon: 'fitness_center',
        color: 0xFF00897B,
        type: TransactionType.expense,
      );

      expect(created, isNotNull);
      expect(created!.name, 'Gym & Fitness');
      expect(created.icon, 'fitness_center');
      expect(created.color, 0xFF00897B);
      expect(created.type, TransactionType.expense);
      expect(created.isActive, isTrue);
      expect(created.isDefault, isFalse);
      expect(created.sortOrder, 0);

      // Verify UUID v4
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(created.id), isTrue);

      final inDb = await db.categoryDao.getCategoryById(created.id);
      expect(inDb, isNotNull);
      expect(inDb!.name, 'Gym & Fitness');
    });

    test('createCategory increments sortOrder for subsequent categories of same type', () async {
      final controller = container.read(categoryControllerProvider.notifier);

      final cat1 = await controller.createCategory(
        name: 'First',
        icon: 'restaurant',
        color: 0xFF43A047,
        type: TransactionType.expense,
      );
      final cat2 = await controller.createCategory(
        name: 'Second',
        icon: 'directions_car',
        color: 0xFF1E88E5,
        type: TransactionType.expense,
      );

      expect(cat1!.sortOrder, 0);
      expect(cat2!.sortOrder, 1);
    });

    test('updateCategory modifies existing category properties while preserving metadata', () async {
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: const drift.Value('cat-edit'),
          name: const drift.Value('Old Food'),
          icon: const drift.Value('restaurant'),
          color: const drift.Value(0xFF43A047),
          type: const drift.Value(TransactionType.expense),
          isDefault: const drift.Value(true),
          isActive: const drift.Value(true),
          sortOrder: const drift.Value(3),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      );

      final controller = container.read(categoryControllerProvider.notifier);
      final success = await controller.updateCategory(
        id: 'cat-edit',
        name: 'Dining & Drinks',
        icon: 'local_cafe',
        color: 0xFFE53935,
        type: TransactionType.expense,
      );

      expect(success, isTrue);

      final updated = await db.categoryDao.getCategoryById('cat-edit');
      expect(updated, isNotNull);
      expect(updated!.name, 'Dining & Drinks');
      expect(updated.icon, 'local_cafe');
      expect(updated.color, 0xFFE53935);
      expect(updated.isDefault, isTrue); // Preserved
      expect(updated.sortOrder, 3); // Preserved
      expect(updated.createdAt, DateTime.utc(2026, 10, 1)); // Preserved
    });

    test('softDeleteCategory marks category as inactive', () async {
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: const drift.Value('cat-delete'),
          name: const drift.Value('To Delete'),
          icon: const drift.Value('restaurant'),
          color: const drift.Value(0xFF43A047),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      );

      final controller = container.read(categoryControllerProvider.notifier);
      await controller.softDeleteCategory('cat-delete');

      final category = await db.categoryDao.getCategoryById('cat-delete');
      expect(category, isNotNull);
      expect(category!.isActive, isFalse);
    });

    test('restoreCategory restores inactive category', () async {
      await db.categoryDao.insertCategory(
        CategoriesCompanion(
          id: const drift.Value('cat-inactive'),
          name: const drift.Value('Inactive Category'),
          icon: const drift.Value('restaurant'),
          color: const drift.Value(0xFF43A047),
          isActive: const drift.Value(false),
          createdAt: drift.Value(DateTime.utc(2026, 10, 1)),
        ),
      );

      final controller = container.read(categoryControllerProvider.notifier);
      await controller.restoreCategory('cat-inactive');

      final category = await db.categoryDao.getCategoryById('cat-inactive');
      expect(category, isNotNull);
      expect(category!.isActive, isTrue);
    });
  });
}

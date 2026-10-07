import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/id_generator.dart';
import '../../../database/app_database.dart';
import '../../../database/converters/transaction_type.dart';
import '../../../database/database_provider.dart';

/// Reactive stream of all active categories ordered by sortOrder and name.
final activeCategoriesProvider =
    StreamProvider.autoDispose<List<Category>>((ref) {
  final dao = ref.watch(categoryDaoProvider);
  return dao.watchActiveCategories();
});

/// Reactive stream of active categories filtered by [TransactionType].
final activeCategoriesByTypeProvider =
    StreamProvider.autoDispose.family<List<Category>, TransactionType>((ref, type) {
  final dao = ref.watch(categoryDaoProvider);
  return dao.watchActiveCategories(type: type);
});

/// Filter parameters for streaming categories.
typedef CategoryFilter = ({TransactionType? type, bool includeInactive});

/// Reactive stream of categories filtered by [TransactionType] and active status.
final categoriesByFilterProvider =
    StreamProvider.autoDispose.family<List<Category>, CategoryFilter>((ref, filter) {
  final dao = ref.watch(categoryDaoProvider);
  return dao.watchCategories(
    type: filter.type,
    includeInactive: filter.includeInactive,
  );
});

/// Map of active categories by category ID for quick lookup.
final activeCategoriesMapProvider =
    Provider.autoDispose<AsyncValue<Map<String, Category>>>((ref) {
  final categoriesAsync = ref.watch(activeCategoriesProvider);
  return categoriesAsync.whenData((categories) {
    return {for (final cat in categories) cat.id: cat};
  });
});

/// Fetches a single category by its ID.
final categoryByIdProvider =
    FutureProvider.autoDispose.family<Category?, String>((ref, id) {
  final dao = ref.watch(categoryDaoProvider);
  return dao.getCategoryById(id);
});

/// Controller handling category mutations (create, update, soft delete, restore).
class CategoryController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Creates a new category with a generated UUID v4 and UTC timestamp.
  Future<Category?> createCategory({
    required String name,
    required String icon,
    required int color,
    required TransactionType type,
  }) async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(categoryDaoProvider);
      final id = IdGenerator.generate();
      final now = DateTime.now().toUtc();
      final existingCategories = await dao.getActiveCategories(type: type);
      final nextSortOrder = existingCategories.isEmpty
          ? 0
          : existingCategories.map((c) => c.sortOrder).reduce(max) + 1;

      final entry = CategoriesCompanion(
        id: Value(id),
        name: Value(name.trim()),
        icon: Value(icon),
        color: Value(color),
        type: Value(type),
        isDefault: const Value(false),
        isActive: const Value(true),
        sortOrder: Value(nextSortOrder),
        createdAt: Value(now),
      );

      await dao.insertCategory(entry);
      state = const AsyncValue.data(null);
      return dao.getCategoryById(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Updates an existing category while preserving `createdAt`, `isDefault`, and `sortOrder`.
  Future<bool> updateCategory({
    required String id,
    required String name,
    required String icon,
    required int color,
    required TransactionType type,
  }) async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(categoryDaoProvider);
      final existing = await dao.getCategoryById(id);
      if (existing == null) {
        throw StateError('Category with id $id not found');
      }

      final entry = CategoriesCompanion(
        id: Value(id),
        name: Value(name.trim()),
        icon: Value(icon),
        color: Value(color),
        type: Value(type),
        isDefault: Value(existing.isDefault),
        isActive: Value(existing.isActive),
        sortOrder: Value(existing.sortOrder),
        createdAt: Value(existing.createdAt),
      );

      final success = await dao.updateCategory(entry);
      state = const AsyncValue.data(null);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Soft deletes a category by marking `isActive = false`.
  Future<void> softDeleteCategory(String id) async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(categoryDaoProvider);
      await dao.softDeleteCategory(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Restores a soft-deleted category by marking `isActive = true`.
  Future<void> restoreCategory(String id) async {
    state = const AsyncValue.loading();
    try {
      final dao = ref.read(categoryDaoProvider);
      await dao.restoreCategory(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Provider exposing [CategoryController] for mutations.
final categoryControllerProvider =
    AutoDisposeAsyncNotifierProvider<CategoryController, void>(
  CategoryController.new,
);

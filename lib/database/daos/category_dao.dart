import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// Streams active categories sorted by sortOrder asc, then name asc.
  Stream<List<Category>> watchActiveCategories() {
    return (select(categories)
          ..where((tbl) => tbl.isActive.equals(true))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// Fetches active categories sorted by sortOrder asc, then name asc.
  Future<List<Category>> getActiveCategories() {
    return (select(categories)
          ..where((tbl) => tbl.isActive.equals(true))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Fetches all categories including soft-deleted ones.
  Future<List<Category>> getAllCategories() {
    return (select(categories)
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Fetches a category by its UUID.
  Future<Category?> getCategoryById(String id) {
    return (select(categories)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Normalizes DateTime fields in [entry] to UTC.
  CategoriesCompanion _normalizeUtc(CategoriesCompanion entry) {
    return entry.copyWith(
      createdAt: entry.createdAt.present
          ? Value(entry.createdAt.value.toUtc())
          : const Value.absent(),
    );
  }

  /// Inserts a new category with UTC-normalized createdAt.
  Future<int> insertCategory(CategoriesCompanion entry) {
    return into(categories).insert(_normalizeUtc(entry));
  }

  /// Updates an existing category with UTC-normalized createdAt.
  Future<bool> updateCategory(CategoriesCompanion entry) {
    return update(categories).replace(_normalizeUtc(entry));
  }

  /// Soft deletes a category by setting `isActive = false` to preserve FK references.
  Future<int> softDeleteCategory(String id) {
    return (update(categories)..where((tbl) => tbl.id.equals(id))).write(
      const CategoriesCompanion(
        isActive: Value(false),
      ),
    );
  }

  /// Counts the active categories.
  Future<int> countActiveCategories() async {
    final countExp = categories.id.count();
    final query = selectOnly(categories)
      ..where(categories.isActive.equals(true))
      ..addColumns([countExp]);
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  /// Seeds default categories in batch with UTC-normalized timestamps.
  Future<void> seedCategories(List<CategoriesCompanion> entries) async {
    final normalized = entries.map(_normalizeUtc).toList();
    await batch((batch) {
      batch.insertAll(categories, normalized, mode: InsertMode.insertOrIgnore);
    });
  }

  /// Counts total categories (including soft-deleted).
  Future<int> countTotalCategories() async {
    final countExp = categories.id.count();
    final query = selectOnly(categories)..addColumns([countExp]);
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  /// Seeds default categories if no categories exist in the database.
  Future<void> seedDefaultCategoriesIfEmpty({
    List<CategoriesCompanion>? defaultEntries,
  }) async {
    final total = await countTotalCategories();
    if (total == 0 && defaultEntries != null && defaultEntries.isNotEmpty) {
      await seedCategories(defaultEntries);
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../database/database_provider.dart';

/// Reactive stream of active categories ordered by sortOrder and name.
final activeCategoriesProvider =
    StreamProvider.autoDispose<List<Category>>((ref) {
  final dao = ref.watch(categoryDaoProvider);
  return dao.watchActiveCategories();
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

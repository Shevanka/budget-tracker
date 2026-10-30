import 'package:budget_tracker/core/constants/default_categories.dart';
import 'package:budget_tracker/features/notification_watcher/services/category_suggester.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategorySuggester', () {
    test('suggests Food category for food, dining, and cafe keywords', () {
      final samples = [
        'KOPI KENANGAN',
        'WARUNG KOPI',
        'KOPI JANJI JIWA',
        'BAKSO RUSUK',
        'POINT COFFEE',
        'Kopi Tuku',
        'Gofood - Ayam Geprek Bensu',
        'Chatime',
        'Restoran Padang Sederhana',
        'McDonalds Sarinah',
        'KFC Kemang',
        'Warung Makan Ibu Siti',
      ];

      for (final sample in samples) {
        final suggestion = CategorySuggester.suggest(sample);
        expect(suggestion, isNotNull, reason: 'Failed for $sample');
        expect(suggestion!.categoryId, equals(DefaultCategories.foodId));
        expect(suggestion.categoryName, equals(DefaultCategories.foodName));
      }
    });

    test('suggests Transport category for transit and fuel keywords', () {
      final samples = [
        'Grab Rides',
        'Gojek Transport',
        'SPBU Pertamina Pasti Pas',
        'Shell Gatot Subroto',
        'Gerbang Tol Pasteur',
        'Parkir Mall Kelapa Gading',
        'Bluebird Taxi',
        'Tiket KAI Gambir',
      ];

      for (final sample in samples) {
        final suggestion = CategorySuggester.suggest(sample);
        expect(suggestion, isNotNull, reason: 'Failed for $sample');
        expect(suggestion!.categoryId, equals(DefaultCategories.transportId));
        expect(suggestion.categoryName, equals(DefaultCategories.transportName));
      }
    });

    test('suggests Bills category for utilities and recurring services', () {
      final samples = [
        'PLN Prabayar',
        'Tagihan Listrik Pascabayar',
        'PDAM Tirtawening',
        'Indihome Internet',
        'BPJS Kesehatan',
        'Pulsa Telkomsel',
      ];

      for (final sample in samples) {
        final suggestion = CategorySuggester.suggest(sample);
        expect(suggestion, isNotNull, reason: 'Failed for $sample');
        expect(suggestion!.categoryId, equals(DefaultCategories.billsId));
        expect(suggestion.categoryName, equals(DefaultCategories.billsName));
      }
    });

    test('suggests Shopping category for retail and ecommerce stores', () {
      final samples = [
        'INDOMARET',
        'ALFAMART',
        'Alfamidi Point',
        'Tokopedia Official Store',
        'Shopee Mall',
        'Superindo Dago',
        'Watsons Grand Indonesia',
      ];

      for (final sample in samples) {
        final suggestion = CategorySuggester.suggest(sample);
        expect(suggestion, isNotNull, reason: 'Failed for $sample');
        expect(suggestion!.categoryId, equals(DefaultCategories.shoppingId));
        expect(suggestion.categoryName, equals(DefaultCategories.shoppingName));
      }
    });

    test('suggests Health category for medical and pharmacy keywords', () {
      final samples = [
        'Apotek Kimia Farma',
        'Apotek K24',
        'Halodoc Konsultasi',
        'Klinik Prodia',
        'RS Pondok Indah',
      ];

      for (final sample in samples) {
        final suggestion = CategorySuggester.suggest(sample);
        expect(suggestion, isNotNull, reason: 'Failed for $sample');
        expect(suggestion!.categoryId, equals(DefaultCategories.healthId));
        expect(suggestion.categoryName, equals(DefaultCategories.healthName));
      }
    });

    test('suggests Entertainment category for movies and gaming', () {
      final samples = [
        'Cinema XXI',
        'CGV Cinemas',
        'Netflix Subscription',
        'Spotify Premium',
        'Steam Games',
      ];

      for (final sample in samples) {
        final suggestion = CategorySuggester.suggest(sample);
        expect(suggestion, isNotNull, reason: 'Failed for $sample');
        expect(suggestion!.categoryId, equals(DefaultCategories.entertainmentId));
        expect(suggestion.categoryName, equals(DefaultCategories.entertainmentName));
      }
    });

    test('returns null for unclassified merchant names', () {
      expect(CategorySuggester.suggest('ANGGIE WAHYU'), isNull);
      expect(CategorySuggester.suggest('Transfer ke Bpk Budi'), isNull);
      expect(CategorySuggester.suggest(null), isNull);
      expect(CategorySuggester.suggest('   '), isNull);
    });

    test('suggestCategoryId and suggestCategoryName fallback to Other category', () {
      expect(
        CategorySuggester.suggestCategoryId('ANGGIE WAHYU'),
        equals(DefaultCategories.otherId),
      );
      expect(
        CategorySuggester.suggestCategoryName('ANGGIE WAHYU'),
        equals(DefaultCategories.otherName),
      );
      expect(
        CategorySuggester.suggestCategoryId(null),
        equals(DefaultCategories.otherId),
      );
      expect(
        CategorySuggester.suggestCategoryName(null),
        equals(DefaultCategories.otherName),
      );
    });

    test('CategorySuggestion equality and toString', () {
      const s1 = CategorySuggestion(
        categoryId: DefaultCategories.foodId,
        categoryName: 'Food',
        matchedKeyword: 'kopi',
      );
      const s2 = CategorySuggestion(
        categoryId: DefaultCategories.foodId,
        categoryName: 'Food',
        matchedKeyword: 'kopi',
      );
      const s3 = CategorySuggestion(
        categoryId: DefaultCategories.foodId,
        categoryName: 'Food',
        matchedKeyword: 'resto',
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
      expect(s1.toString(), contains('Food'));
      expect(s1.toString(), contains('kopi'));
    });
  });
}

import 'package:budget_tracker/core/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IdGenerator', () {
    test('generate returns a non-empty string', () {
      final id = IdGenerator.generate();
      expect(id, isNotEmpty);
    });

    test('generate returns a valid RFC 4122 v4 UUID format', () {
      final uuidV4Regex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      for (int i = 0; i < 20; i++) {
        final id = IdGenerator.generate();
        expect(
          uuidV4Regex.hasMatch(id),
          isTrue,
          reason: '$id does not match UUID v4 format',
        );
      }
    });

    test('generate produces unique IDs across multiple invocations', () {
      const count = 1000;
      final generatedIds = <String>{};

      for (int i = 0; i < count; i++) {
        final id = IdGenerator.generate();
        expect(generatedIds.contains(id), isFalse, reason: 'Duplicate ID generated');
        generatedIds.add(id);
      }

      expect(generatedIds.length, count);
    });
  });
}

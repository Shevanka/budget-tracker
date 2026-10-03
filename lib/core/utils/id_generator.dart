import 'package:uuid/uuid.dart';

/// Utility for generating unique IDs (RFC 4122 UUID v4) for database records and domain entities.
abstract final class IdGenerator {
  static const Uuid _uuid = Uuid();

  /// Generates a random RFC 4122 version 4 UUID string.
  static String generate() => _uuid.v4();
}

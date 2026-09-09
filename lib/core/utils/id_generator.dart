import 'package:uuid/uuid.dart';

/// Helper utility for generating unique identifiers.
abstract final class IdGenerator {
  static const Uuid _uuid = Uuid();

  /// Generates a time-ordered UUIDv7 string.
  static String generateUuidV7() => _uuid.v7();
}

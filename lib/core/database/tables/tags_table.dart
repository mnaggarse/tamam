import 'package:drift/drift.dart';

/// Database table definition for Tags.
@DataClassName('TagEntry')
class Tags extends Table {
  /// Unique identifier (UUIDv7).
  TextColumn get id => text()();

  /// User-defined tag name.
  TextColumn get name => text()();

  /// Optional 32-bit ARGB color value.
  IntColumn get color => integer().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Last modification timestamp for sync.
  DateTimeColumn get updatedAt => dateTime()();

  /// Soft-delete timestamp for sync.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

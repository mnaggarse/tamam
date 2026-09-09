import 'package:drift/drift.dart';

/// Database table definition for Projects.
@DataClassName('ProjectEntry')
class Projects extends Table {
  /// Unique identifier (UUIDv7).
  TextColumn get id => text()();

  /// User-defined project name.
  TextColumn get name => text()();

  /// 32-bit ARGB color value.
  IntColumn get color => integer()();

  /// Optional icon name or identifier.
  TextColumn get icon => text().nullable()();

  /// Sorting order within the project list.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Last modification timestamp for sync.
  DateTimeColumn get updatedAt => dateTime()();

  /// Soft-delete timestamp for sync.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

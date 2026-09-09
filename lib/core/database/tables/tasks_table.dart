import 'package:drift/drift.dart';
import 'package:tamam/core/database/tables/projects_table.dart';

/// Database table definition for Tasks.
@DataClassName('TaskEntry')
class Tasks extends Table {
  /// Unique identifier (UUIDv7).
  TextColumn get id => text()();

  /// Associated project ID, or null for "Inbox".
  TextColumn get projectId =>
      text().nullable().references(Projects, #id)();

  /// Task title.
  TextColumn get title => text()();

  /// Detailed notes or description.
  TextColumn get notes => text().nullable()();

  /// Scheduled due date.
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// Scheduled due time (separate for timed tasks).
  DateTimeColumn get dueTime => dateTime().nullable()();

  /// Priority level (0: None, 1: Low, 2: Medium, 3: High).
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// Whether the task is completed.
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Timestamp when the task was marked completed.
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Recurrence rule identifier (for Phase 8).
  TextColumn get recurrenceRuleId => text().nullable()();

  /// Sorting order index within its list.
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

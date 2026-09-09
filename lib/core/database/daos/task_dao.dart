import 'package:drift/drift.dart';
import 'package:tamam/core/database/database.dart';
import 'package:tamam/core/database/tables/tasks_table.dart';

part 'task_dao.g.dart';

/// Data access object for the [Tasks] table.
@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  /// Creates a [TaskDao] accessor.
  TaskDao(super.db);

  /// Builds a select query for tasks based on filtering criteria.
  SimpleSelectStatement<$TasksTable, TaskEntry> _buildTaskQuery({
    bool includeCompleted = false,
    String? projectId,
    bool isInboxOnly = false,
  }) {
    final query = select(tasks)
      ..where((tbl) => tbl.deletedAt.isNull());

    if (!includeCompleted) {
      query.where((tbl) => tbl.isCompleted.equals(false));
    }

    if (isInboxOnly) {
      query.where((tbl) => tbl.projectId.isNull());
    } else if (projectId != null) {
      query.where((tbl) => tbl.projectId.equals(projectId));
    }

    query.orderBy([
      (tbl) => OrderingTerm.asc(tbl.isCompleted),
      (tbl) => OrderingTerm.asc(tbl.sortOrder),
      (tbl) => OrderingTerm.desc(tbl.createdAt),
    ]);

    return query;
  }

  /// Watches tasks matching the provided criteria.
  Stream<List<TaskEntry>> watchTasks({
    bool includeCompleted = false,
    String? projectId,
    bool isInboxOnly = false,
  }) {
    return _buildTaskQuery(
      includeCompleted: includeCompleted,
      projectId: projectId,
      isInboxOnly: isInboxOnly,
    ).watch();
  }

  /// Retrieves tasks matching the provided criteria.
  Future<List<TaskEntry>> getTasks({
    bool includeCompleted = false,
    String? projectId,
    bool isInboxOnly = false,
  }) {
    return _buildTaskQuery(
      includeCompleted: includeCompleted,
      projectId: projectId,
      isInboxOnly: isInboxOnly,
    ).get();
  }

  /// Retrieves a single task by its [id].
  Future<TaskEntry?> getTaskById(String id) {
    return (select(tasks)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Watches a single task by its [id] reactively.
  Stream<TaskEntry?> watchTaskById(String id) {
    return (select(tasks)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }


  /// Inserts a new task.
  Future<int> insertTask(TasksCompanion companion) {
    return into(tasks).insert(companion);
  }

  /// Updates an existing task.
  Future<bool> updateTask(TasksCompanion companion) {
    return update(tasks).replace(companion);
  }

  /// Toggles completion state for a task by [id].
  Future<int> toggleComplete(
    String id, {
    required bool isCompleted,
    required DateTime now,
  }) {
    return (update(tasks)..where((tbl) => tbl.id.equals(id))).write(
      TasksCompanion(
        isCompleted: Value(isCompleted),
        completedAt: Value(isCompleted ? now : null),
        updatedAt: Value(now),
      ),
    );
  }


  /// Soft-deletes a task by marking `deletedAt` and updating `updatedAt`.
  Future<int> softDeleteTask(String id, DateTime deletedAt) {
    return (update(tasks)..where((tbl) => tbl.id.equals(id))).write(
      TasksCompanion(
        deletedAt: Value(deletedAt),
        updatedAt: Value(deletedAt),
      ),
    );
  }

  /// Physical deletion of a task by [id] (used primarily for test cleanup).
  Future<int> hardDeleteTask(String id) {
    return (delete(tasks)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Retrieves all tasks including soft-deleted ones (for verification/sync).
  Future<List<TaskEntry>> getRawTasks() {
    return select(tasks).get();
  }
}

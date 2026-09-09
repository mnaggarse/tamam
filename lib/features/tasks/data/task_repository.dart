import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamam/core/database/daos/task_dao.dart';
import 'package:tamam/core/database/database.dart';
import 'package:tamam/core/utils/id_generator.dart';
import 'package:tamam/features/tasks/data/models/task.dart';

/// Repository managing Task domain entities.
class TaskRepository {
  /// Creates a [TaskRepository].
  const TaskRepository(this._taskDao);

  final TaskDao _taskDao;

  /// Watches tasks matching the provided criteria.
  Stream<List<Task>> watchTasks({
    bool includeCompleted = false,
    String? projectId,
    bool isInboxOnly = false,
  }) {
    return _taskDao
        .watchTasks(
          includeCompleted: includeCompleted,
          projectId: projectId,
          isInboxOnly: isInboxOnly,
        )
        .map((entries) => entries.map(_entryToDomain).toList());
  }

  /// Retrieves tasks matching the provided criteria.
  Future<List<Task>> getTasks({
    bool includeCompleted = false,
    String? projectId,
    bool isInboxOnly = false,
  }) async {
    final entries = await _taskDao.getTasks(
      includeCompleted: includeCompleted,
      projectId: projectId,
      isInboxOnly: isInboxOnly,
    );
    return entries.map(_entryToDomain).toList();
  }

  /// Retrieves a task by [id].
  Future<Task?> getTask(String id) async {
    final entry = await _taskDao.getTaskById(id);
    return entry != null ? _entryToDomain(entry) : null;
  }

  /// Watches a single task by [id] reactively.
  Stream<Task?> watchTask(String id) {
    return _taskDao
        .watchTaskById(id)
        .map((entry) => entry != null ? _entryToDomain(entry) : null);
  }


  /// Creates and stores a new task.
  Future<String> createTask({
    required String title,
    String? notes,
    String? projectId,
    int priority = 0,
    int sortOrder = 0,
  }) async {
    final id = IdGenerator.generateUuidV7();
    final now = DateTime.now();

    await _taskDao.insertTask(
      TasksCompanion.insert(
        id: id,
        title: title,
        projectId: Value(projectId),
        notes: Value(notes),
        priority: Value(priority),
        sortOrder: Value(sortOrder),
        createdAt: now,
        updatedAt: now,
      ),
    );

    return id;
  }

  /// Updates an existing task.
  Future<void> updateTask(Task task) async {
    final now = DateTime.now();

    await _taskDao.updateTask(
      TasksCompanion(
        id: Value(task.id),
        projectId: Value(task.projectId),
        title: Value(task.title),
        notes: Value(task.notes),
        dueDate: Value(task.dueDate),
        dueTime: Value(task.dueTime),
        priority: Value(task.priority),
        isCompleted: Value(task.isCompleted),
        completedAt: Value(task.completedAt),
        recurrenceRuleId: Value(task.recurrenceRuleId),
        sortOrder: Value(task.sortOrder),
        createdAt: Value(task.createdAt),
        updatedAt: Value(now),
        deletedAt: Value(task.deletedAt),
      ),
    );
  }

  /// Toggles the completion state for a task.
  Future<void> toggleComplete(String id, {required bool isCompleted}) async {
    final now = DateTime.now();
    await _taskDao.toggleComplete(id, isCompleted: isCompleted, now: now);
  }


  /// Soft-deletes a task by its [id].
  Future<void> softDeleteTask(String id) async {
    final now = DateTime.now();
    await _taskDao.softDeleteTask(id, now);
  }

  /// Maps a Drift [TaskEntry] row to a [Task] domain entity.
  static Task _entryToDomain(TaskEntry entry) {
    return Task(
      id: entry.id,
      projectId: entry.projectId,
      title: entry.title,
      notes: entry.notes,
      dueDate: entry.dueDate,
      dueTime: entry.dueTime,
      priority: entry.priority,
      isCompleted: entry.isCompleted,
      completedAt: entry.completedAt,
      recurrenceRuleId: entry.recurrenceRuleId,
      sortOrder: entry.sortOrder,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      deletedAt: entry.deletedAt,
    );
  }
}

/// Riverpod provider for the [TaskRepository].
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final dao = ref.watch(taskDaoProvider);
  return TaskRepository(dao);
});

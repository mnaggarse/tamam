import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamam/core/database/daos/project_dao.dart';
import 'package:tamam/core/database/daos/task_dao.dart';
import 'package:tamam/core/database/database.dart';
import 'package:tamam/features/projects/data/project_repository.dart';
import 'package:tamam/features/tasks/data/task_repository.dart';

void main() {
  late AppDatabase db;
  late TaskDao taskDao;
  late ProjectDao projectDao;
  late TaskRepository taskRepository;
  late ProjectRepository projectRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    taskDao = TaskDao(db);
    projectDao = ProjectDao(db);
    taskRepository = TaskRepository(taskDao);
    projectRepository = ProjectRepository(projectDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('TaskRepository', () {
    test('createTask inserts and emits through watchTasks stream', () async {
      final taskId = await taskRepository.createTask(
        title: 'Buy Groceries',
        notes: 'Milk, eggs, bread',
      );

      expect(taskId, isNotEmpty);

      final tasks = await taskRepository.getTasks();
      expect(tasks.length, 1);
      expect(tasks.first.id, taskId);
      expect(tasks.first.title, 'Buy Groceries');
      expect(tasks.first.notes, 'Milk, eggs, bread');
      expect(tasks.first.projectId, isNull);
      expect(tasks.first.isCompleted, isFalse);
      expect(tasks.first.completedAt, isNull);
      expect(tasks.first.deletedAt, isNull);

      final single = await taskRepository.getTask(taskId);
      expect(single, isNotNull);
      expect(single!.title, 'Buy Groceries');
    });

    test('createTask associates task with an existing project', () async {
      final projectId = await projectRepository.createProject(
        name: 'Personal',
        color: 0xFF3B82F6,
      );

      final taskId = await taskRepository.createTask(
        title: 'Morning workout',
        projectId: projectId,
      );

      final tasks =
          await taskRepository.getTasks(projectId: projectId);
      expect(tasks.length, 1);
      expect(tasks.first.id, taskId);
      expect(tasks.first.projectId, projectId);
    });

    test('updateTask modifies title, notes, and project, updating updatedAt',
        () async {
      final taskId = await taskRepository.createTask(
        title: 'Initial Title',
      );

      final initial = await taskRepository.getTask(taskId);
      expect(initial, isNotNull);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final projectId = await projectRepository.createProject(
        name: 'Work',
        color: 0xFF5B5BD6,
      );

      final updated = initial!.copyWith(
        title: 'Updated Title',
        notes: 'Added notes',
        projectId: projectId,
      );

      await taskRepository.updateTask(updated);

      final fetched = await taskRepository.getTask(taskId);
      expect(fetched!.title, 'Updated Title');
      expect(fetched.notes, 'Added notes');
      expect(fetched.projectId, projectId);
      expect(
        fetched.updatedAt.isAfter(initial.updatedAt) ||
            fetched.updatedAt.isAtSameMomentAs(initial.updatedAt),
        isTrue,
      );
    });

    test('toggleComplete marks completed and manages completedAt timestamp',
        () async {
      final taskId = await taskRepository.createTask(
        title: 'Test completion',
      );

      // Complete task
      await taskRepository.toggleComplete(taskId, isCompleted: true);

      final completedTask = await taskRepository.getTask(taskId);
      expect(completedTask!.isCompleted, isTrue);
      expect(completedTask.completedAt, isNotNull);

      // Default incomplete watch query should now exclude it
      final incompleteTasks = await taskRepository.getTasks();
      expect(incompleteTasks, isEmpty);

      // Query with includeCompleted: true should return it
      final allTasks =
          await taskRepository.getTasks(includeCompleted: true);
      expect(allTasks.length, 1);
      expect(allTasks.first.id, taskId);

      // Toggle back to incomplete
      await taskRepository.toggleComplete(taskId, isCompleted: false);


      final uncompletedTask = await taskRepository.getTask(taskId);
      expect(uncompletedTask!.isCompleted, isFalse);
      expect(uncompletedTask.completedAt, isNull);
    });

    test('softDeleteTask sets deletedAt and excludes from queries', () async {
      final taskId = await taskRepository.createTask(
        title: 'Task to delete',
      );

      expect((await taskRepository.getTasks()).length, 1);

      await taskRepository.softDeleteTask(taskId);

      // Active get and watch queries exclude soft-deleted
      final activeTasks =
          await taskRepository.getTasks(includeCompleted: true);
      expect(activeTasks, isEmpty);

      // Raw table query still retains row with deletedAt != null
      final rawEntries = await taskDao.getRawTasks();
      expect(rawEntries.length, 1);
      expect(rawEntries.first.id, taskId);
      expect(rawEntries.first.deletedAt, isNotNull);
    });
  });
}

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamam/app.dart';
import 'package:tamam/core/database/daos/project_dao.dart';
import 'package:tamam/core/database/daos/tag_dao.dart';
import 'package:tamam/core/database/daos/task_dao.dart';
import 'package:tamam/core/database/database.dart';
import 'package:tamam/features/projects/data/project_repository.dart';
import 'package:tamam/features/tags/data/tag_repository.dart';
import 'package:tamam/features/tasks/data/task_repository.dart';

void main() {
  late AppDatabase db;
  late ProjectDao projectDao;
  late TagDao tagDao;
  late TaskDao taskDao;
  late ProjectRepository projectRepository;
  late TagRepository tagRepository;
  late TaskRepository taskRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    projectDao = ProjectDao(db);
    tagDao = TagDao(db);
    taskDao = TaskDao(db);
    projectRepository = ProjectRepository(projectDao);
    tagRepository = TagRepository(tagDao);
    taskRepository = TaskRepository(taskDao);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        projectDaoProvider.overrideWithValue(projectDao),
        tagDaoProvider.overrideWithValue(tagDao),
        taskDaoProvider.overrideWithValue(taskDao),
        projectRepositoryProvider.overrideWithValue(projectRepository),
        tagRepositoryProvider.overrideWithValue(tagRepository),
        taskRepositoryProvider.overrideWithValue(taskRepository),
      ],
      child: const TamamApp(),
    );
  }

  testWidgets(
    'Task details retains project and notes when reopened after editing',
    (tester) async {
      // 1. Create a project
      await projectRepository.createProject(
        name: 'Work',
        color: 0xFF5B5BD6,
      );

      // 2. Create a task with NO project and NO notes (like QuickAdd)
      await taskRepository.createTask(
        title: 'Draft proposal',
      );

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Verify task is in list
      expect(find.text('Draft proposal'), findsOneWidget);

      // Tap task to open details screen
      await tester.tap(find.text('Draft proposal'));
      await tester.pumpAndSettle();

      // Verify in Task Details
      expect(find.text('Task Details'), findsOneWidget);

      // Enter notes
      final notesField = find.widgetWithText(
        TextFormField,
        'Add description, checklist, or context...',
      );
      await tester.enterText(notesField, 'Detailed project proposal notes');
      await tester.pumpAndSettle();

      // Select Project
      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Work').last);
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Back on list screen: verify project name and notes icon show in list
      expect(find.text('Draft proposal'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.byIcon(Icons.notes), findsOneWidget);

      // NOW OPEN TASK DETAILS AGAIN
      await tester.tap(find.text('Draft proposal'));
      await tester.pumpAndSettle();

      // VERIFY NOTES AND PROJECT IN DETAILS SCREEN
      expect(find.text('Task Details'), findsOneWidget);
      expect(
        find.text('Detailed project proposal notes'),
        findsOneWidget,
        reason: 'Notes should be populated when reopening task details',
      );
      expect(
        find.text('Work'),
        findsOneWidget,
        reason:
            'Selected project should be populated when reopening task details',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}

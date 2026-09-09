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
    'Tasks flow: empty state, quick-add, complete, toggle completed, and edit',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // On launch, Tasks tab is active
      expect(find.text('No tasks yet'), findsOneWidget);

      // Quick add a task
      await tester.enterText(find.byType(TextField), 'Buy fresh milk');
      await tester.pumpAndSettle();

      // Tap add button
      await tester.tap(find.byTooltip('Add Task'));
      await tester.pumpAndSettle();

      // Task should now appear in the list
      expect(find.text('Buy fresh milk'), findsOneWidget);

      // Tap task to open detail screen
      await tester.tap(find.text('Buy fresh milk'));
      await tester.pumpAndSettle();

      // Verify Task Details screen
      expect(find.text('Task Details'), findsOneWidget);
      expect(find.text('Buy fresh milk'), findsOneWidget);

      // Edit title
      final titleField = find.widgetWithText(TextFormField, 'Buy fresh milk');
      await tester.enterText(titleField, 'Buy fresh milk & eggs');
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Back on Tasks screen, verify updated title
      expect(find.text('Buy fresh milk & eggs'), findsOneWidget);

      // Check task complete
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // It should disappear from the incomplete view
      expect(find.text('Buy fresh milk & eggs'), findsNothing);
      expect(find.text('No tasks yet'), findsOneWidget);

      // Tap "Show Completed" in AppBar
      await tester.tap(find.byTooltip('Show Completed'));
      await tester.pumpAndSettle();

      // Now the completed task is visible
      expect(find.text('Buy fresh milk & eggs'), findsOneWidget);

      // Clean unmount
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}

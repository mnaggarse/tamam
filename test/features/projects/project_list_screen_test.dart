import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamam/app.dart';
import 'package:tamam/core/database/daos/project_dao.dart';
import 'package:tamam/core/database/database.dart';
import 'package:tamam/features/projects/data/project_repository.dart';

void main() {
  late AppDatabase db;
  late ProjectDao dao;
  late ProjectRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = ProjectDao(db);
    repository = ProjectRepository(dao);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        projectDaoProvider.overrideWithValue(dao),
        projectRepositoryProvider.overrideWithValue(repository),
      ],
      child: const TamamApp(),
    );
  }

  testWidgets(
    'Projects flow: navigate from Settings, see empty state, create a project',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Navigate to Settings tab
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Tap "Projects" entry
      expect(find.text('Projects'), findsOneWidget);
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();

      // Verify empty state is shown
      expect(find.text('No projects yet'), findsOneWidget);

      // Tap FAB to create a project
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify Create Project screen
      expect(find.text('New Project'), findsOneWidget);

      // Enter project name
      await tester.enterText(find.byType(TextFormField), 'Inbox & Tasks');
      await tester.pumpAndSettle();

      // Tap Save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Back on Project List, verify project exists in list
      expect(find.text('Inbox & Tasks'), findsOneWidget);

      // Unmount widget tree cleanly to dispose active stream subscriptions
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}

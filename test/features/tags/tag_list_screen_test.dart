import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamam/app.dart';
import 'package:tamam/core/database/daos/tag_dao.dart';
import 'package:tamam/core/database/database.dart';
import 'package:tamam/features/tags/data/tag_repository.dart';

void main() {
  late AppDatabase db;
  late TagDao dao;
  late TagRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TagDao(db);
    repository = TagRepository(dao);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        tagDaoProvider.overrideWithValue(dao),
        tagRepositoryProvider.overrideWithValue(repository),
      ],
      child: const TamamApp(),
    );
  }

  testWidgets(
    'Tags flow: navigate from Settings, see empty state, create a tag',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Navigate to Settings tab
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Tap "Tags" entry
      expect(find.text('Tags'), findsOneWidget);
      await tester.tap(find.text('Tags'));
      await tester.pumpAndSettle();

      // Verify empty state is shown
      expect(find.text('No tags yet'), findsOneWidget);

      // Tap FAB to create a tag
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify Create Tag screen
      expect(find.text('New Tag'), findsOneWidget);

      // Enter tag name
      await tester.enterText(find.byType(TextFormField), 'urgent');
      await tester.pumpAndSettle();

      // Tap Save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Back on Tag List, verify tag exists in list (with leading #)
      expect(find.text('#urgent'), findsOneWidget);

      // Unmount widget tree cleanly to dispose active stream subscriptions
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}

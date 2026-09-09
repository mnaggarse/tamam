import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamam/app.dart';
import 'package:tamam/core/database/database.dart';

void main() {
  testWidgets('App smoke test: launches and switches bottom navigation tabs',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const TamamApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial screen is Tasks tab
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Tasks'), findsAtLeastNWidgets(1));
    expect(find.text('No tasks yet'), findsOneWidget);

    // Switch to Calendar tab
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Calendar'), findsAtLeastNWidgets(1));
    expect(find.text('Calendar view is coming in Phase 10'), findsOneWidget);

    // Switch to Settings tab
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsAtLeastNWidgets(1));
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Tags'), findsOneWidget);
    expect(
      find.text('More settings coming in Phase 11'),
      findsOneWidget,
    );

    // Clean unmount
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

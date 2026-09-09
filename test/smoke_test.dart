import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamam/app.dart';

void main() {
  testWidgets('App smoke test: launches and switches bottom navigation tabs',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TamamApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial screen is Tasks tab placeholder
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Tasks'), findsAtLeastNWidgets(1));
    expect(find.text('Task management is coming in Phase 3'), findsOneWidget);

    // Switch to Calendar tab
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Calendar'), findsAtLeastNWidgets(1));
    expect(find.text('Calendar view is coming in Phase 10'), findsOneWidget);

    // Switch to Settings tab
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsAtLeastNWidgets(1));
    expect(
      find.text('Settings and preferences are coming in Phase 11'),
      findsOneWidget,
    );
  });
}

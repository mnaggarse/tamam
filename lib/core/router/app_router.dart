import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tamam/features/projects/presentation/screens/project_edit_screen.dart';
import 'package:tamam/features/projects/presentation/screens/project_list_screen.dart';
import 'package:tamam/features/tags/presentation/screens/tag_edit_screen.dart';
import 'package:tamam/features/tags/presentation/screens/tag_list_screen.dart';

/// Riverpod provider exposing the application's GoRouter configuration.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/tasks',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Tasks',
                  icon: Icons.check_circle_outline,
                  subtitle: 'Task management is coming in Phase 3',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Calendar',
                  icon: Icons.calendar_month_outlined,
                  subtitle: 'Calendar view is coming in Phase 10',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPlaceholderScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ProjectEditScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => ProjectEditScreen(
              projectId: state.pathParameters['id'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/tags',
        builder: (context, state) => const TagListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const TagEditScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => TagEditScreen(
              tagId: state.pathParameters['id'],
            ),
          ),
        ],
      ),
    ],
  );
});

/// Root scaffold hosting the persistent bottom navigation bar.
class ScaffoldWithNavBar extends StatelessWidget {
  /// Creates a [ScaffoldWithNavBar].
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  /// The active navigation shell containing current branch state.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Settings screen tab displaying configuration options and feature entries.
class SettingsPlaceholderScreen extends StatelessWidget {
  /// Creates a [SettingsPlaceholderScreen].
  const SettingsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Projects'),
            subtitle: const Text('Manage lists and project colors'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/projects'),
          ),
          ListTile(
            leading: const Icon(Icons.label_outlined),
            title: const Text('Tags'),
            subtitle: const Text('Organize tasks with custom tags'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/tags'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'More settings coming in Phase 11',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder screen displayed for unbuilt tabs.
class PlaceholderScreen extends StatelessWidget {
  /// Creates a [PlaceholderScreen].
  const PlaceholderScreen({
    required this.title,
    required this.icon,
    required this.subtitle,
    super.key,
  });

  /// Screen title.
  final String title;

  /// Illustrative icon for the placeholder.
  final IconData icon;

  /// Informational subtitle.
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: theme.colorScheme.primary.withAlpha(180),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tamam/features/tasks/application/task_providers.dart';
import 'package:tamam/features/tasks/data/models/task.dart';
import 'package:tamam/features/tasks/presentation/widgets/quick_add_bar.dart';
import 'package:tamam/features/tasks/presentation/widgets/task_tile.dart';

/// Primary screen for managing and organizing tasks.
class TaskListScreen extends ConsumerWidget {
  /// Creates a [TaskListScreen].
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final showCompleted = ref.watch(showCompletedTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: Icon(
              showCompleted
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
            ),
            tooltip: showCompleted ? 'Hide Completed' : 'Show Completed',
            onPressed: () {
              ref
                  .read(showCompletedTasksProvider.notifier)
                  .update((value) => !value);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return _buildEmptyState(
                    context,
                    showCompleted: showCompleted,
                  );
                }

                return _buildTaskList(context, ref, tasks);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Text('Error loading tasks: $error'),
              ),
            ),
          ),
          const QuickAddBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required bool showCompleted,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt_outlined,
              size: 64,
              color: theme.colorScheme.primary.withAlpha(160),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type a task in the quick-add bar below '
              'to start organizing your day.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    WidgetRef ref,
    List<Task> tasks,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
      itemBuilder: (context, index) {
        final task = tasks[index];

        return Dismissible(
          key: ValueKey(task.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Theme.of(context).colorScheme.error,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Task?'),
                content: Text(
                  'Are you sure you want to delete "${task.title}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(ctx).colorScheme.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            ref.read(taskControllerProvider.notifier).deleteTask(task.id);
          },
          child: TaskTile(
            task: task,
            onTap: () => context.push('/tasks/${task.id}'),
          ),
        );
      },
    );
  }
}

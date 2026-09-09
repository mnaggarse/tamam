import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamam/features/projects/application/project_providers.dart';
import 'package:tamam/features/tasks/application/task_providers.dart';
import 'package:tamam/features/tasks/data/models/task.dart';

/// Single row item representing a task in the list.
class TaskTile extends ConsumerWidget {
  /// Creates a [TaskTile].
  const TaskTile({
    required this.task,
    this.onTap,
    super.key,
  });

  /// The task entity to display.
  final Task task;

  /// Callback when the tile is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasNotes = task.notes != null && task.notes!.trim().isNotEmpty;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Transform.scale(
        scale: 1.1,
        child: Checkbox(
          value: task.isCompleted,
          shape: const CircleBorder(),
          activeColor: theme.colorScheme.primary,
          onChanged: (_) {
            ref
                .read(taskControllerProvider.notifier)
                .toggleComplete(task.id, isCompleted: !task.isCompleted);
          },

        ),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          decoration:
              task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted
              ? theme.colorScheme.onSurfaceVariant.withAlpha(150)
              : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: _buildSubtitle(context, ref),
      trailing: hasNotes
          ? Icon(
              Icons.notes,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget? _buildSubtitle(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (task.projectId == null) {
      return null;
    }

    final projectAsync = ref.watch(projectByIdProvider(task.projectId!));

    return projectAsync.when(
      data: (project) {
        if (project == null) return null;
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(project.color),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

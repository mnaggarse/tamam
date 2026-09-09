import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tamam/features/tags/application/tag_providers.dart';
import 'package:tamam/features/tags/data/models/tag.dart';

/// Screen displaying the list of active tags.
class TagListScreen extends ConsumerWidget {
  /// Creates a [TagListScreen].
  const TagListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tags'),
      ),
      body: tagsAsync.when(
        data: (tags) {
          if (tags.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildTagList(context, ref, tags);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('Error loading tags: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tags/new'),
        tooltip: 'New Tag',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.label_outline,
              size: 64,
              color: theme.colorScheme.primary.withAlpha(160),
            ),
            const SizedBox(height: 16),
            Text(
              'No tags yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create tags to categorize, label, and filter '
              'your tasks across projects.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/tags/new'),
              icon: const Icon(Icons.add),
              label: const Text('Create Tag'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagList(
    BuildContext context,
    WidgetRef ref,
    List<Tag> tags,
  ) {
    final theme = Theme.of(context);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: tags.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
      itemBuilder: (context, index) {
        final tag = tags[index];
        final tagColor = tag.color != null ? Color(tag.color!) : null;

        return Dismissible(
          key: ValueKey(tag.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: theme.colorScheme.error,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Tag?'),
                content: Text(
                  'Are you sure you want to delete "#${tag.name}"?',
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
            ref.read(tagControllerProvider.notifier).deleteTag(tag.id);
          },
          child: ListTile(
            leading: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tagColor ?? theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: tagColor != null
                    ? const Text(
                        '#',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Icon(
                        Icons.tag,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
              ),
            ),
            title: Text(
              '#${tag.name}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.push('/tags/${tag.id}'),
          ),
        );
      },
    );
  }
}

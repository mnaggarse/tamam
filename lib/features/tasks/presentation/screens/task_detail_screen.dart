import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tamam/features/projects/application/project_providers.dart';
import 'package:tamam/features/tasks/application/task_providers.dart';
import 'package:tamam/features/tasks/data/models/task.dart';

/// Screen for viewing and editing details of a [Task].
class TaskDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [TaskDetailScreen].
  const TaskDetailScreen({
    required this.taskId,
    super.key,
  });

  /// The unique ID of the task to view/edit.
  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  String? _selectedProjectId;
  bool _isInitialized = false;
  Task? _existingTask;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeFromTask(Task task) {
    if (!_isInitialized) {
      _existingTask = task;
      _titleController.text = task.title;
      _notesController.text = task.notes ?? '';
      _selectedProjectId = task.projectId;
      _isInitialized = true;
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_existingTask == null) return;

    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();

    final updated = _existingTask!.copyWith(
      title: title,
      notes: notes.isNotEmpty ? notes : null,
      projectId: _selectedProjectId,
      clearNotes: notes.isEmpty,
      clearProjectId: _selectedProjectId == null,
    );

    final success =
        await ref.read(taskControllerProvider.notifier).updateTask(updated);

    if (success && mounted) {
      context.pop();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text(
          'Are you sure you want to delete "${_existingTask?.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      final success = await ref
          .read(taskControllerProvider.notifier)
          .deleteTask(widget.taskId);
      if (success && mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(taskControllerProvider);
    final isLoading = controllerState.isLoading;

    if (!_isInitialized) {
      final taskAsync = ref.watch(taskByIdProvider(widget.taskId));

      return taskAsync.when(
        data: (task) {
          if (task == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Task Not Found')),
              body: const Center(child: Text('This task no longer exists.')),
            );
          }
          _initializeFromTask(task);
          return _buildForm(context, isLoading: isLoading);
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Failed to load task: $error')),
        ),
      );
    }

    return _buildForm(context, isLoading: isLoading);
  }

  Widget _buildForm(BuildContext context, {required bool isLoading}) {
    final theme = Theme.of(context);
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Task',
            onPressed: isLoading ? null : _confirmDelete,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: isLoading ? null : _saveTask,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Task Title',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Project',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              projectsAsync.when(
                data: (projects) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedProjectId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        child: Row(

                          children: [
                            Icon(Icons.inbox_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Inbox'),
                          ],
                        ),
                      ),
                      ...projects.map((project) {
                        return DropdownMenuItem<String?>(
                          value: project.id,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Color(project.color),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(project.name),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedProjectId = value;
                      });
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Error loading projects: $error'),
              ),
              const SizedBox(height: 24),
              Text(
                'Notes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                minLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add description, checklist, or context...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

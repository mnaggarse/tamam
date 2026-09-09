import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tamam/features/projects/application/project_providers.dart';
import 'package:tamam/features/projects/data/models/project.dart';

/// Preset color palette for projects.
const List<Color> projectPresetColors = [
  Color(0xFF5B5BD6), // Indigo
  Color(0xFF3B82F6), // Blue
  Color(0xFF06B6D4), // Cyan
  Color(0xFF0D9488), // Teal
  Color(0xFF10B981), // Emerald
  Color(0xFF84CC16), // Lime
  Color(0xFFF59E0B), // Amber
  Color(0xFFF97316), // Orange
  Color(0xFFEF4444), // Coral Red
  Color(0xFFEC4899), // Rose
  Color(0xFF8B5CF6), // Purple
  Color(0xFF64748B), // Slate
];

/// Screen for creating or editing a [Project].
class ProjectEditScreen extends ConsumerStatefulWidget {
  /// Creates a [ProjectEditScreen]. If [projectId] is null, opens in create
  /// mode.
  const ProjectEditScreen({
    this.projectId,
    super.key,
  });

  /// Optional ID of the project being edited.
  final String? projectId;

  @override
  ConsumerState<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends ConsumerState<ProjectEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late Color _selectedColor;
  bool _isInitialized = false;
  Project? _existingProject;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedColor = projectPresetColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initializeFromProject(Project project) {
    if (!_isInitialized) {
      _existingProject = project;
      _nameController.text = project.name;
      _selectedColor = Color(project.color);
      _isInitialized = true;
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final colorValue = _selectedColor.toARGB32();
    final controller = ref.read(projectControllerProvider.notifier);

    if (widget.projectId == null) {
      final newId = await controller.createProject(
        name: name,
        color: colorValue,
      );
      if (newId != null && mounted) {
        context.pop();
      }
    } else if (_existingProject != null) {
      final updated = _existingProject!.copyWith(
        name: name,
        color: colorValue,
      );
      final success = await controller.updateProject(updated);
      if (success && mounted) {
        context.pop();
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text(
          'Are you sure you want to delete "${_existingProject?.name}"?',
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

    if ((confirmed ?? false) && mounted && widget.projectId != null) {
      final success = await ref
          .read(projectControllerProvider.notifier)
          .deleteProject(widget.projectId!);
      if (success && mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.projectId != null;
    final controllerState = ref.watch(projectControllerProvider);
    final isLoading = controllerState.isLoading;

    if (isEditing && !_isInitialized) {
      final projectAsync = ref.watch(projectByIdProvider(widget.projectId!));

      return projectAsync.when(
        data: (project) {
          if (project == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Project Not Found')),
              body: const Center(child: Text('This project no longer exists.')),
            );
          }
          _initializeFromProject(project);
          return _buildForm(context, isLoading: isLoading);
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Failed to load project: $error')),
        ),
      );
    }

    return _buildForm(context, isLoading: isLoading);
  }

  Widget _buildForm(BuildContext context, {required bool isLoading}) {
    final isEditing = widget.projectId != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Project' : 'New Project'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Project',
              onPressed: isLoading ? null : _confirmDelete,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: isLoading ? null : _saveProject,
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
                'Project Name',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                autofocus: !isEditing,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'e.g. Work, Personal, Fitness',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a project name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Color',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: projectPresetColors.map((color) {
                  final isSelected =
                      _selectedColor.toARGB32() == color.toARGB32();
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.withAlpha(120),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 22,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

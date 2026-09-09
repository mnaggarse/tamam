import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tamam/features/tags/application/tag_providers.dart';
import 'package:tamam/features/tags/data/models/tag.dart';

/// Preset color palette for tags.
const List<Color> tagPresetColors = [
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

/// Screen for creating or editing a [Tag].
class TagEditScreen extends ConsumerStatefulWidget {
  /// Creates a [TagEditScreen]. If [tagId] is null, opens in create mode.
  const TagEditScreen({
    this.tagId,
    super.key,
  });

  /// Optional ID of the tag being edited.
  final String? tagId;

  @override
  ConsumerState<TagEditScreen> createState() => _TagEditScreenState();
}

class _TagEditScreenState extends ConsumerState<TagEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  Color? _selectedColor;
  bool _isInitialized = false;
  Tag? _existingTag;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedColor = null; // Default to no color for tags
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initializeFromTag(Tag tag) {
    if (!_isInitialized) {
      _existingTag = tag;
      _nameController.text = tag.name;
      _selectedColor = tag.color != null ? Color(tag.color!) : null;
      _isInitialized = true;
    }
  }

  String _cleanTagName(String input) {
    var cleaned = input.trim();
    while (cleaned.startsWith('#')) {
      cleaned = cleaned.substring(1).trim();
    }
    return cleaned;
  }

  Future<void> _saveTag() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _cleanTagName(_nameController.text);
    final colorValue = _selectedColor?.toARGB32();
    final controller = ref.read(tagControllerProvider.notifier);

    if (widget.tagId == null) {
      final newId = await controller.createTag(
        name: name,
        color: colorValue,
      );
      if (newId != null && mounted) {
        context.pop();
      }
    } else if (_existingTag != null) {
      final updated = _existingTag!.copyWith(
        name: name,
        color: colorValue,
        clearColor: colorValue == null,
      );
      final success = await controller.updateTag(updated);
      if (success && mounted) {
        context.pop();
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag?'),
        content: Text(
          'Are you sure you want to delete "#${_existingTag?.name}"?',
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

    if ((confirmed ?? false) && mounted && widget.tagId != null) {
      final success = await ref
          .read(tagControllerProvider.notifier)
          .deleteTag(widget.tagId!);
      if (success && mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tagId != null;
    final controllerState = ref.watch(tagControllerProvider);
    final isLoading = controllerState.isLoading;

    if (isEditing && !_isInitialized) {
      final tagAsync = ref.watch(tagByIdProvider(widget.tagId!));

      return tagAsync.when(
        data: (tag) {
          if (tag == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Tag Not Found')),
              body: const Center(child: Text('This tag no longer exists.')),
            );
          }
          _initializeFromTag(tag);
          return _buildForm(context, isLoading: isLoading);
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Failed to load tag: $error')),
        ),
      );
    }

    return _buildForm(context, isLoading: isLoading);
  }

  Widget _buildForm(BuildContext context, {required bool isLoading}) {
    final isEditing = widget.tagId != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Tag' : 'New Tag'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Tag',
              onPressed: isLoading ? null : _confirmDelete,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: isLoading ? null : _saveTag,
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
                'Tag Name',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                autofocus: !isEditing,
                decoration: InputDecoration(
                  hintText: 'e.g. urgent, health, finances',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _selectedColor ??
                            theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '#',
                          style: TextStyle(
                            color: _selectedColor != null
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || _cleanTagName(value).isEmpty) {
                    return 'Please enter a tag name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Color (Optional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Option for "No Color"
                  _buildNoColorOption(theme),
                  ...tagPresetColors.map(
                    (color) => _buildColorOption(theme, color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoColorOption(ThemeData theme) {
    final isSelected = _selectedColor == null;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedColor = null;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.onSurface
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: theme.colorScheme.shadow.withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Center(
          child: Icon(
            isSelected ? Icons.check : Icons.format_color_reset_outlined,
            size: 20,
            color: isSelected
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(ThemeData theme, Color color) {
    final isSelected = _selectedColor?.toARGB32() == color.toARGB32();

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
  }
}

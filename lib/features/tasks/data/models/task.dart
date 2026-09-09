import 'package:equatable/equatable.dart';

/// Domain entity representing a Task.
class Task extends Equatable {
  /// Creates a [Task] instance.
  const Task({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.projectId,
    this.notes,
    this.dueDate,
    this.dueTime,
    this.priority = 0,
    this.isCompleted = false,
    this.completedAt,
    this.recurrenceRuleId,
    this.sortOrder = 0,
    this.deletedAt,
  });

  /// Unique identifier (UUIDv7).
  final String id;

  /// Associated project ID, or null for "Inbox".
  final String? projectId;

  /// Task title.
  final String title;

  /// Detailed notes or description.
  final String? notes;

  /// Scheduled due date.
  final DateTime? dueDate;

  /// Scheduled due time.
  final DateTime? dueTime;

  /// Priority level (0: None, 1: Low, 2: Medium, 3: High).
  final int priority;

  /// Whether the task is completed.
  final bool isCompleted;

  /// Timestamp when marked completed.
  final DateTime? completedAt;

  /// Recurrence rule identifier (for Phase 8).
  final String? recurrenceRuleId;

  /// Display sort order index.
  final int sortOrder;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last modification timestamp for sync.
  final DateTime updatedAt;

  /// Soft-delete timestamp, or null if active.
  final DateTime? deletedAt;

  /// Creates a copy of this [Task] with updated values.
  Task copyWith({
    String? id,
    String? title,
    String? projectId,
    String? notes,
    DateTime? dueDate,
    DateTime? dueTime,
    int? priority,
    bool? isCompleted,
    DateTime? completedAt,
    String? recurrenceRuleId,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearProjectId = false,
    bool clearNotes = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      projectId: clearProjectId ? null : (projectId ?? this.projectId),
      notes: clearNotes ? null : (notes ?? this.notes),
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      recurrenceRuleId: recurrenceRuleId ?? this.recurrenceRuleId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        title,
        notes,
        dueDate,
        dueTime,
        priority,
        isCompleted,
        completedAt,
        recurrenceRuleId,
        sortOrder,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}

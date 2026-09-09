import 'package:equatable/equatable.dart';

/// Domain entity representing a Project.
class Project extends Equatable {
  /// Creates a [Project] instance.
  const Project({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.icon,
    this.sortOrder = 0,
    this.deletedAt,
  });

  /// Unique identifier (UUIDv7).
  final String id;

  /// Project title/name.
  final String name;

  /// 32-bit ARGB color value.
  final int color;

  /// Optional icon identifier.
  final String? icon;

  /// Display sort order index.
  final int sortOrder;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime updatedAt;

  /// Soft-delete timestamp, or null if active.
  final DateTime? deletedAt;

  /// Creates a copy of this [Project] with updated values.
  Project copyWith({
    String? id,
    String? name,
    int? color,
    String? icon,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        color,
        icon,
        sortOrder,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}

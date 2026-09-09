import 'package:equatable/equatable.dart';

/// Domain entity representing a Tag.
class Tag extends Equatable {
  /// Creates a [Tag] instance.
  const Tag({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    this.deletedAt,
  });

  /// Unique identifier (UUIDv7).
  final String id;

  /// Tag title/name.
  final String name;

  /// Optional 32-bit ARGB color value.
  final int? color;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime updatedAt;

  /// Soft-delete timestamp, or null if active.
  final DateTime? deletedAt;

  /// Creates a copy of this [Tag] with updated values.
  Tag copyWith({
    String? id,
    String? name,
    int? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearColor = false,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: clearColor ? null : (color ?? this.color),
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
        createdAt,
        updatedAt,
        deletedAt,
      ];
}

import 'package:flutter/material.dart';

/// Semantic and palette color tokens for the Tamam application.
abstract final class AppColors {
  /// Primary brand seed color.
  static const Color primarySeed = Color(0xFF5B5BD6);

  /// Priority indicator colors.
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF3B82F6);
  static const Color priorityNone = Color(0xFF9CA3AF);

  /// Light theme neutral colors.
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);

  /// Dark theme neutral colors.
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
}

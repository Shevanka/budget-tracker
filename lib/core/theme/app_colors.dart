import 'package:flutter/material.dart';

/// Semantic and palette color constants for the Budget Tracker app.
abstract final class AppColors {
  // Brand & Seed (Fresh financial emerald green)
  static const Color primarySeed = Color(0xFF006C4C);

  // Financial Semantics
  static const Color income = Color(0xFF2E7D32);
  static const Color expense = Color(0xFFD32F2F);

  // Budget Status Thresholds (<80% safe, 80-99% warning, >=100% danger)
  static const Color budgetSafe = Color(0xFF2E7D32);
  static const Color budgetWarning = Color(0xFFF57F17);
  static const Color budgetDanger = Color(0xFFD32F2F);

  // Category Palette (16 distinct colors for user custom categories)
  static const List<Color> categoryPalette = [
    Color(0xFFE53935), // Red
    Color(0xFFD81B60), // Pink
    Color(0xFF8E24AA), // Purple
    Color(0xFF5E35B1), // Deep Purple
    Color(0xFF3949AB), // Indigo
    Color(0xFF1E88E5), // Blue
    Color(0xFF039BE5), // Light Blue
    Color(0xFF00ACC1), // Cyan
    Color(0xFF00897B), // Teal
    Color(0xFF43A047), // Green
    Color(0xFF7CB342), // Light Green
    Color(0xFFFDD835), // Yellow
    Color(0xFFFB8C00), // Orange
    Color(0xFFF4511E), // Deep Orange
    Color(0xFF6D4C41), // Brown
    Color(0xFF546E7A), // Blue Grey
  ];
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Reusable color picker widget for category creation and customization.
///
/// Displays a curated palette of vibrant financial category colors with
/// high-contrast selection feedback and accessible semantics.
class CategoryColorPicker extends StatelessWidget {
  const CategoryColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.colors = defaultColors,
  });

  /// The currently selected color integer (ARGB).
  final int selectedColor;

  /// Callback triggered when a color is tapped.
  final ValueChanged<int> onColorSelected;

  /// Optional custom palette of colors. Defaults to [defaultColors].
  final List<int> colors;

  /// Standard 16 distinct palette colors mapped from [AppColors.categoryPalette].
  static const List<int> defaultColors = [
    0xFFE53935, // Red
    0xFFD81B60, // Pink
    0xFF8E24AA, // Purple
    0xFF5E35B1, // Deep Purple
    0xFF3949AB, // Indigo
    0xFF1E88E5, // Blue
    0xFF039BE5, // Light Blue
    0xFF00ACC1, // Cyan
    0xFF00897B, // Teal
    0xFF43A047, // Green
    0xFF7CB342, // Light Green
    0xFFFDD835, // Yellow
    0xFFFB8C00, // Orange
    0xFFF4511E, // Deep Orange
    0xFF6D4C41, // Brown
    0xFF546E7A, // Blue Grey
  ];

  static const Map<int, String> colorNames = {
    0xFFE53935: 'Red',
    0xFFD81B60: 'Pink',
    0xFF8E24AA: 'Purple',
    0xFF5E35B1: 'Deep Purple',
    0xFF3949AB: 'Indigo',
    0xFF1E88E5: 'Blue',
    0xFF039BE5: 'Light Blue',
    0xFF00ACC1: 'Cyan',
    0xFF00897B: 'Teal',
    0xFF43A047: 'Green',
    0xFF7CB342: 'Light Green',
    0xFFFDD835: 'Yellow',
    0xFFFB8C00: 'Orange',
    0xFFF4511E: 'Deep Orange',
    0xFF6D4C41: 'Brown',
    0xFF546E7A: 'Blue Grey',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Color',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              colorNames[selectedColor] ?? 'Custom',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final colorInt = colors[index];
              final isSelected = colorInt == selectedColor;
              final name = colorNames[colorInt] ?? 'Color ${index + 1}';

              return Tooltip(
                message: name,
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: name,
                  child: GestureDetector(
                    onTap: () => onColorSelected(colorInt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(colorInt),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.onSurface
                              : Colors.transparent,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Color(colorInt).withValues(alpha: 0.55),
                              blurRadius: 8,
                              spreadRadius: 1,
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
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

/// Standard Material 3 empty state widget displaying an icon, title, description,
/// and an optional actionable button.
class AppEmptyState extends StatelessWidget {
  /// Icon representing the empty condition.
  final IconData icon;

  /// Main headline explaining the empty state.
  final String title;

  /// Helpful message guiding the user on next steps.
  final String message;

  /// Optional text label for the primary call-to-action button.
  final String? actionLabel;

  /// Optional icon for the primary call-to-action button.
  final IconData? actionIcon;

  /// Callback executed when the primary button is tapped.
  final VoidCallback? onAction;

  /// Optional custom icon color.
  final Color? iconColor;

  /// Padding around the empty state widget.
  final EdgeInsetsGeometry padding;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.iconColor,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: effectiveIconColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Standard Material 3 error state widget displaying an error icon, message,
/// and an optional retry button.
class AppErrorState extends StatelessWidget {
  /// Icon representing the error condition (defaults to [Icons.error_outline]).
  final IconData icon;

  /// The error title headline.
  final String title;

  /// Optional detailed error description.
  final String? message;

  /// Optional retry callback.
  final VoidCallback? onRetry;

  /// Label for the retry button (defaults to 'Retry').
  final String retryLabel;

  /// Whether to display in a compact card format rather than full centered layout.
  final bool isCard;

  /// Padding around the error content.
  final EdgeInsetsGeometry padding;

  const AppErrorState({
    super.key,
    this.icon = Icons.error_outline,
    this.title = 'Something went wrong',
    this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.isCard = false,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 30,
            color: colorScheme.error,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isCard ? colorScheme.onErrorContainer : colorScheme.onSurface,
          ),
        ),
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isCard
                  ? colorScheme.onErrorContainer.withValues(alpha: 0.8)
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(retryLabel),
          ),
        ],
      ],
    );

    if (isCard) {
      return Card(
        elevation: 0,
        color: colorScheme.errorContainer.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: padding,
          child: content,
        ),
      );
    }

    return Center(
      child: Padding(
        padding: padding,
        child: content,
      ),
    );
  }
}

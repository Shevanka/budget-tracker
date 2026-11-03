import 'package:flutter/material.dart';

/// Standard Material 3 loading indicator with optional status message and height constraints.
class AppLoadingState extends StatelessWidget {
  /// Optional message displayed below the progress indicator (e.g. 'Loading transactions...').
  final String? message;

  /// Optional fixed height (useful for sections inside a scrollable screen).
  final double? height;

  /// Size of the circular progress indicator.
  final double indicatorSize;

  const AppLoadingState({
    super.key,
    this.message,
    this.height,
    this.indicatorSize = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final widgetContent = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: indicatorSize,
            height: indicatorSize,
            child: const CircularProgressIndicator(strokeWidth: 3),
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    if (height != null) {
      return SizedBox(
        height: height,
        child: widgetContent,
      );
    }

    return widgetContent;
  }
}

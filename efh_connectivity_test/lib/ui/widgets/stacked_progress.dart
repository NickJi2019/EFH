import 'package:flutter/material.dart';

/// A two-layer progress bar: a light layer for work that has started and a
/// darker layer for work that has finished, each animated smoothly.
class StackedProgress extends StatelessWidget {
  const StackedProgress({
    super.key,
    required this.started,
    required this.completed,
    this.height = 3,
    this.borderRadius,
    this.color,
  });

  /// Fraction (0..1) of work that has started.
  final double started;

  /// Fraction (0..1) of work that has finished.
  final double completed;

  final double height;
  final BorderRadius? borderRadius;

  /// Bar color; defaults to the theme primary.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bar = color ?? scheme.primary;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: started.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, startedValue, _) {
        return Stack(
          children: [
            LinearProgressIndicator(
              value: startedValue,
              minHeight: height,
              borderRadius: borderRadius,
              color: bar.withValues(alpha: 0.35),
              backgroundColor: scheme.surfaceContainerHighest,
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: completed.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              builder: (context, completedValue, _) => LinearProgressIndicator(
                value: completedValue,
                minHeight: height,
                borderRadius: borderRadius,
                color: bar,
                backgroundColor: Colors.transparent,
              ),
            ),
          ],
        );
      },
    );
  }
}

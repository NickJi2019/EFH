import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum CommonCardType { plain, filled }

/// A Material 3 surface card in the style of FlClash's `CommonCard`:
/// `plain` draws a hairline border, `filled` is a solid container, and a
/// selected card uses the secondary container role.
class CommonCard extends StatelessWidget {
  const CommonCard({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.isSelected = false,
    this.isError = false,
    this.type = CommonCardType.plain,
    this.padding,
    this.radius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isError;
  final CommonCardType type;
  final EdgeInsetsGeometry? padding;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = type == CommonCardType.filled;

    final Color background;
    if (isError) {
      background = scheme.errorContainer;
    } else if (filled) {
      background = isSelected
          ? scheme.secondaryContainer
          : scheme.surfaceContainerHigh;
    } else {
      background = isSelected
          ? scheme.secondaryContainer
          : scheme.surfaceContainerLow;
    }

    final Color border;
    if (isError) {
      border = scheme.error;
    } else if (isSelected) {
      border = scheme.primary;
    } else {
      border = scheme.surfaceContainerHighest;
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius ?? AppCorner.md),
      side: filled ? BorderSide.none : BorderSide(color: border),
    );

    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppInsets.card),
      child: child,
    );

    if (onPressed == null && onLongPress == null) {
      return DecoratedBox(
        decoration: ShapeDecoration(color: background, shape: shape),
        child: content,
      );
    }
    return Material(
      color: background,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        onLongPress: onLongPress,
        child: content,
      ),
    );
  }
}

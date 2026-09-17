import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A section title with an optional leading icon and trailing actions,
/// mirroring FlClash's `InfoHeader`.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(
      AppInsets.page,
      8,
      AppInsets.page,
      8,
    ),
  });

  final String title;
  final IconData? icon;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (actions.isNotEmpty) ...[const SizedBox(width: 8), ...actions],
        ],
      ),
    );
  }
}

/// A titled block of settings rendered inside one surface card, the FlClash
/// `SettingsBlock` pattern.
class SettingsBlock extends StatelessWidget {
  const SettingsBlock({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.actions = const [],
  });

  final String title;
  final IconData? icon;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        spaced.add(
          const Divider(indent: AppInsets.page, endIndent: AppInsets.page),
        );
      }
      spaced.add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title, icon: icon, actions: actions),
        Material(
          color: scheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppCorner.md),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: spaced,
          ),
        ),
      ],
    );
  }
}

/// Pads a custom control so it aligns with the block's list tiles.
class SettingPadding extends StatelessWidget {
  const SettingPadding({super.key, required this.child, this.vertical = 8});

  final Widget child;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppInsets.page,
        vertical: vertical,
      ),
      child: child,
    );
  }
}

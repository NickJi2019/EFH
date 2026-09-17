import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common_card.dart';

class StatItem {
  const StatItem(this.label, this.value, {this.icon, this.highlight = false});

  final String label;
  final int value;
  final IconData? icon;
  final bool highlight;
}

/// A responsive grid of statistics, in the spirit of FlClash's dashboard grid.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.items});

  final List<StatItem> items;

  int _columns(double width) {
    final int preferred;
    if (width >= 720) {
      preferred = 5;
    } else if (width >= 480) {
      preferred = 3;
    } else {
      preferred = 2;
    }
    return preferred < items.length ? preferred : items.length;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = _columns(constraints.maxWidth);
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _StatCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final StatItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = item.highlight ? scheme.error : scheme.onSurface;
    return CommonCard(
      type: CommonCardType.filled,
      padding: const EdgeInsets.all(AppInsets.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${item.value}',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

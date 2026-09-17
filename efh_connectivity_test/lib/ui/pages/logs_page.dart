import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent, ScrollDirection;

import '../../connectivity/favicon_cache.dart';
import '../../connectivity/radar.dart';
import '../../connectivity/site_metadata.dart';
import '../../connectivity/status.dart';
import '../../l10n/app_localizations.dart';
import '../run_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/stacked_progress.dart';

enum _StatusFilter {
  reachable,
  hdsbBlocked,
  expired,
  unreachable,
  otherProblem,
}

/// The result log: one row per probed domain. Rows appear as soon as a probe
/// starts (with a spinner), then move to the bottom with an icon once done.
class LogsPage extends StatefulWidget {
  const LogsPage({super.key, required this.controller});

  final RunController controller;

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage>
    with AutomaticKeepAliveClientMixin {
  final _metadata = SiteMetadata();
  final _favicons = FaviconCache();
  final _scrollController = ScrollController();

  /// How close to the bottom the user must scroll for auto-scroll to resume.
  static const double _resumeMargin = 64;

  bool _wasAutoScroll = true;

  final Set<_StatusFilter> _statuses = {};
  final Set<int> _heatTops = {};
  bool _filtersExpanded = true;
  String _query = '';
  final _searchController = TextEditingController();

  int _lastListKey = 0;
  Widget? _cachedList;
  Widget? _cachedFilters;
  int _filtersKey = 0;
  Widget? _cachedFab;
  bool? _fabKey;
  Timer? _searchDebounce;

  List<ResultItem>? _filtered;
  int? _cacheKey;

  bool get _hasFilter =>
      _statuses.isNotEmpty || _heatTops.isNotEmpty || _query.isNotEmpty;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Theme or locale changed: drop cached subtrees so they pick up the new
    // styling instead of being reused verbatim.
    _cachedFilters = null;
    _filtersKey = 0;
    _cachedFab = null;
    _fabKey = null;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ResultItem> _computeFiltered(RunController c) {
    final key = Object.hash(
      c.resultsRevision.value,
      Object.hashAll(_statuses),
      Object.hashAll(_heatTops),
      _query,
      c.pending.length,
      c.completed.length,
    );
    if (key == _cacheKey && _filtered != null) {
      return _filtered!;
    }
    _cacheKey = key;

    final query = _query.trim().toLowerCase();
    bool matchesQuery(ResultItem item) =>
        query.isEmpty ||
        item.host.toLowerCase().contains(query) ||
        item.detail.toLowerCase().contains(query);

    bool passesHeat(ResultItem item) =>
        _heatTops.isEmpty || _heatTops.contains(item.top);

    bool passesStatus(ResultItem item) {
      if (_statuses.isEmpty) {
        return true;
      }
      for (final status in _statuses) {
        if (_matchesStatus(item, status)) {
          return true;
        }
      }
      return false;
    }

    final list = <ResultItem>[];
    // Running probes have no outcome yet, so only show them unfiltered.
    if (_statuses.isEmpty) {
      for (final item in c.pending) {
        if (passesHeat(item) && matchesQuery(item)) {
          list.add(item);
        }
      }
    }
    for (final item in c.completed) {
      if (passesStatus(item) && passesHeat(item) && matchesQuery(item)) {
        list.add(item);
      }
    }
    return _filtered = list;
  }

  bool _scrollScheduled = false;

  void _scrollToEnd() {
    if (_scrollScheduled) {
      return;
    }
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final max = _scrollController.position.maxScrollExtent;
      if (_scrollController.offset < max) {
        _scrollController.jumpTo(max);
      }
    });
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await widget.controller.exportJson();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            path == null ? l10n.snackCancelledExport : l10n.snackExported(path),
          ),
        ),
      );
    } catch (exception) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.snackExportFailed('$exception'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final c = widget.controller;
    // Re-enabling auto-scroll must take effect immediately, not only after the
    // next result arrives (the list itself is cached between updates).
    if (c.autoScroll && !_wasAutoScroll) {
      _scrollToEnd();
    }
    _wasAutoScroll = c.autoScroll;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final total = c.pending.length + c.completed.length;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (c.running && !c.paused) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(l10n.logsTitle(total)),
              ],
            ),
            bottom: c.running
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(3),
                    child: StackedProgress(
                      started: c.total > 0
                          ? (c.pending.length + c.completed.length) / c.total
                          : 0,
                      completed: c.total > 0 ? c.completed.length / c.total : 0,
                    ),
                  )
                : null,
            actions: [
              IconButton(
                tooltip: l10n.actionExportJson,
                onPressed: c.hasResults && !c.running ? _export : null,
                icon: const Icon(Icons.share),
              ),
              IconButton(
                tooltip: l10n.actionClear,
                onPressed: total == 0 ? null : c.clearResults,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _filtersFor(context, l10n, c),
                  const Divider(height: 1),
                  Expanded(child: _listFor(context, l10n, c)),
                ],
              ),
              Positioned(
                left: 16,
                bottom: 16,
                child: _autoScrollFabFor(context, l10n, c),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Returns the list, reusing the previous widget instance when the results
  /// have not changed, so a progress tick does not rebuild the whole list.
  Widget _listFor(
    BuildContext context,
    AppLocalizations l10n,
    RunController c,
  ) {
    final key = Object.hash(
      c.resultsRevision.value,
      _query,
      Object.hashAll(_statuses),
      Object.hashAll(_heatTops),
    );
    if (_cachedList == null || _lastListKey != key) {
      _lastListKey = key;
      _cachedList = _buildList(context, l10n, c);
    }
    return _cachedList!;
  }

  Widget _buildList(
    BuildContext context,
    AppLocalizations l10n,
    RunController c,
  ) {
    final int count;
    final ResultItem Function(int index) itemAt;
    if (_hasFilter) {
      final filtered = _computeFiltered(c);
      count = filtered.length;
      itemAt = (index) => filtered[index];
    } else {
      count = c.pending.length + c.completed.length;
      itemAt = (index) => index < c.pending.length
          ? c.pending[index]
          : c.completed[index - c.pending.length];
    }
    if (count > 0 && c.autoScroll) {
      _scrollToEnd();
    }
    final list = count == 0
        ? _buildEmpty(context, l10n)
        : Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.laptop,
              ),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // Any scroll the user drives themselves (either direction)
                  // turns auto-scroll off immediately.
                  if (notification is UserScrollNotification) {
                    if (notification.direction != ScrollDirection.idle &&
                        c.autoScroll) {
                      c.setAutoScroll(false);
                    }
                  } else if (notification is ScrollEndNotification) {
                    // Only resume once the user has stopped, and only when
                    // they are at/near the bottom — otherwise dragging upward
                    // would be immediately undone.
                    if (!c.autoScroll &&
                        notification.metrics.extentAfter <= _resumeMargin) {
                      c.setAutoScroll(true);
                    }
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: count,
                  // Keep the last row clear of the floating action button.
                  padding: const EdgeInsets.only(bottom: 96),
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                  scrollCacheExtent: const ScrollCacheExtent.pixels(200),
                  itemBuilder: (context, index) {
                    final item = itemAt(index);
                    return RepaintBoundary(
                      key: ValueKey(item.seq),
                      child: _ResultTile(
                        item: item,
                        metadata: _metadata,
                        favicons: _favicons,
                        paused: c.paused,
                        quick: c.hdsbDetection && c.hdsbQuickCheck,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
    return list;
  }

  /// Reuses the filter bar between high-frequency progress ticks; it only
  /// depends on a handful of low-churn values.
  Widget _filtersFor(
    BuildContext context,
    AppLocalizations l10n,
    RunController c,
  ) {
    final key = Object.hash(
      c.hdsbDetection,
      c.hdsbQuickCheck,
      _filtersExpanded,
      _query,
      Object.hashAll(_statuses),
      Object.hashAll(_heatTops),
    );
    if (_cachedFilters == null || _filtersKey != key) {
      _filtersKey = key;
      _cachedFilters = _buildFilters(context, l10n, c);
    }
    return _cachedFilters!;
  }

  Widget _autoScrollFabFor(
    BuildContext context,
    AppLocalizations l10n,
    RunController c,
  ) {
    if (_cachedFab == null || _fabKey != c.autoScroll) {
      _fabKey = c.autoScroll;
      _cachedFab = _buildAutoScrollFab(context, l10n, c);
    }
    return _cachedFab!;
  }

  Widget _buildAutoScrollFab(
    BuildContext context,
    AppLocalizations l10n,
    RunController c,
  ) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(c.autoScroll),
      tween: Tween<double>(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: FloatingActionButton.extended(
        heroTag: 'logsAutoScroll',
        tooltip: c.autoScroll
            ? l10n.actionAutoScrollStop
            : l10n.actionAutoScrollStart,
        backgroundColor: c.autoScroll
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: c.autoScroll
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurfaceVariant,
        onPressed: () => c.setAutoScroll(!c.autoScroll),
        icon: const Icon(Icons.vertical_align_bottom),
        label: Text(c.autoScroll ? l10n.autoScrollOn : l10n.autoScrollOff),
      ),
    );
  }

  Widget _buildFilters(
    BuildContext context,
    AppLocalizations l10n,
    RunController c,
  ) {
    final quick = c.hdsbDetection && c.hdsbQuickCheck;
    final statusOptions = <_StatusFilter>[
      _StatusFilter.reachable,
      _StatusFilter.hdsbBlocked,
      if (quick)
        _StatusFilter.otherProblem
      else ...[
        _StatusFilter.expired,
        _StatusFilter.unreachable,
      ],
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppInsets.page, 8, AppInsets.page, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    // Debounced so filtering a large result set does not run on
                    // every keystroke.
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(
                      const Duration(milliseconds: 250),
                      () {
                        if (mounted) {
                          setState(() => _query = value);
                        }
                      },
                    );
                  },
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _searchDebounce?.cancel();
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l10n.filterTitle,
                onPressed: () =>
                    setState(() => _filtersExpanded = !_filtersExpanded),
                icon: Icon(
                  _filtersExpanded ? Icons.expand_less : Icons.expand_more,
                ),
              ),
            ],
          ),
          if (_filtersExpanded) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _MultiSelectMenu<_StatusFilter>(
                  label: l10n.filterStatus,
                  options: statusOptions,
                  optionLabel: (value) => switch (value) {
                    _StatusFilter.reachable => l10n.badgeReachable,
                    _StatusFilter.hdsbBlocked => l10n.badgeHdsbBlocked,
                    _StatusFilter.expired => l10n.badgeCertificateExpired,
                    _StatusFilter.unreachable => l10n.badgeUnreachable,
                    _StatusFilter.otherProblem => l10n.badgeCertUnavailable,
                  },
                  selected: _statuses,
                  enabledFor: (value) =>
                      value != _StatusFilter.hdsbBlocked || c.hdsbDetection,
                  onChanged: (value) => setState(() {
                    _statuses
                      ..clear()
                      ..addAll(value);
                  }),
                ),
                _MultiSelectMenu<int>(
                  label: l10n.filterHeat,
                  options: [for (final bucket in rankingBuckets) bucket.top],
                  optionLabel: (value) => Bucket(value).label,
                  selected: _heatTops,
                  onChanged: (value) => setState(() {
                    _heatTops
                      ..clear()
                      ..addAll(value);
                  }),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.resultsEmpty,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// A compact multi-select drop-down: a button that opens a menu of checkbox
/// entries which stay open while toggling.
class _MultiSelectMenu<T> extends StatelessWidget {
  const _MultiSelectMenu({
    required this.label,
    required this.options,
    required this.optionLabel,
    required this.selected,
    required this.onChanged,
    this.enabledFor,
  });

  final String label;
  final List<T> options;
  final String Function(T value) optionLabel;
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;
  final bool Function(T value)? enabledFor;

  bool _enabled(T value) => enabledFor?.call(value) ?? true;

  String _summary(AppLocalizations l10n) {
    if (selected.isEmpty) {
      return label;
    }
    if (selected.length == 1) {
      return optionLabel(selected.first);
    }
    return '$label (${selected.length})';
  }

  void _toggle(T option) {
    final next = Set<T>.of(selected);
    if (!next.add(option)) {
      next.remove(option);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          closeOnActivate: false,
          onPressed: () => onChanged(<T>{}),
          leadingIcon: Icon(
            selected.isEmpty ? Icons.check_box : Icons.check_box_outline_blank,
            size: 18,
          ),
          child: Text(l10n.filterAll),
        ),
        const Divider(height: 1),
        for (final option in options)
          MenuItemButton(
            closeOnActivate: false,
            onPressed: _enabled(option) ? () => _toggle(option) : null,
            leadingIcon: Icon(
              selected.contains(option)
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              size: 18,
            ),
            child: Text(optionLabel(option)),
          ),
      ],
      builder: (context, controller, child) {
        return OutlinedButton.icon(
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          icon: Icon(
            Icons.filter_list,
            size: 18,
            color: selected.isEmpty ? scheme.onSurfaceVariant : scheme.primary,
          ),
          label: Text(_summary(l10n)),
        );
      },
    );
  }
}

/// A single result row. Kept deliberately cheap: no per-row animations or
/// tickers, and network metadata (title/favicon) is only requested once the row
/// has actually settled in the viewport.
class _ResultTile extends StatefulWidget {
  const _ResultTile({
    required this.item,
    required this.metadata,
    required this.favicons,
    this.paused = false,
    this.quick = false,
  });

  final ResultItem item;
  final SiteMetadata metadata;
  final FaviconCache favicons;
  final bool paused;
  final bool quick;

  @override
  State<_ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends State<_ResultTile> {
  static const double _hostHeight = 22;
  static const double _subtitleHeight = 18;

  /// Delay before a row is considered "settled" and starts fetching metadata.
  static const Duration _settleDelay = Duration(milliseconds: 240);

  bool _expanded = false;
  bool _metadataReady = false;
  String? _title;
  Timer? _titleTimer;

  @override
  void initState() {
    super.initState();
    _scheduleMetadata();
  }

  @override
  void didUpdateWidget(covariant _ResultTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.host != widget.item.host) {
      _title = null;
      _metadataReady = false;
      _scheduleMetadata();
    }
  }

  @override
  void dispose() {
    _titleTimer?.cancel();
    super.dispose();
  }

  /// Defers all metadata work (title + favicon) slightly so tiles that are
  /// merely scrolled past never trigger a request.
  void _scheduleMetadata() {
    final host = widget.item.host;
    if (widget.metadata.isCached(host)) {
      _title = widget.metadata.cachedTitle(host);
      _metadataReady = true;
      return;
    }
    _titleTimer?.cancel();
    _titleTimer = Timer(_settleDelay, () {
      if (!mounted) {
        return;
      }
      setState(() => _metadataReady = true);
      _loadTitle();
    });
  }

  Future<void> _loadTitle() async {
    final title = await widget.metadata.title(widget.item.host);
    if (!mounted || title == null) {
      return;
    }
    setState(() => _title = title);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = widget.item;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _leading(scheme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: _hostHeight,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.host,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: _subtitleHeight,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: _subtitle(context, scheme),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _StatusBadge(
                  status: item.status,
                  certificateError: item.certificateError,
                  quick: widget.quick,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? _details(context)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: content,
    );
  }

  Widget _subtitle(BuildContext context, ColorScheme scheme) {
    final item = widget.item;
    final l10n = AppLocalizations.of(context);
    if (item.otherError) {
      return Text(
        _explanationText(l10n, item.status) ?? item.errorText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: scheme.error),
      );
    }
    if (_title != null) {
      return Text(
        _title!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: scheme.onSurfaceVariant),
      );
    }
    if (!item.done) {
      return Text(
        l10n.itemChecking,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: scheme.onSurfaceVariant),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _details(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = widget.item;
    final details = <Widget>[
      if (_title != null) _detailRow(context, l10n.detailTitle, _title!),
      _detailRow(context, l10n.detailStatus, _statusLabel(l10n, item.status)),
      _detailRow(context, l10n.detailHeat, Bucket(item.top).label),
    ];
    if (item.otherError) {
      details.add(_detailRow(context, l10n.detailMessage, item.errorText));
    } else if (item.done && item.detail.trim().isNotEmpty) {
      details.add(
        _detailRow(context, l10n.detailCertError, item.detail.trim()),
      );
    }
    final explanation = _explanationText(l10n, item.status);
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...details,
          if (explanation != null) _explanation(context, explanation),
        ],
      ),
    );
  }

  Widget _explanation(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  /// Spinner while running, a cross when blocked, the favicon or a globe
  /// otherwise.
  Widget _leading(ColorScheme scheme) {
    final item = widget.item;
    if (!item.done) {
      if (widget.paused) {
        return SizedBox(
          width: 24,
          height: 24,
          child: Icon(Icons.pause, size: 20, color: scheme.onSurfaceVariant),
        );
      }
      // A determinate ring (value set) rather than an indeterminate spinner:
      // each indeterminate indicator owns a ticker and repaints every frame,
      // which is expensive across many visible rows. The header progress bar
      // already conveys live progress.
      return const SizedBox(
        width: 24,
        height: 24,
        child: Padding(
          padding: EdgeInsets.all(4),
          child: CircularProgressIndicator(strokeWidth: 2, value: 0.75),
        ),
      );
    }
    if (item.status == CheckStatus.certificateError &&
        item.certificateError == 'expired') {
      return const SizedBox(
        width: 24,
        height: 24,
        child: Icon(Icons.warning_amber, size: 20, color: Color(0xFFF9A825)),
      );
    }
    if (widget.quick) {
      if (item.status == CheckStatus.fortinetBlocked) {
        return SizedBox(
          width: 24,
          height: 24,
          child: Icon(Icons.close, size: 20, color: scheme.error),
        );
      }
      if (item.status == CheckStatus.notFortinet) {
        return _Favicon(
          host: item.host,
          cache: widget.favicons,
          ready: _metadataReady,
        );
      }
      return const SizedBox(
        width: 24,
        height: 24,
        child: Icon(Icons.warning_amber, size: 20, color: Color(0xFFF9A825)),
      );
    }
    if (item.blocked || item.otherError) {
      return SizedBox(
        width: 24,
        height: 24,
        child: Icon(Icons.close, size: 20, color: scheme.error),
      );
    }
    return _Favicon(
      host: item.host,
      cache: widget.favicons,
      ready: _metadataReady,
    );
  }
}

class _Favicon extends StatefulWidget {
  const _Favicon({required this.host, required this.cache, this.ready = true});

  final String host;
  final FaviconCache cache;

  /// Whether the row has settled and the icon should actually be fetched.
  final bool ready;

  @override
  State<_Favicon> createState() => _FaviconState();
}

class _FaviconState extends State<_Favicon> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _Favicon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.host != widget.host) {
      _bytes = null;
      _load();
    } else if (!oldWidget.ready && widget.ready) {
      _load();
    }
  }

  void _load() {
    if (!widget.ready) {
      return;
    }
    final host = widget.host;
    if (widget.cache.isCached(host)) {
      _bytes = widget.cache.cached(host);
      return;
    }
    widget.cache.get(host).then((bytes) {
      if (!mounted || host != widget.host) {
        return;
      }
      setState(() => _bytes = bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = _globe(context);
    final bytes = _bytes;
    if (!widget.ready || bytes == null) {
      return SizedBox(width: 24, height: 24, child: placeholder);
    }
    return SizedBox(
      width: 24,
      height: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          bytes,
          width: 24,
          height: 24,
          cacheWidth: 48,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
      ),
    );
  }

  Widget _globe(BuildContext context) {
    return Icon(
      Icons.public,
      size: 20,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

String _statusLabel(AppLocalizations l10n, CheckStatus? status) {
  return switch (status) {
    null => l10n.statusChecking,
    CheckStatus.fortinetBlocked => l10n.statusBlocked,
    CheckStatus.notFortinet => l10n.statusNotBlocked,
    CheckStatus.certificateError => l10n.statusCertificateError,
    CheckStatus.dnsError => l10n.statusDnsError,
    CheckStatus.timeout => l10n.statusTimeout,
    CheckStatus.connectionRefused => l10n.statusConnectionRefused,
    CheckStatus.tlsOrNetworkError => l10n.statusNetworkError,
    CheckStatus.invalidInput => l10n.statusInvalidInput,
  };
}

bool _matchesStatus(ResultItem item, _StatusFilter filter) {
  final expired =
      item.status == CheckStatus.certificateError &&
      item.certificateError == 'expired';
  return switch (filter) {
    // An expired but reachable certificate still counts as accessible.
    _StatusFilter.reachable =>
      item.status == CheckStatus.notFortinet || expired,
    _StatusFilter.hdsbBlocked => item.blocked,
    _StatusFilter.expired => expired,
    _StatusFilter.unreachable => item.otherError && !expired,
    _StatusFilter.otherProblem => item.otherError,
  };
}

String? _explanationText(AppLocalizations l10n, CheckStatus? status) {
  return switch (status) {
    null => null,
    CheckStatus.notFortinet => l10n.explanationReachable,
    CheckStatus.fortinetBlocked => l10n.explanationBlocked,
    CheckStatus.dnsError => l10n.explanationDns,
    CheckStatus.timeout => l10n.explanationTimeout,
    CheckStatus.certificateError => l10n.explanationCertificate,
    _ => l10n.explanationUnreachable,
  };
}

/// A small solid-colored label showing the outcome with an icon: a green check
/// when accessible, a red cross when blocked or unreachable, and an amber
/// exclamation mark for DNS errors.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    this.certificateError = '',
    this.quick = false,
  });

  final CheckStatus? status;
  final String certificateError;
  final bool quick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final Color background;
    final Color foreground;
    final IconData icon;
    final String label;
    if (status == null) {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurfaceVariant;
      icon = Icons.autorenew;
      label = l10n.statusChecking;
    } else if (status == CheckStatus.fortinetBlocked) {
      background = const Color(0xFFC62828);
      foreground = Colors.white;
      icon = Icons.close;
      label = l10n.badgeBlocked;
    } else if (status == CheckStatus.notFortinet) {
      background = const Color(0xFF2E7D32);
      foreground = Colors.white;
      icon = Icons.check;
      label = l10n.badgeReachable;
    } else if (!quick &&
        status == CheckStatus.certificateError &&
        certificateError == 'expired') {
      background = const Color(0xFFF9A825);
      foreground = Colors.black87;
      icon = Icons.warning_amber;
      label = l10n.badgeCertificateExpired;
    } else if (quick) {
      // Quick mode only inspects the certificate issuer, so anything that did
      // not yield one means the certificate could not be checked.
      background = const Color(0xFFF9A825);
      foreground = Colors.black87;
      icon = Icons.help_outline;
      label = l10n.badgeCertUnavailable;
    } else {
      background = const Color(0xFFC62828);
      foreground = Colors.white;
      icon = Icons.close;
      label = l10n.badgeUnreachable;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

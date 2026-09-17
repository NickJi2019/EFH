import 'package:flutter/material.dart';

import '../../connectivity/radar.dart';
import '../../connectivity/result.dart';
import '../../l10n/app_localizations.dart';
import '../run_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_card.dart';
import '../widgets/section.dart';
import '../widgets/stacked_progress.dart';
import '../widgets/stat_grid.dart';

/// The probe configuration and live progress.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.controller});

  final RunController controller;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _workers;
  late final TextEditingController _timeout;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _workers = TextEditingController(text: c.workersText);
    _timeout = TextEditingController(text: c.timeoutText);
  }

  @override
  void dispose() {
    _workers.dispose();
    _timeout.dispose();
    super.dispose();
  }

  Future<void> _pickInputFile() async {
    final l10n = AppLocalizations.of(context);
    try {
      await widget.controller.pickInputFile();
    } catch (exception) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snackPickFailed('$exception'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final c = widget.controller;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          return Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppInsets.page,
                AppInsets.page,
                AppInsets.page,
                96,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.laptop,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusCard(c),
                    const SizedBox(height: AppInsets.gap),
                    _buildStatsBlock(c),
                    const SizedBox(height: AppInsets.gap),
                    _buildSourceBlock(c),
                    const SizedBox(height: AppInsets.gap),
                    _buildSettingsBlock(c),
                    if (c.error != null) ...[
                      const SizedBox(height: AppInsets.gap),
                      _buildErrorCard(c),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(RunController c) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final String state;
    if (c.warmingUp && c.statusMessage != null) {
      state = c.statusMessage!;
    } else if (c.cancelled) {
      state = l10n.stateCancelled;
    } else if (c.running && c.paused) {
      state = l10n.statePaused;
    } else if (c.running) {
      state = c.total > 0 ? l10n.stateRunning : l10n.statePreparing;
    } else if (c.error != null) {
      state = l10n.stateError;
    } else if (c.stats != null) {
      state = l10n.stateDone;
    } else {
      state = l10n.stateIdle;
    }
    return CommonCard(
      type: CommonCardType.filled,
      padding: const EdgeInsets.all(AppInsets.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (c.running) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  state,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: c.error != null ? scheme.error : null),
                ),
              ),
              if (c.running)
                Text(
                  l10n.ratePerSecond(c.rate.toStringAsFixed(0)),
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _StartupProgress(
            active: c.warmingUp,
            height: 8,
            child: StackedProgress(
              started: c.startedProgress,
              completed: c.completedProgress,
              height: 8,
              borderRadius: BorderRadius.circular(4),
              color: c.cancelled
                  ? scheme.error
                  : c.running && c.paused
                  ? scheme.onSurfaceVariant
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                l10n.progressCounter(
                  c.done,
                  c.total,
                  (c.progressValue * 100).toStringAsFixed(1),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  l10n.progressBreakdown(
                    c.stats?.notFortinet ?? 0,
                    c.stats?.fortinetBlocked ?? 0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: (c.stats?.fortinetBlocked ?? 0) > 0
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBlock(RunController c) {
    final l10n = AppLocalizations.of(context);
    return SettingsBlock(
      title: l10n.sourceTitle,
      icon: Icons.cloud_outlined,
      children: [
        SettingPadding(
          child: SegmentedButton<DataSource>(
            segments: [
              ButtonSegment(
                value: DataSource.radar,
                label: Text(l10n.sourceRadar),
                icon: const Icon(Icons.public),
              ),
              ButtonSegment(
                value: DataSource.local,
                label: Text(l10n.sourceLocal),
                icon: const Icon(Icons.insert_drive_file_outlined),
              ),
            ],
            selected: {c.source},
            onSelectionChanged: c.running
                ? null
                : (selection) => c.setSource(selection.first),
          ),
        ),
        if (c.source == DataSource.radar)
          SettingPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(l10n.listToCheck),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final bucket in rankingBuckets)
                      ChoiceChip(
                        label: Text(bucket.label),
                        selected: c.selectedTop == bucket.top,
                        onSelected: c.running
                            ? null
                            : (_) => c.setSelectedTop(bucket.top),
                      ),
                  ],
                ),
              ],
            ),
          )
        else
          SettingPadding(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    c.inputPath.isEmpty ? l10n.noFileSelected : c.inputPath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.inputPath.isEmpty
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: c.running ? null : _pickInputFile,
                  icon: const Icon(Icons.folder_open),
                  label: Text(l10n.actionChooseFile),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsBlock(RunController c) {
    final l10n = AppLocalizations.of(context);
    return SettingsBlock(
      title: l10n.paramsTitle,
      icon: Icons.tune,
      children: [
        SettingPadding(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _workers,
                  enabled: !c.running,
                  keyboardType: TextInputType.number,
                  onChanged: c.setWorkersText,
                  decoration: InputDecoration(labelText: l10n.workersLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _timeout,
                  enabled: !c.running,
                  keyboardType: TextInputType.number,
                  onChanged: c.setTimeoutText,
                  decoration: InputDecoration(labelText: l10n.timeoutLabel),
                ),
              ),
            ],
          ),
        ),
        SwitchListTile(
          title: Text(l10n.hdsbDetectionLabel),
          subtitle: Text(
            l10n.hdsbDetectionDesc,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          value: c.hdsbDetection,
          onChanged: c.running ? null : (value) => c.setHdsbDetection(value),
        ),
        if (c.hdsbDetection)
          SwitchListTile(
            title: Text(l10n.hdsbQuickCheckLabel),
            subtitle: Text(
              l10n.hdsbQuickCheckDesc,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            value: c.hdsbQuickCheck,
            onChanged: c.running ? null : (value) => c.setHdsbQuickCheck(value),
          ),
      ],
    );
  }

  Widget _buildErrorCard(RunController c) {
    final scheme = Theme.of(context).colorScheme;
    return CommonCard(
      isError: true,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              c.error!,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBlock(RunController c) {
    final l10n = AppLocalizations.of(context);
    final stats = c.stats ?? Stats();
    final quick = c.hdsbDetection && c.hdsbQuickCheck;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.statsTitle, icon: Icons.bar_chart),
        StatGrid(
          items: [
            StatItem(
              l10n.statTotal,
              stats.total,
              icon: Icons.format_list_numbered,
            ),
            StatItem(l10n.statProcessed, stats.processed, icon: Icons.check),
            StatItem(
              l10n.badgeReachable,
              stats.notFortinet,
              icon: Icons.check_circle_outline,
            ),
            StatItem(
              l10n.statHdsb,
              stats.fortinetBlocked,
              icon: Icons.block,
              highlight: stats.fortinetBlocked > 0,
            ),
            if (quick)
              StatItem(
                l10n.badgeOtherProblem,
                stats.certificateError + stats.failed,
                icon: Icons.warning_amber,
              )
            else ...[
              StatItem(
                l10n.statCertError,
                stats.certificateError,
                icon: Icons.lock_outline,
              ),
              StatItem(
                l10n.statFailed,
                stats.failed,
                icon: Icons.warning_amber,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

/// The startup list-check bar: a single soft bar slides across with eased
/// motion (Fluent style). When [active] goes false the bar finishes its pass
/// to the right before disappearing, instead of snapping away.
class _StartupProgress extends StatefulWidget {
  const _StartupProgress({
    required this.active,
    required this.child,
    this.height = 8,
  });

  final bool active;
  final Widget child;
  final double height;

  @override
  State<_StartupProgress> createState() => _StartupProgressState();
}

class _StartupProgressState extends State<_StartupProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _visible = true;
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _StartupProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      setState(() => _visible = true);
      _controller.repeat();
    } else if (!widget.active && oldWidget.active) {
      // Finish the current pass to the right, then hide.
      _controller.stop();
      _controller.animateTo(1.0, curve: Curves.easeInOut).whenComplete(() {
        if (mounted) {
          setState(() => _visible = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) {
      return widget.child;
    }
    final scheme = Theme.of(context).colorScheme;
    final track = scheme.surfaceContainerHighest;
    final bar = scheme.primary;
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.height / 2),
        child: ColoredBox(
          color: track,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final barWidth = width * 0.4;
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  // Ease-in-out gives the bar a non-linear, springy motion.
                  final eased = Curves.easeInOut.transform(_controller.value);
                  final left = -0.4 * width + eased * (width * 1.4);
                  return Stack(
                    children: [
                      Positioned(
                        left: left,
                        top: 0,
                        bottom: 0,
                        width: barWidth,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                track.withValues(alpha: 0),
                                bar,
                                track.withValues(alpha: 0),
                              ],
                              stops: const [0, 0.5, 1],
                            ),
                            borderRadius: BorderRadius.circular(
                              widget.height / 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

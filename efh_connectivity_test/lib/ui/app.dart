import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'pages/about_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/logs_page.dart';
import 'pages/settings_page.dart';
import 'run_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/update.dart';

/// The app shell: a navigation rail on wide screens and a bottom navigation
/// bar on narrow ones, with the pages kept alive in a non-swipeable
/// [PageView]. The layout follows FlClash's `AppSidebarContainer` +
/// `_HomeShell` structure.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.controller,
    this.autoCheckUpdates = true,
  });

  final RunController controller;

  /// Whether to check GitHub for a newer release on startup.
  final bool autoCheckUpdates;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _pageController = PageController();
  int _index = 0;
  bool _warmedUp = false;
  bool _updateChecked = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) {
      return;
    }
    setState(() => _index = index);
    _pageController.jumpToPage(index);
  }

  Widget _buildFab(AppLocalizations l10n) {
    final c = widget.controller;
    if (!c.running || c.cancelled) {
      return FloatingActionButton.extended(
        heroTag: 'start',
        onPressed: c.running ? null : c.start,
        icon: const Icon(Icons.play_arrow),
        label: Text(l10n.actionStart),
      );
    }
    if (!c.paused) {
      return FloatingActionButton.extended(
        heroTag: 'pause',
        onPressed: c.pause,
        icon: const Icon(Icons.pause),
        label: Text(l10n.actionPause),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: 'stop',
          onPressed: c.stop,
          icon: const Icon(Icons.close),
          label: Text(l10n.actionCancel),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.extended(
          heroTag: 'resume',
          onPressed: c.resume,
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.actionResume),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    widget.controller.l10n = l10n;
    if (!_warmedUp) {
      _warmedUp = true;
      if (widget.controller.autoWarmUp) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.controller.refreshLists();
        });
      }
    }
    if (!_updateChecked) {
      _updateChecked = true;
      if (widget.autoCheckUpdates && widget.controller.autoCheckUpdates) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await widget.controller.checkForUpdates();
          if (!context.mounted) {
            return;
          }
          if (widget.controller.shouldPromptForUpdate) {
            await showUpdateDialog(context, widget.controller);
          }
        });
      }
    }
    final destinations = [
      (
        icon: Icons.space_dashboard_outlined,
        selectedIcon: Icons.space_dashboard,
        label: l10n.navDashboard,
      ),
      (
        icon: Icons.article_outlined,
        selectedIcon: Icons.article,
        label: l10n.navLogs,
      ),
      (
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.navSettings,
      ),
      (
        icon: Icons.info_outline,
        selectedIcon: Icons.info,
        label: l10n.navAbout,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final mode = viewModeFor(constraints.maxWidth);
        final pages = PageView(
          key: ValueKey(mode),
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _index = index),
          children: [
            DashboardPage(controller: widget.controller),
            LogsPage(controller: widget.controller),
            SettingsPage(controller: widget.controller),
            AboutPage(controller: widget.controller),
          ],
        );
        // A layout-mode change rebuilds the PageView, which re-attaches the
        // controller at page 0; restore the currently selected page.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_pageController.hasClients) {
            return;
          }
          if (_pageController.page?.round() != _index) {
            _pageController.jumpToPage(_index);
          }
        });
        if (mode == ViewMode.mobile) {
          return Scaffold(
            body: pages,
            floatingActionButton: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) => _buildFab(AppLocalizations.of(context)),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
          );
        }
        return Scaffold(
          backgroundColor: scheme.surfaceContainer,
          floatingActionButton: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) => _buildFab(AppLocalizations.of(context)),
          ),
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  labelType: mode == ViewMode.desktop
                      ? NavigationRailLabelType.all
                      : NavigationRailLabelType.selected,
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
              ),
              VerticalDivider(width: 1, color: scheme.outlineVariant),
              Expanded(child: pages),
            ],
          ),
        );
      },
    );
  }
}

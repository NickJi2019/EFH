import 'package:flutter/material.dart';

import '../../connectivity/app_version.dart';
import '../../l10n/app_localizations.dart';
import '../open_url.dart';
import '../run_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_card.dart';
import '../widgets/section.dart';

/// Static information about the tool, plus a GitHub release update check.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key, required this.controller});

  final RunController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final principles = [
      (l10n.principleMethodTitle, l10n.principleMethodDesc),
      (l10n.principleCriteriaTitle, l10n.principleCriteriaDesc),
      (l10n.principleTrustTitle, l10n.principleTrustDesc),
      (l10n.principleSourceTitle, l10n.principleSourceDesc),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAbout)),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppInsets.page,
            8,
            AppInsets.page,
            16,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.laptop),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CommonCard(
                  type: CommonCardType.filled,
                  padding: const EdgeInsets.all(AppInsets.card),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.aboutTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.aboutSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppInsets.gap),
                SettingsBlock(
                  title: l10n.aboutPrinciples,
                  icon: Icons.help_outline,
                  children: [
                    for (final principle in principles)
                      SettingPadding(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              principle.$1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(principle.$2),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppInsets.gap),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => SettingsBlock(
                    title: l10n.updateTitle,
                    icon: Icons.system_update_alt,
                    children: [
                      SettingPadding(
                        child: Row(
                          children: [
                            Expanded(child: Text(l10n.updateCurrentVersion)),
                            Text(
                              'v$appVersion',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SettingPadding(child: _buildUpdateStatus(context, l10n)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateStatus(BuildContext context, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    if (controller.checkingUpdates) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, value: 0.75),
          ),
          const SizedBox(width: 12),
          Text(l10n.updateChecking),
        ],
      );
    }
    if (controller.updateAvailable) {
      final release = controller.latestRelease!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.new_releases_outlined,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l10n.updateAvailable} · ${release.tag}',
                  style: TextStyle(color: scheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => openExternalUrl(release.url),
              icon: const Icon(Icons.download),
              label: Text(l10n.updateDownload),
            ),
          ),
        ],
      );
    }
    final failed = controller.updateCheckFailed;
    final text = failed
        ? l10n.updateCheckFailed
        : (controller.updateCheckedAt != null
              ? l10n.updateUpToDate
              : l10n.updateNotChecked);
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: failed ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          onPressed: controller.checkForUpdates,
          child: Text(l10n.actionCheckUpdate),
        ),
      ],
    );
  }
}

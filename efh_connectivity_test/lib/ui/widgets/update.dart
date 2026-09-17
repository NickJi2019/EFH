import 'package:flutter/material.dart';

import '../../connectivity/app_version.dart';
import '../../l10n/app_localizations.dart';
import '../open_url.dart';
import '../run_controller.dart';

/// Shows the "new version available" dialog, including the release notes and
/// the actions: download, skip this version, or stop showing the prompt.
Future<void> showUpdateDialog(BuildContext context, RunController controller) {
  final release = controller.latestRelease;
  if (release == null) {
    return Future<void>.value();
  }
  return showDialog<void>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final scheme = Theme.of(context).colorScheme;
      final notes = release.notes.trim();
      return AlertDialog(
        title: Text(l10n.updateAvailable),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                        '${l10n.updateCurrentVersion} v$appVersion → '
                        '${release.tag}',
                        style: TextStyle(color: scheme.primary),
                      ),
                    ),
                  ],
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.updateReleaseNotes,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(notes),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.setUpdatePromptEnabled(false);
              Navigator.of(context).pop();
            },
            child: Text(l10n.updateNeverShow),
          ),
          TextButton(
            onPressed: () {
              controller.skipVersion(release.tag);
              Navigator.of(context).pop();
            },
            child: Text(l10n.updateSkipVersion),
          ),
          FilledButton.icon(
            onPressed: () {
              openExternalUrl(release.url);
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.download),
            label: Text(l10n.updateDownload),
          ),
        ],
      );
    },
  );
}

/// The inline update status and check button, shared by the About and Settings
/// pages.
class UpdateStatusTile extends StatelessWidget {
  const UpdateStatusTile({super.key, required this.controller});

  final RunController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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

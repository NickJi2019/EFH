import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../connectivity/doh_resolver.dart';
import '../../connectivity/radar.dart';
import '../../l10n/app_localizations.dart';
import '../run_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/section.dart';

/// Application settings: list update settings, interface language, and the
/// Cloudflare Radar token used when downloading lists directly.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final RunController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _cfToken;
  late final TextEditingController _dohUrl;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cfToken = TextEditingController(text: widget.controller.cfToken);
    _dohUrl = TextEditingController(text: widget.controller.customDohUrl);
  }

  @override
  void dispose() {
    _cfToken.dispose();
    _dohUrl.dispose();
    super.dispose();
  }

  String _dnsDescription(AppLocalizations l10n, DnsMode mode) => switch (mode) {
    DnsMode.system => l10n.dnsSystemDesc,
    DnsMode.cloudflare => l10n.dnsCloudflareDesc,
    DnsMode.custom => l10n.dnsCustomDesc,
  };

  String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  static const _seedColors = <Color>[
    Colors.deepPurple,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.red,
  ];

  Widget _colorSwatch(BuildContext context, RunController c, Color? color) {
    final scheme = Theme.of(context).colorScheme;
    final display = color ?? defaultSeedColor;
    final selected = c.seedColor == color;
    return Tooltip(
      message: color == null
          ? AppLocalizations.of(context).themeColorDefault
          : '',
      child: InkWell(
        onTap: () => c.setSeedColor(color),
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: display,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? scheme.onSurface : scheme.outlineVariant,
              width: selected ? 3 : 1,
            ),
          ),
          child: selected
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  static bool _isCustom(Color? seed) =>
      seed != null && !_seedColors.contains(seed);

  Widget _customSwatch(BuildContext context, RunController c) {
    final scheme = Theme.of(context).colorScheme;
    final custom = _isCustom(c.seedColor);
    return Tooltip(
      message: AppLocalizations.of(context).themeColorCustom,
      child: InkWell(
        onTap: () => _pickCustomColor(c, c.seedColor ?? defaultSeedColor),
        customBorder: const CircleBorder(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: custom ? c.seedColor : scheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: custom ? scheme.onSurface : scheme.outlineVariant,
              width: custom ? 3 : 1,
            ),
          ),
          child: Icon(
            Icons.colorize,
            size: 18,
            color: custom ? Colors.white : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomColor(RunController c, Color initial) async {
    var picked = initial;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.themeColorLabel),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initial,
            onColorChanged: (value) => picked = value,
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.dialogOk),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) {
      return;
    }
    c.setSeedColor(picked);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final c = widget.controller;
    final scheme = Theme.of(context).colorScheme;
    final updatedAt = c.listsUpdatedAt;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
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
                SettingsBlock(
                  title: l10n.updateSettingsTitle,
                  icon: Icons.cloud_sync_outlined,
                  children: [
                    SettingPadding(
                      child: SegmentedButton<RadarSource>(
                        segments: [
                          ButtonSegment(
                            value: RadarSource.efhServer,
                            label: Text(l10n.efhServer),
                            icon: const Icon(Icons.dns_outlined),
                          ),
                          ButtonSegment(
                            value: RadarSource.cloudflare,
                            label: Text(l10n.cloudflareDirect),
                            icon: const Icon(Icons.cloud_outlined),
                          ),
                        ],
                        selected: {c.radarSource},
                        onSelectionChanged: c.warmingUp
                            ? null
                            : (selection) => c.setRadarSource(selection.first),
                      ),
                    ),
                    if (c.radarSource == RadarSource.efhServer)
                      SettingPadding(
                        child: Row(
                          children: [
                            Icon(
                              Icons.link,
                              size: 18,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                efhServerBaseUrl,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SettingPadding(
                        child: TextField(
                          controller: _cfToken,
                          onChanged: c.setCfToken,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: l10n.cfTokenLabel,
                            hintText: l10n.cfTokenHint,
                          ),
                        ),
                      ),
                    SettingPadding(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.warmingUp
                                  ? l10n.updating
                                  : updatedAt == null
                                  ? l10n.neverUpdated
                                  : l10n.lastUpdated(_formatTime(updatedAt)),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                          if (c.warmingUp) ...[
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: c.listUpdateProgress,
                                  minHeight: 4,
                                  backgroundColor:
                                      scheme.surfaceContainerHighest,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 12),
                          FilledButton.tonalIcon(
                            onPressed: c.warmingUp
                                ? null
                                : () => c.refreshLists(force: true),
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.updateNow),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppInsets.gap),
                SettingsBlock(
                  title: l10n.dnsTitle,
                  icon: Icons.travel_explore,
                  children: [
                    SettingPadding(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<DnsMode>(
                            initialValue: c.dnsMode,
                            decoration: InputDecoration(
                              labelText: l10n.dnsTitle,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: DnsMode.system,
                                child: Text(l10n.dnsSystem),
                              ),
                              DropdownMenuItem(
                                value: DnsMode.cloudflare,
                                child: Text(l10n.dnsCloudflare),
                              ),
                              DropdownMenuItem(
                                value: DnsMode.custom,
                                child: Text(l10n.dnsCustom),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                c.setDnsMode(value);
                              }
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _dnsDescription(l10n, c.dnsMode),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    if (c.dnsMode == DnsMode.custom)
                      SettingPadding(
                        child: TextField(
                          controller: _dohUrl,
                          onChanged: c.setCustomDohUrl,
                          autocorrect: false,
                          enableSuggestions: false,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: l10n.dnsCustomUrlLabel,
                            hintText: l10n.dnsCustomUrlHint,
                            errorText:
                                c.customDohUrl.trim().isNotEmpty &&
                                    !RunController.isValidDohUrl(c.customDohUrl)
                                ? l10n.validationDohUrl
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppInsets.gap),
                SettingsBlock(
                  title: l10n.languageTitle,
                  icon: Icons.translate,
                  children: [
                    SettingPadding(
                      child: DropdownButtonFormField<String>(
                        initialValue: c.locale?.languageCode ?? 'system',
                        decoration: InputDecoration(
                          labelText: l10n.languageTitle,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'system',
                            child: Text(l10n.languageSystem),
                          ),
                          DropdownMenuItem(
                            value: 'zh',
                            child: Text(l10n.languageChinese),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text(l10n.languageEnglish),
                          ),
                        ],
                        onChanged: (value) {
                          c.setLocale(
                            value == null || value == 'system'
                                ? null
                                : Locale(value),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppInsets.gap),
                SettingsBlock(
                  title: l10n.themeTitle,
                  icon: Icons.palette_outlined,
                  children: [
                    SwitchListTile(
                      title: Text(l10n.themeFollowSystem),
                      value: c.followSystemColor,
                      onChanged: c.supportsSystemColor
                          ? (value) => c.setFollowSystemColor(value)
                          : null,
                    ),
                    SwitchListTile(
                      title: Text(l10n.themeFollowSystemDark),
                      value: c.followSystemDark,
                      onChanged: (value) => c.setFollowSystemDark(value),
                    ),
                    if (!c.followSystemDark)
                      SwitchListTile(
                        title: Text(l10n.themeDarkMode),
                        value: c.darkMode,
                        onChanged: (value) => c.setDarkMode(value),
                      ),
                    SettingPadding(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.themeColorLabel,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Opacity(
                            opacity: c.followSystemColor ? 0.4 : 1,
                            child: IgnorePointer(
                              ignoring: c.followSystemColor,
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _colorSwatch(context, c, null),
                                  for (final color in _seedColors)
                                    _colorSwatch(context, c, color),
                                  _customSwatch(context, c),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

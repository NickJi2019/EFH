import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'ui/app.dart';
import 'ui/run_controller.dart';
import 'ui/theme/app_theme.dart';

void main() {
  runApp(const EfhConnectivityApp());
}

/// The EFH connectivity test: probes the TLS certificate presented by each
/// domain and detects Fortinet-issued interception certificates.
class EfhConnectivityApp extends StatefulWidget {
  const EfhConnectivityApp({
    super.key,
    this.initialLocale,
    this.warmUp = true,
    this.checkUpdates = true,
  });

  /// Overrides the interface locale; null follows the system locale.
  final Locale? initialLocale;

  /// Whether to refresh the cached Top-N lists on startup.
  final bool warmUp;

  /// Whether to check GitHub for a newer release on startup.
  final bool checkUpdates;

  @override
  State<EfhConnectivityApp> createState() => _EfhConnectivityAppState();
}

class _EfhConnectivityAppState extends State<EfhConnectivityApp> {
  late final RunController _controller = RunController(
    initialLocale: widget.initialLocale,
    autoWarmUp: widget.warmUp,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            final seed = _controller.seedColor ?? defaultSeedColor;
            final follow = _controller.followSystemColor;
            final lightScheme = (follow && lightDynamic != null)
                ? lightDynamic
                : ColorScheme.fromSeed(seedColor: seed);
            final darkScheme = (follow && darkDynamic != null)
                ? darkDynamic
                : ColorScheme.fromSeed(
                    seedColor: seed,
                    brightness: Brightness.dark,
                  );
            return MaterialApp(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).appTitle,
              debugShowCheckedModeBanner: false,
              theme: buildAppThemeFromScheme(lightScheme),
              darkTheme: buildAppThemeFromScheme(darkScheme),
              themeMode: _controller.resolvedThemeMode,
              locale: _controller.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AppShell(
                controller: _controller,
                autoCheckUpdates: widget.checkUpdates,
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

/// Screens are laid out for one of three widths, following FlClash's
/// breakpoints: a bottom navigation bar on [ViewMode.mobile], a navigation
/// rail otherwise.
abstract final class AppBreakpoints {
  static const double mobile = 600;
  static const double laptop = 840;
}

enum ViewMode { mobile, laptop, desktop }

ViewMode viewModeFor(double width) {
  if (width <= AppBreakpoints.mobile) {
    return ViewMode.mobile;
  }
  if (width <= AppBreakpoints.laptop) {
    return ViewMode.laptop;
  }
  return ViewMode.desktop;
}

/// Corner radii and spacing used across the app.
abstract final class AppCorner {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
}

abstract final class AppInsets {
  static const double page = 16;
  static const double card = 16;
  static const double gap = 16;
}

/// The fallback accent when the system provides no dynamic color.
const defaultSeedColor = Color(0xFFDE937E);

ThemeData buildAppTheme({Color? seedColor, bool dark = false}) {
  return buildAppThemeFromScheme(
    ColorScheme.fromSeed(
      seedColor: seedColor ?? defaultSeedColor,
      brightness: dark ? Brightness.dark : Brightness.light,
    ),
  );
}

ThemeData buildAppThemeFromScheme(ColorScheme scheme) {
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppCorner.sm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppCorner.sm),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppCorner.sm),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.surfaceContainerHighest,
      space: 1,
      thickness: 1,
    ),
  );
}

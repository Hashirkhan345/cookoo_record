import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';

class VideoFeatureTheme {
  const VideoFeatureTheme._();

  static const String fontFamily = 'Roboto';

  static const Color ink = Color(0xFF171A24);
  static const Color canvas = Color(0xFFF7F3EC);
  static const Color canvasShade = Color(0xFFECE3D7);
  static const Color primary = Color(0xFF3E63F4);
  static const Color primaryDeep = Color(0xFF2D4ACD);
  static const Color muted = Color(0xFF6D6A73);
  static const Color panel = Color(0xFFFFFCF7);
  static const Color panelMuted = Color(0xFFF4EEE4);
  static const Color line = Color(0xFFE3D8C8);
  static const Color lineStrong = Color(0xFFD1C1AD);
  static const Color success = Color(0xFF1D8A6B);
  static const Color accent = Color(0xFF182033);
  static const Color accentSoft = Color(0xFFE7ECFB);
  static const Color focus = Color(0xFF6F8CFF);
  static const Color danger = Color(0xFFBF5845);

  static const LinearGradient screenBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFF8F4EE), Color(0xFFF4EEE5), Color(0xFFFCFAF6)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF181F32), Color(0xFF233459), Color(0xFF3750A0)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primaryDeep, primary, focus],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF24304D), accent],
  );

  static const List<BoxShadow> panelShadow = <BoxShadow>[
    BoxShadow(color: Color(0x171F1B14), blurRadius: 38, offset: Offset(0, 24)),
  ];

  static const List<BoxShadow> floatingShadow = <BoxShadow>[
    BoxShadow(color: Color(0x121F1B14), blurRadius: 26, offset: Offset(0, 16)),
  ];

  static const List<BoxShadow> glowShadow = <BoxShadow>[
    BoxShadow(color: Color(0x243E63F4), blurRadius: 32, offset: Offset(0, 14)),
  ];

  static const Color darkInk = Color(0xFFF5F7FB);
  static const Color darkCanvas = Color(0xFF0F131A);
  static const Color darkCanvasShade = Color(0xFF161C26);
  static const Color darkMuted = Color(0xFFAAB4C3);
  static const Color darkPanel = Color(0xFF171D27);
  static const Color darkPanelMuted = Color(0xFF1F2835);
  static const Color darkLine = Color(0xFF2D394B);
  static const Color darkLineStrong = Color(0xFF42536A);
  static const Color darkAccent = Color(0xFFF5F7FB);
  static const Color darkAccentSoft = Color(0xFF24324A);
  static const Color darkDanger = Color(0xFFE17F6E);

  static const LinearGradient darkScreenBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF0F131A), Color(0xFF121926), Color(0xFF0C1017)],
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF182033), Color(0xFF203355), Color(0xFF3559D7)],
  );

  static TextTheme buildTextTheme(TextTheme base) {
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
            height: 1.02,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
            height: 1.05,
          ),
          displaySmall: base.displaySmall?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            height: 1.08,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            height: 1.08,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.12,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.16,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.2,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            height: 1.22,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            height: 1.24,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            height: 1.55,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            height: 1.55,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontFamily: fontFamily,
            color: muted,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            height: 1.5,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontFamily: fontFamily,
            color: muted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        )
        .apply(bodyColor: ink, displayColor: ink);
  }

  static ThemeData buildTheme({required Brightness brightness}) {
    final bool isDark = brightness == Brightness.dark;
    final ThemeData baseTheme = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: isDark ? darkPanel : panel,
    );

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? darkCanvas : canvas,
      pageTransitionsTheme: AppRouter.pageTransitionsTheme,
      dividerColor: isDark ? darkLine : line,
      textTheme: buildTextThemeFor(baseTheme.textTheme, isDark: isDark),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? darkPanel : ink,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? darkInk : ink,
          side: BorderSide(color: isDark ? darkLine : line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: (isDark ? darkPanelMuted : panelMuted).withValues(
          alpha: 0.7,
        ),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: isDark ? darkMuted : muted,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: isDark ? darkLine : line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: isDark ? darkLine : line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: isDark ? darkDanger : danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: isDark ? darkDanger : danger,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  static TextTheme buildTextThemeFor(TextTheme base, {required bool isDark}) {
    final Color bodyColor = isDark ? darkInk : ink;
    final Color mutedColor = isDark ? darkMuted : muted;
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontFamily: fontFamily,
            color: bodyColor,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
            height: 1.02,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontFamily: fontFamily,
            color: bodyColor,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
            height: 1.05,
          ),
          displaySmall: base.displaySmall?.copyWith(
            fontFamily: fontFamily,
            color: bodyColor,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            height: 1.08,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontFamily: fontFamily,
            color: bodyColor,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            height: 1.08,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontFamily: fontFamily,
            color: bodyColor,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.12,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontFamily: fontFamily,
            color: bodyColor,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            height: 1.16,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontFamily: fontFamily,
            color: bodyColor,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.2,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontFamily: fontFamily,
            color: bodyColor,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            height: 1.22,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontFamily: fontFamily,
            color: bodyColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            height: 1.24,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontFamily: fontFamily,
            color: bodyColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            height: 1.55,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontFamily: fontFamily,
            color: bodyColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            height: 1.55,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontFamily: fontFamily,
            color: mutedColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            height: 1.5,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontFamily: fontFamily,
            color: bodyColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontFamily: fontFamily,
            color: bodyColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontFamily: fontFamily,
            color: mutedColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        )
        .apply(bodyColor: bodyColor, displayColor: bodyColor);
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color inkFor(BuildContext context) => isDark(context) ? darkInk : ink;

  static Color canvasFor(BuildContext context) =>
      isDark(context) ? darkCanvas : canvas;

  static Color canvasShadeFor(BuildContext context) =>
      isDark(context) ? darkCanvasShade : canvasShade;

  static Color mutedFor(BuildContext context) =>
      isDark(context) ? darkMuted : muted;

  static Color panelFor(BuildContext context) =>
      isDark(context) ? darkPanel : panel;

  static Color panelMutedFor(BuildContext context) =>
      isDark(context) ? darkPanelMuted : panelMuted;

  static Color lineFor(BuildContext context) =>
      isDark(context) ? darkLine : line;

  static Color lineStrongFor(BuildContext context) =>
      isDark(context) ? darkLineStrong : lineStrong;

  static Color accentFor(BuildContext context) =>
      isDark(context) ? darkAccent : accent;

  static Color accentSoftFor(BuildContext context) =>
      isDark(context) ? darkAccentSoft : accentSoft;

  static Color dangerFor(BuildContext context) =>
      isDark(context) ? darkDanger : danger;

  static LinearGradient screenBackgroundFor(BuildContext context) =>
      isDark(context) ? darkScreenBackground : screenBackground;

  static LinearGradient heroGradientFor(BuildContext context) =>
      isDark(context) ? darkHeroGradient : heroGradient;
}

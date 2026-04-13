import 'package:flutter/material.dart';

class VideoFeatureTheme {
  const VideoFeatureTheme._();

  static const String fontFamily = 'Roboto';

  static const Color ink = Color(0xFF1F2A1F);
  static const Color canvas = Color(0xFFF6FAF4);
  static const Color canvasShade = Color(0xFFE7F2E2);
  static const Color primary = Color(0xFF14A800);
  static const Color primaryDeep = Color(0xFF0F7A00);
  static const Color muted = Color(0xFF667364);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color panelMuted = Color(0xFFF0F7EB);
  static const Color line = Color(0xFFD6E4D2);
  static const Color lineStrong = Color(0xFFB6CCAF);
  static const Color success = Color(0xFF108A00);
  static const Color accent = Color(0xFF13544E);
  static const Color accentSoft = Color(0xFFDDEEEA);
  static const Color focus = Color(0xFF6FDA44);
  static const Color danger = Color(0xFFB24B37);

  static const LinearGradient screenBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFF7FBF5), Color(0xFFEAF4E6), Color(0xFFFDFEFC)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF0E3B34), Color(0xFF13544E), Color(0xFF1A6E59)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primaryDeep, primary, focus],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1A6E59), accent],
  );

  static const List<BoxShadow> panelShadow = <BoxShadow>[
    BoxShadow(color: Color(0x1D2A312A), blurRadius: 38, offset: Offset(0, 24)),
  ];

  static const List<BoxShadow> floatingShadow = <BoxShadow>[
    BoxShadow(color: Color(0x182A312A), blurRadius: 26, offset: Offset(0, 16)),
  ];

  static const List<BoxShadow> glowShadow = <BoxShadow>[
    BoxShadow(color: Color(0x2614A800), blurRadius: 32, offset: Offset(0, 14)),
  ];

  static TextTheme buildTextTheme(TextTheme base) {
    return base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.8,
            height: 1.02,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
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
            letterSpacing: -0.8,
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
            letterSpacing: -0.1,
            height: 1.5,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontFamily: fontFamily,
            color: ink,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            height: 1.52,
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontFamily: fontFamily,
            color: muted,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            height: 1.45,
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
}

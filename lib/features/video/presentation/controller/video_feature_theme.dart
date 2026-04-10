import 'package:flutter/material.dart';

class VideoFeatureTheme {
  const VideoFeatureTheme._();

  static const Color ink = Color(0xFF1C3137);
  static const Color canvas = Color(0xFFF8F1E6);
  static const Color canvasShade = Color(0xFFE1EFE8);
  static const Color primary = Color(0xFF147A73);
  static const Color primaryDeep = Color(0xFF0A5552);
  static const Color muted = Color(0xFF6B7774);
  static const Color panel = Color(0xFFFFFCF7);
  static const Color panelMuted = Color(0xFFF3E7D7);
  static const Color line = Color(0xFFE2D5C2);
  static const Color lineStrong = Color(0xFFD0BEA0);
  static const Color success = Color(0xFF2D8B57);
  static const Color accent = Color(0xFFF56F45);
  static const Color accentSoft = Color(0xFFFFE0D4);
  static const Color focus = Color(0xFFE8BC67);
  static const Color danger = Color(0xFFB24B37);

  static const LinearGradient screenBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFBF4EA), Color(0xFFE6F1EA), Color(0xFFFFFBF6)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF14373A), Color(0xFF1B5E5A), Color(0xFF2B8A74)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primaryDeep, primary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFF8A66), accent],
  );

  static const List<BoxShadow> panelShadow = <BoxShadow>[
    BoxShadow(color: Color(0x1D2A312A), blurRadius: 38, offset: Offset(0, 24)),
  ];

  static const List<BoxShadow> floatingShadow = <BoxShadow>[
    BoxShadow(color: Color(0x182A312A), blurRadius: 26, offset: Offset(0, 16)),
  ];

  static const List<BoxShadow> glowShadow = <BoxShadow>[
    BoxShadow(color: Color(0x26F56F45), blurRadius: 32, offset: Offset(0, 14)),
  ];
}

import 'package:flutter/material.dart';

class VideoFeatureTheme {
  const VideoFeatureTheme._();

  static const Color ink = Color(0xFF181D33);
  static const Color canvas = Color(0xFFF5F7FB);
  static const Color canvasShade = Color(0xFFE9EEF7);
  static const Color primary = Color(0xFF1D63E8);
  static const Color muted = Color(0xFF6E7487);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFD8DFEB);
  static const Color success = Color(0xFF1E9158);
  static const Color accent = Color(0xFFFF623B);

  static const LinearGradient screenBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[canvas, canvasShade],
  );
}

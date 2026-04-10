import 'package:flutter/material.dart';

import '../controller/video_feature_theme.dart';

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, required this.brandLabel});

  final String brandLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const BrandMark(size: 40),
        const SizedBox(width: 12),
        Text(
          brandLabel,
          style: const TextStyle(
            color: VideoFeatureTheme.ink,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.9,
          ),
        ),
      ],
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 34});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: VideoFeatureTheme.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.34),
        boxShadow: VideoFeatureTheme.floatingShadow,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.22),
            ),
          ),
          Positioned(
            left: size * 0.15,
            top: size * 0.18,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: VideoFeatureTheme.focus,
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.92),
                width: size * 0.08,
              ),
              borderRadius: BorderRadius.circular(size * 0.26),
            ),
          ),
          Positioned(
            right: size * 0.16,
            bottom: size * 0.14,
            child: Container(
              width: size * 0.18,
              height: size * 0.18,
              decoration: BoxDecoration(
                color: VideoFeatureTheme.accent,
                borderRadius: BorderRadius.circular(size),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

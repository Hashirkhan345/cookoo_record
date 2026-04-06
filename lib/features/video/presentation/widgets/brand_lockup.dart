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
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
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
        color: VideoFeatureTheme.primary,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: size * 0.16,
            height: size * 0.78,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size),
            ),
          ),
          Container(
            width: size * 0.78,
            height: size * 0.16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size),
            ),
          ),
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: size * 0.085),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

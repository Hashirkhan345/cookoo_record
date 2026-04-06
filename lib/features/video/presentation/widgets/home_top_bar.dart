import 'package:flutter/material.dart';

import '../controller/video_feature_theme.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: VideoFeatureTheme.line),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.search_rounded, color: VideoFeatureTheme.muted),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Search videos, spaces, or teammates',
                    style: TextStyle(
                      color: VideoFeatureTheme.muted,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        if (isDesktop)
          Container(
            width: 126,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: VideoFeatureTheme.line),
            ),
            child: const Center(
              child: Text(
                'Workspace',
                style: TextStyle(
                  color: VideoFeatureTheme.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        if (isDesktop) const SizedBox(width: 16),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.98),
            shape: BoxShape.circle,
            border: Border.all(color: VideoFeatureTheme.line),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x100B1326),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'H',
              style: TextStyle(
                color: VideoFeatureTheme.ink,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

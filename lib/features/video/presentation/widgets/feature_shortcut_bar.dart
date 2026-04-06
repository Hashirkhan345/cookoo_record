import 'package:flutter/material.dart';

import '../../data/enums/video_shortcut_type.dart';
import '../../data/models/video_shortcut_model.dart';
import '../controller/video_feature_theme.dart';

class FeatureShortcutBar extends StatelessWidget {
  const FeatureShortcutBar({super.key, required this.shortcuts});

  final List<VideoShortcutModel> shortcuts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 28,
      runSpacing: 16,
      children: shortcuts
          .map(
            (shortcut) => Container(
              width: 180,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: VideoFeatureTheme.line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    _iconForShortcut(shortcut.type),
                    size: 30,
                    color: VideoFeatureTheme.ink,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    shortcut.label,
                    style: const TextStyle(
                      color: VideoFeatureTheme.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  IconData _iconForShortcut(VideoShortcutType type) {
    switch (type) {
      case VideoShortcutType.brainstorm:
        return Icons.psychology_alt_outlined;
      case VideoShortcutType.build:
        return Icons.handyman_outlined;
      case VideoShortcutType.narrate:
        return Icons.mic_none_rounded;
    }
  }
}

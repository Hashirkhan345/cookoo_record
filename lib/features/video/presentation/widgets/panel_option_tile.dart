import 'package:flutter/material.dart';

import '../../data/enums/video_recording_mode.dart';
import '../../data/enums/video_recording_option_kind.dart';
import '../../data/models/video_recording_option_model.dart';
import '../controller/video_feature_theme.dart';

class PanelOptionTile extends StatelessWidget {
  const PanelOptionTile({super.key, required this.option, this.onTap});

  final VideoRecordingOptionModel option;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = onTap != null;
    final bool isHighlighted = option.highlighted;
    final Widget content = Container(
      key: Key('panelOption_${option.kind.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: isHighlighted
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  VideoFeatureTheme.panelMuted.withValues(alpha: 0.92),
                  Colors.white,
                ],
              )
            : null,
        color: isHighlighted ? null : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHighlighted
              ? VideoFeatureTheme.lineStrong
              : VideoFeatureTheme.line,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? VideoFeatureTheme.primary.withValues(alpha: 0.12)
                  : VideoFeatureTheme.panelMuted.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _iconForKind(option.kind),
              color: isHighlighted
                  ? VideoFeatureTheme.primaryDeep
                  : VideoFeatureTheme.ink,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _titleForKind(option.kind),
                  style: const TextStyle(
                    color: VideoFeatureTheme.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: VideoFeatureTheme.ink,
                    fontSize: 17,
                    fontWeight: isHighlighted
                        ? FontWeight.w800
                        : FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (option.status != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: VideoFeatureTheme.success,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                option.status!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            )
          else if (isInteractive)
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: VideoFeatureTheme.muted,
              size: 24,
            ),
        ],
      ),
    );

    if (!isInteractive) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap!(),
        borderRadius: BorderRadius.circular(24),
        child: content,
      ),
    );
  }

  String _titleForKind(VideoRecordingOptionKind kind) {
    switch (kind) {
      case VideoRecordingOptionKind.display:
        return 'Capture mode';
      case VideoRecordingOptionKind.camera:
        return 'Camera';
      case VideoRecordingOptionKind.microphone:
        return 'Microphone';
    }
  }

  IconData _iconForKind(VideoRecordingOptionKind kind) {
    final VideoRecordingMode? selectedRecordingMode =
        option.selectedRecordingMode;
    if (selectedRecordingMode != null) {
      switch (selectedRecordingMode) {
        case VideoRecordingMode.fullScreen:
          return Icons.desktop_windows_outlined;
        case VideoRecordingMode.window:
          return Icons.crop_square_rounded;
        case VideoRecordingMode.currentTab:
          return Icons.web_asset_outlined;
        case VideoRecordingMode.cameraOnly:
          return Icons.videocam_outlined;
      }
    }

    switch (kind) {
      case VideoRecordingOptionKind.display:
        return Icons.desktop_windows_outlined;
      case VideoRecordingOptionKind.camera:
        return Icons.videocam_outlined;
      case VideoRecordingOptionKind.microphone:
        return Icons.mic_none_rounded;
    }
  }
}

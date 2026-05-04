import 'package:flutter/material.dart';

import '../../data/enums/video_recording_mode.dart';
import '../../data/enums/video_recording_option_kind.dart';
import '../../data/models/video_recording_option_model.dart';
import '../controller/video_feature_theme.dart';

class PanelOptionTile extends StatelessWidget {
  const PanelOptionTile({
    super.key,
    required this.option,
    this.onTap,
    this.onStatusTap,
  });

  final VideoRecordingOptionModel option;
  final Future<void> Function()? onTap;
  final Future<void> Function()? onStatusTap;

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = onTap != null;
    final bool isHighlighted = option.highlighted;
    final bool isDark = VideoFeatureTheme.isDark(context);
    final bool isEnabledStatus = option.status == 'On';
    final Widget content = Container(
      key: Key('panelOption_${option.kind.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? VideoFeatureTheme.panelMutedFor(
                context,
              ).withValues(alpha: isDark ? 0.96 : 0.92)
            : VideoFeatureTheme.panelFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlighted
              ? VideoFeatureTheme.lineStrongFor(context)
              : VideoFeatureTheme.lineFor(context),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? VideoFeatureTheme.primary.withValues(alpha: 0.12)
                  : VideoFeatureTheme.panelMutedFor(
                      context,
                    ).withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _iconForKind(option.kind),
              color: isHighlighted
                  ? VideoFeatureTheme.primaryDeep
                  : VideoFeatureTheme.inkFor(context),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _titleForKind(option.kind),
                  style: TextStyle(
                    color: VideoFeatureTheme.mutedFor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: VideoFeatureTheme.inkFor(context),
                    fontSize: 15,
                    fontWeight: isHighlighted
                        ? FontWeight.w800
                        : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (option.status != null)
            _StatusButton(
              label: option.status!,
              isEnabled: isEnabledStatus,
              isInteractive: onStatusTap != null,
              onTap: onStatusTap,
            )
          else if (isInteractive)
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: VideoFeatureTheme.mutedFor(context),
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
        borderRadius: BorderRadius.circular(18),
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

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.isEnabled,
    required this.isInteractive,
    required this.onTap,
  });

  final String label;
  final bool isEnabled;
  final bool isInteractive;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 54,
      height: 34,
      decoration: BoxDecoration(
        color: isEnabled
            ? VideoFeatureTheme.primary
            : VideoFeatureTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isEnabled
              ? VideoFeatureTheme.primary
              : VideoFeatureTheme.primary.withValues(alpha: 0.24),
        ),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isEnabled ? Colors.white : VideoFeatureTheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );

    if (!isInteractive) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap?.call(),
        borderRadius: BorderRadius.circular(999),
        child: child,
      ),
    );
  }
}

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
    final Widget content = Container(
      key: Key('panelOption_${option.kind.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(22),
        border: option.highlighted
            ? const Border(
                bottom: BorderSide(color: Color(0xFFD2E2FF), width: 6),
              )
            : null,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            _iconForKind(option.kind),
            color: VideoFeatureTheme.ink,
            size: 30,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: VideoFeatureTheme.ink,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (option.status != null) ...<Widget>[
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: VideoFeatureTheme.success,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                option.status!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap!();
        },
        borderRadius: BorderRadius.circular(22),
        child: content,
      ),
    );
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

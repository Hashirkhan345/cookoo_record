import 'package:flutter/material.dart';

import '../../data/enums/video_recording_mode.dart';
import '../../data/enums/video_recording_option_kind.dart';
import '../../data/models/video_recording_option_model.dart';
import '../controller/video_feature_theme.dart';
import 'brand_lockup.dart';
import 'panel_option_tile.dart';

class RecorderPanel extends StatelessWidget {
  const RecorderPanel({
    super.key,
    required this.brandLabel,
    required this.options,
    required this.statusLabel,
    required this.recordingLimitLabel,
    required this.tutorialLabel,
    required this.onClose,
    required this.onSelectRecordingMode,
    required this.selectedRecordingMode,
    required this.onStartRecording,
    required this.isRecordingActive,
    required this.isBusy,
  });

  final String brandLabel;
  final List<VideoRecordingOptionModel> options;
  final String statusLabel;
  final String recordingLimitLabel;
  final String tutorialLabel;
  final Future<void> Function() onClose;
  final Future<void> Function(VideoRecordingMode mode) onSelectRecordingMode;
  final VideoRecordingMode selectedRecordingMode;
  final Future<void> Function() onStartRecording;
  final bool isRecordingActive;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final bool isCompact = MediaQuery.sizeOf(context).width < 1040;
    final double width = isCompact ? 420 : 380;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: width,
        minWidth: isCompact ? 0 : width,
      ),
      child: Container(
        key: const Key('recordingPanel'),
        decoration: BoxDecoration(
          color: VideoFeatureTheme.panel,
          borderRadius: BorderRadius.circular(38),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x250B1326),
              blurRadius: 42,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(38),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(child: BrandLockup(brandLabel: brandLabel)),
                          const SizedBox(width: 12),
                          _PanelIconButton(
                            icon: Icons.close_rounded,
                            onPressed: onClose,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      for (
                        int index = 0;
                        index < options.length;
                        index++
                      ) ...<Widget>[
                        if (index > 0) const SizedBox(height: 14),
                        Builder(
                          builder: (BuildContext tileContext) {
                            final VideoRecordingOptionModel option =
                                options[index];
                            return PanelOptionTile(
                              option: option,
                              onTap:
                                  option.kind ==
                                          VideoRecordingOptionKind.display &&
                                      !isRecordingActive &&
                                      !isBusy
                                  ? () => _showRecordingModeMenu(tileContext)
                                  : null,
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 28),
                      FilledButton(
                        key: const Key('startRecordingButton'),
                        onPressed: isRecordingActive || isBusy
                            ? null
                            : () => onStartRecording(),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(70),
                          backgroundColor: VideoFeatureTheme.accent,
                          disabledBackgroundColor: VideoFeatureTheme.muted,
                          disabledForegroundColor: Colors.white,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: Text(statusLabel),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        recordingLimitLabel,
                        style: const TextStyle(
                          color: VideoFeatureTheme.muted,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: const Color(0xFFEAF1FB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 22,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          tutorialLabel,
                          style: const TextStyle(
                            color: VideoFeatureTheme.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.arrow_forward,
                        color: VideoFeatureTheme.ink,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRecordingModeMenu(BuildContext context) async {
    final List<VideoRecordingMode> supportedModes =
        supportedRecordingModesForCurrentPlatform();
    if (supportedModes.length <= 1) {
      return;
    }

    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final VideoRecordingMode? selectedMode = await showMenu<VideoRecordingMode>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      color: Colors.white,
      items: supportedModes
          .map((VideoRecordingMode mode) {
            return PopupMenuItem<VideoRecordingMode>(
              value: mode,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: <Widget>[
                  Icon(
                    _iconForMode(mode),
                    color: VideoFeatureTheme.ink,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mode.label,
                      style: const TextStyle(
                        color: VideoFeatureTheme.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (mode == selectedRecordingMode) ...<Widget>[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: VideoFeatureTheme.primary,
                      size: 22,
                    ),
                  ],
                ],
              ),
            );
          })
          .toList(growable: false),
    );

    if (selectedMode == null || selectedMode == selectedRecordingMode) {
      return;
    }

    await onSelectRecordingMode(selectedMode);
  }

  IconData _iconForMode(VideoRecordingMode mode) {
    switch (mode) {
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
}

class _PanelIconButton extends StatelessWidget {
  const _PanelIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onPressed(),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: VideoFeatureTheme.line),
          ),
          child: Icon(icon, color: VideoFeatureTheme.ink, size: 24),
        ),
      ),
    );
  }
}

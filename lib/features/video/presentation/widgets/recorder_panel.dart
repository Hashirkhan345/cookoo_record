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
    required this.onToggleCamera,
    required this.onToggleMicrophone,
    required this.selectedRecordingMode,
    required this.onStartRecording,
    required this.canStartRecording,
    required this.isRecordingActive,
    required this.isBusy,
    this.isRecordingRestricted = false,
  });

  final String brandLabel;
  final List<VideoRecordingOptionModel> options;
  final String statusLabel;
  final String recordingLimitLabel;
  final String tutorialLabel;
  final Future<void> Function() onClose;
  final Future<void> Function(VideoRecordingMode mode) onSelectRecordingMode;
  final Future<void> Function() onToggleCamera;
  final Future<void> Function() onToggleMicrophone;
  final VideoRecordingMode selectedRecordingMode;
  final Future<void> Function() onStartRecording;
  final bool canStartRecording;
  final bool isRecordingActive;
  final bool isBusy;
  final bool isRecordingRestricted;

  @override
  Widget build(BuildContext context) {
    final bool isCompact = MediaQuery.sizeOf(context).width < 1040;
    final double width = isCompact ? 448 : 472;
    final bool isDark = VideoFeatureTheme.isDark(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: width,
        minWidth: isCompact ? 0 : width,
      ),
      child: Container(
        key: const Key('recordingPanel'),
        decoration: BoxDecoration(
          color: VideoFeatureTheme.panelFor(
            context,
          ).withValues(alpha: isDark ? 0.96 : 0.94),
          borderRadius: BorderRadius.circular(38),
          border: Border.all(color: VideoFeatureTheme.lineFor(context)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: isDark ? const Color(0x52040A12) : const Color(0x1A152329),
              blurRadius: 42,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(38),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 18 : 24,
                isCompact ? 18 : 24,
                isCompact ? 18 : 24,
                isCompact ? 18 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  if (!isCompact) ...<Widget>[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: VideoFeatureTheme.panelMutedFor(
                          context,
                        ).withValues(alpha: 0.74),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: VideoFeatureTheme.lineFor(context),
                        ),
                      ),
                      child: Column(
                        children: const <Widget>[
                          _SetupChecklistItem(
                            step: '1',
                            title: 'Choose a capture mode',
                            subtitle:
                                'Pick full screen, window, current tab, or camera only.',
                          ),
                          SizedBox(height: 12),
                          _SetupChecklistItem(
                            step: '2',
                            title: 'Confirm camera and mic',
                            subtitle:
                                'Check the active devices before the session starts.',
                          ),
                          SizedBox(height: 12),
                          _SetupChecklistItem(
                            step: '3',
                            title: 'Start and save',
                            subtitle:
                                'Record, review the result, then keep or export it from your library.',
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VideoFeatureTheme.panelFor(
                        context,
                      ).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: VideoFeatureTheme.lineFor(context),
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        for (
                          int index = 0;
                          index < options.length;
                          index++
                        ) ...<Widget>[
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
                                onStatusTap:
                                    option.kind ==
                                        VideoRecordingOptionKind.camera
                                    ? onToggleCamera
                                    : option.kind ==
                                          VideoRecordingOptionKind.microphone
                                    ? onToggleMicrophone
                                    : null,
                              );
                            },
                          ),
                          if (index != options.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    key: const Key('startRecordingButton'),
                    onPressed:
                        isRecordingActive ||
                            isBusy ||
                            isRecordingRestricted ||
                            !canStartRecording
                        ? null
                        : () => onStartRecording(),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(68),
                      backgroundColor: VideoFeatureTheme.primary,
                      disabledBackgroundColor: VideoFeatureTheme.mutedFor(
                        context,
                      ),
                      disabledForegroundColor: Colors.white,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    child: Text(
                      isRecordingRestricted
                          ? 'Recording limit reached'
                          : 'Start recording',
                    ),
                  ),
                ],
              ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: VideoFeatureTheme.panelFor(context),
      items: supportedModes
          .map((VideoRecordingMode mode) {
            return PopupMenuItem<VideoRecordingMode>(
              value: mode,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: <Widget>[
                  Icon(
                    _iconForMode(mode),
                    color: VideoFeatureTheme.inkFor(context),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mode.label,
                      style: TextStyle(
                        color: VideoFeatureTheme.inkFor(context),
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

class _SetupChecklistItem extends StatelessWidget {
  const _SetupChecklistItem({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  final String step;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: VideoFeatureTheme.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  color: VideoFeatureTheme.inkFor(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: VideoFeatureTheme.mutedFor(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: VideoFeatureTheme.panelMutedFor(
              context,
            ).withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: VideoFeatureTheme.lineFor(context)),
          ),
          child: Icon(icon, color: VideoFeatureTheme.inkFor(context), size: 24),
        ),
      ),
    );
  }
}

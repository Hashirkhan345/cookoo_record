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
    this.isRecordingRestricted = false,
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
  final bool isRecordingRestricted;

  @override
  Widget build(BuildContext context) {
    final bool isCompact = MediaQuery.sizeOf(context).width < 1040;
    final double width = isCompact ? 448 : 472;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: width,
        minWidth: isCompact ? 0 : width,
      ),
      child: Container(
        key: const Key('recordingPanel'),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(38),
          border: Border.all(color: VideoFeatureTheme.line),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1A152329),
              blurRadius: 42,
              offset: Offset(0, 24),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(38),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: VideoFeatureTheme.heroGradient,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          right: -18,
                          top: -12,
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                _HeroBadge(label: 'Studio'),
                                _HeroBadge(
                                  label: _shortLimitLabel(recordingLimitLabel),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            Text(
                              statusLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                height: 1.02,
                                letterSpacing: -1.2,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                _StatusPill(
                                  icon: Icons.desktop_windows_rounded,
                                  label: _displayModeLabel(),
                                ),
                                const _StatusPill(
                                  icon: Icons.videocam_rounded,
                                  label: 'Camera ready',
                                ),
                                const _StatusPill(
                                  icon: Icons.mic_rounded,
                                  label: 'Mic on',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VideoFeatureTheme.panel.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: VideoFeatureTheme.line),
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
                        isRecordingActive || isBusy || isRecordingRestricted
                        ? null
                        : () => onStartRecording(),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(68),
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
                        letterSpacing: -0.2,
                      ),
                    ),
                    child: Text(
                      isRecordingRestricted
                          ? 'Recording limit reached'
                          : statusLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      isRecordingRestricted
                          ? 'You have reached the 2-video lifetime limit.'
                          : recordingLimitLabel,
                      style: const TextStyle(
                        color: VideoFeatureTheme.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: VideoFeatureTheme.panelMuted.withValues(
                        alpha: 0.7,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: VideoFeatureTheme.line),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: VideoFeatureTheme.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            tutorialLabel,
                            style: const TextStyle(
                              color: VideoFeatureTheme.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: VideoFeatureTheme.ink,
                          size: 24,
                        ),
                      ],
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

  String _displayModeLabel() {
    switch (selectedRecordingMode) {
      case VideoRecordingMode.fullScreen:
        return 'Full screen';
      case VideoRecordingMode.window:
        return 'Window';
      case VideoRecordingMode.currentTab:
        return 'Current tab';
      case VideoRecordingMode.cameraOnly:
        return 'Camera only';
    }
  }

  String _shortLimitLabel(String label) {
    if (label.toLowerCase() == '5 minute recording limit') {
      return '5 min limit';
    }
    return label;
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
                    size: 22,
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

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.94),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: VideoFeatureTheme.focus, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
            color: VideoFeatureTheme.panelMuted.withValues(alpha: 0.46),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: VideoFeatureTheme.line),
          ),
          child: Icon(icon, color: VideoFeatureTheme.ink, size: 24),
        ),
      ),
    );
  }
}

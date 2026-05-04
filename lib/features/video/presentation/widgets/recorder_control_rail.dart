import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../controller/video_feature_theme.dart';

class RecorderControlRail extends StatefulWidget {
  const RecorderControlRail({
    super.key,
    required this.durationLabel,
    required this.isPaused,
    required this.canPauseResume,
    required this.isBusy,
    required this.onStop,
    required this.onPauseResume,
    required this.onRestart,
    required this.onDelete,
    this.showFooterAction = false,
  });

  final String durationLabel;
  final bool isPaused;
  final bool canPauseResume;
  final bool isBusy;
  final Future<void> Function() onStop;
  final Future<void> Function() onPauseResume;
  final Future<void> Function() onRestart;
  final Future<void> Function() onDelete;
  final bool showFooterAction;

  @override
  State<RecorderControlRail> createState() => _RecorderControlRailState();
}

class _RecorderControlRailState extends State<RecorderControlRail>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = VideoFeatureTheme.isDark(context);
    return Column(
      children: <Widget>[
        MouseRegion(
          onEnter: (_) => setState(() => _isExpanded = true),
          onExit: (_) => setState(() => _isExpanded = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 78,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color:
                  (isDark
                          ? VideoFeatureTheme.panelFor(context)
                          : VideoFeatureTheme.ink)
                      .withValues(alpha: isDark ? 0.94 : 0.9),
              borderRadius: BorderRadius.circular(28),
              boxShadow: VideoFeatureTheme.panelShadow,
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Column(
                children: <Widget>[
                  _RailAction(
                    key: const Key('stopRecordingButton'),
                    icon: Symbols.stop_circle_rounded,
                    enabled: !widget.isBusy,
                    onTap: widget.onStop,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.durationLabel,
                    style: TextStyle(
                      color: isDark
                          ? VideoFeatureTheme.darkInk
                          : Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _RailAction(
                    key: const Key('togglePauseRecordingButton'),
                    icon: widget.isPaused
                        ? Symbols.play_circle_rounded
                        : Symbols.pause_circle_rounded,
                    outlined: true,
                    enabled: widget.canPauseResume && !widget.isBusy,
                    onTap: widget.onPauseResume,
                  ),
                  if (_isExpanded) ...<Widget>[
                    const SizedBox(height: 20),
                    _RailAction(
                      key: const Key('restartRecordingButton'),
                      icon: Symbols.restart_alt_rounded,
                      outlined: true,
                      enabled: !widget.isBusy,
                      onTap: widget.onRestart,
                    ),
                    const SizedBox(height: 20),
                    _RailAction(
                      key: const Key('deleteRecordingButton'),
                      icon: Symbols.delete_sharp,
                      outlined: true,
                      enabled: !widget.isBusy,
                      onTap: widget.onDelete,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (widget.showFooterAction) ...<Widget>[
          const SizedBox(height: 24),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: VideoFeatureTheme.panelFor(
                context,
              ).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: VideoFeatureTheme.lineFor(context)),
            ),
            child: Icon(
              Icons.settings_outlined,
              color: VideoFeatureTheme.inkFor(context),
              size: 30,
            ),
          ),
        ],
      ],
    );
  }
}

class _RailAction extends StatelessWidget {
  const _RailAction({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.outlined = false,
  });

  final IconData icon;
  final bool enabled;
  final Future<void> Function() onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final bool isDark = VideoFeatureTheme.isDark(context);
    return InkWell(
      onTap: enabled ? () => onTap() : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: outlined
              ? Colors.transparent
              : (isDark ? VideoFeatureTheme.primary : Colors.white).withValues(
                  alpha: enabled ? (isDark ? 0.16 : 0.16) : 0.08,
                ),
          borderRadius: BorderRadius.circular(16),
          border: outlined
              ? Border.all(
                  color:
                      (isDark
                              ? VideoFeatureTheme.lineStrongFor(context)
                              : Colors.white)
                          .withValues(alpha: enabled ? 0.28 : 0.08),
                )
              : null,
        ),
        child: Icon(
          icon,
          color: enabled
              ? (isDark ? VideoFeatureTheme.inkFor(context) : Colors.white70)
              : (isDark ? VideoFeatureTheme.mutedFor(context) : Colors.white38),
          size: 24,
        ),
      ),
    );
  }
}

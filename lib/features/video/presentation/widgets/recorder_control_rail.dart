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
              color: const Color(0xEE151922),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x220B1326),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
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
                    style: const TextStyle(
                      color: Colors.white70,
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
                      icon: Symbols.delete_rounded,
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
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: VideoFeatureTheme.line),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: VideoFeatureTheme.ink,
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
    return InkWell(
      onTap: enabled ? () => onTap() : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: outlined
              ? Colors.transparent
              : Colors.white.withValues(alpha: enabled ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(16),
          border: outlined
              ? Border.all(
                  color: Colors.white.withValues(alpha: enabled ? 0.18 : 0.08),
                )
              : null,
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white70 : Colors.white38,
          size: 24,
        ),
      ),
    );
  }
}

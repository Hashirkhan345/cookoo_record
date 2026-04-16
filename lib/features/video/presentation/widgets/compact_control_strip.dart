import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../controller/video_feature_theme.dart';

class CompactControlStrip extends StatelessWidget {
  const CompactControlStrip({
    super.key,
    required this.durationLabel,
    required this.isPaused,
    required this.canPauseResume,
    required this.isBusy,
    required this.onStop,
    required this.onPauseResume,
    required this.onRestart,
    required this.onDelete,
  });

  final String durationLabel;
  final bool isPaused;
  final bool canPauseResume;
  final bool isBusy;
  final Future<void> Function() onStop;
  final Future<void> Function() onPauseResume;
  final Future<void> Function() onRestart;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: VideoFeatureTheme.ink.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: VideoFeatureTheme.floatingShadow,
      ),
      child: Row(
        children: <Widget>[
          _CompactAction(
            key: const Key('stopRecordingButton'),
            icon: Symbols.stop_circle_rounded,
            enabled: !isBusy,
            onTap: onStop,
          ),
          const SizedBox(width: 12),
          Text(
            durationLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _CompactAction(
            key: const Key('togglePauseRecordingButton'),
            icon: isPaused
                ? Symbols.play_circle_rounded
                : Symbols.pause_circle_rounded,
            enabled: canPauseResume && !isBusy,
            onTap: onPauseResume,
          ),
          const SizedBox(width: 14),
          _CompactAction(
            key: const Key('restartRecordingButton'),
            icon: Symbols.restart_alt_rounded,
            enabled: !isBusy,
            onTap: onRestart,
          ),
          const SizedBox(width: 14),
          _CompactAction(
            key: const Key('deleteRecordingButton'),
            icon: Symbols.delete_sharp,
            enabled: !isBusy,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _CompactAction extends StatelessWidget {
  const _CompactAction({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onTap() : null,
      borderRadius: BorderRadius.circular(14),
      child: Icon(
        icon,
        color: enabled ? Colors.white70 : Colors.white38,
        size: 24,
      ),
    );
  }
}

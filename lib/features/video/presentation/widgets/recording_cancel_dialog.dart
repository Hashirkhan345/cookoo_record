import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../controller/video_feature_theme.dart';

enum RecordingCancelAction { resume, restart, cancelRecording }

enum RecordingDialogVariant { cancel, restart }

class RecordingCancelDialog extends StatelessWidget {
  const RecordingCancelDialog({super.key, required this.variant});

  final RecordingDialogVariant variant;

  static Future<RecordingCancelAction?> showCancel(BuildContext context) {
    return showDialog<RecordingCancelAction>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) =>
          const RecordingCancelDialog(variant: RecordingDialogVariant.cancel),
    );
  }

  static Future<RecordingCancelAction?> showRestart(BuildContext context) {
    return showDialog<RecordingCancelAction>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) =>
          const RecordingCancelDialog(variant: RecordingDialogVariant.restart),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompact = MediaQuery.sizeOf(context).width < 720;
    final bool isRestartDialog = variant == RecordingDialogVariant.restart;
    final String title = isRestartDialog
        ? 'Are you sure you want to restart your recording?'
        : 'Are you sure you want to cancel your recording?';
    final String primaryActionLabel = isRestartDialog
        ? 'Restart recording'
        : 'Cancel recording';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Material(
            color: VideoFeatureTheme.panel,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(34, 30, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: VideoFeatureTheme.ink,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Your current video progress will be lost.',
                                  style: TextStyle(
                                    color: VideoFeatureTheme.muted,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Close',
                            style: IconButton.styleFrom(
                              foregroundColor: VideoFeatureTheme.ink,
                            ),
                            icon: const Icon(Icons.close_rounded, size: 34),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      if (isCompact)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            if (!isRestartDialog) ...<Widget>[
                              _RestartButton(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pop(RecordingCancelAction.restart),
                              ),
                              const SizedBox(height: 14),
                            ],
                            _ActionButtons(
                              isCompact: true,
                              primaryActionLabel: primaryActionLabel,
                              onResume: () => Navigator.of(
                                context,
                              ).pop(RecordingCancelAction.resume),
                              onPrimaryAction: () => Navigator.of(context).pop(
                                isRestartDialog
                                    ? RecordingCancelAction.restart
                                    : RecordingCancelAction.cancelRecording,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: <Widget>[
                            if (!isRestartDialog) ...<Widget>[
                              _RestartButton(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pop(RecordingCancelAction.restart),
                              ),
                              const Spacer(),
                            ] else
                              const Spacer(),
                            _ActionButtons(
                              isCompact: false,
                              primaryActionLabel: primaryActionLabel,
                              onResume: () => Navigator.of(
                                context,
                              ).pop(RecordingCancelAction.resume),
                              onPrimaryAction: () => Navigator.of(context).pop(
                                isRestartDialog
                                    ? RecordingCancelAction.restart
                                    : RecordingCancelAction.cancelRecording,
                              ),
                            ),
                          ],
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
}

class _RestartButton extends StatelessWidget {
  const _RestartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: VideoFeatureTheme.ink,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      icon: const Icon(Symbols.restart_alt_rounded, size: 34),
      label: const Text('Restart'),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isCompact,
    required this.primaryActionLabel,
    required this.onResume,
    required this.onPrimaryAction,
  });

  final bool isCompact;
  final String primaryActionLabel;
  final VoidCallback onResume;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
      OutlinedButton(
        onPressed: onResume,
        style: OutlinedButton.styleFrom(
          foregroundColor: VideoFeatureTheme.ink,
          backgroundColor: VideoFeatureTheme.panelMuted.withValues(alpha: 0.35),
          side: const BorderSide(color: VideoFeatureTheme.line),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        child: const Text('Resume'),
      ),
      FilledButton(
        onPressed: onPrimaryAction,
        style: FilledButton.styleFrom(
          backgroundColor: VideoFeatureTheme.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        child: Text(primaryActionLabel),
      ),
    ];

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          children[0],
          const SizedBox(height: 12),
          children[1],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[children[0], const SizedBox(width: 14), children[1]],
    );
  }
}

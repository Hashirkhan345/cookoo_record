import 'package:flutter/material.dart';

import '../controller/video_feature_theme.dart';
import 'studio_dialog.dart';

enum RecordingCancelAction { resume, restart, cancelRecording }

enum RecordingDialogVariant { cancel, restart }

class RecordingCancelDialog extends StatelessWidget {
  const RecordingCancelDialog({super.key, required this.variant});

  final RecordingDialogVariant variant;

  static Future<RecordingCancelAction?> showCancel(BuildContext context) {
    return showStudioDialog<RecordingCancelAction>(
      context: context,
      builder: (BuildContext context) =>
          const RecordingCancelDialog(variant: RecordingDialogVariant.cancel),
    );
  }

  static Future<RecordingCancelAction?> showRestart(BuildContext context) {
    return showStudioDialog<RecordingCancelAction>(
      context: context,
      builder: (BuildContext context) =>
          const RecordingCancelDialog(variant: RecordingDialogVariant.restart),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompact = MediaQuery.sizeOf(context).width < 720;
    final bool isRestartDialog = variant == RecordingDialogVariant.restart;
    final String title = isRestartDialog
        ? 'Restart this recording?'
        : 'Cancel this recording?';
    final String primaryActionLabel = isRestartDialog
        ? 'Restart recording'
        : 'Cancel recording';

    return StudioDialogShell(
      icon: isRestartDialog
          ? Icons.restart_alt_rounded
          : Icons.delete_outline_rounded,
      badge: isRestartDialog ? 'Restart' : 'Recording',
      title: title,
      message: 'Your current video progress will be lost.',
      maxWidth: isCompact ? 420 : 760,
      actions: isCompact
          ? _CompactActions(
              isRestartDialog: isRestartDialog,
              primaryActionLabel: primaryActionLabel,
            )
          : _WideActions(
              isRestartDialog: isRestartDialog,
              primaryActionLabel: primaryActionLabel,
            ),
    );
  }
}

class _CompactActions extends StatelessWidget {
  const _CompactActions({
    required this.isRestartDialog,
    required this.primaryActionLabel,
  });

  final bool isRestartDialog;
  final String primaryActionLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!isRestartDialog) ...<Widget>[
          FilledButton.tonalIcon(
            onPressed: () =>
                Navigator.of(context).pop(RecordingCancelAction.restart),
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Restart instead'),
            style: FilledButton.styleFrom(
              foregroundColor: VideoFeatureTheme.primaryDeep,
              backgroundColor: VideoFeatureTheme.panelMuted.withValues(
                alpha: 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton(
          onPressed: () =>
              Navigator.of(context).pop(RecordingCancelAction.resume),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          child: const Text('Resume'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            isRestartDialog
                ? RecordingCancelAction.restart
                : RecordingCancelAction.cancelRecording,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: VideoFeatureTheme.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          child: Text(primaryActionLabel),
        ),
      ],
    );
  }
}

class _WideActions extends StatelessWidget {
  const _WideActions({
    required this.isRestartDialog,
    required this.primaryActionLabel,
  });

  final bool isRestartDialog;
  final String primaryActionLabel;

  @override
  Widget build(BuildContext context) {
    final bool phone = MediaQuery.sizeOf(context).width < 900;
    return Row(
      children: <Widget>[
        if (!isRestartDialog)
          FilledButton.tonalIcon(
            onPressed: () =>
                Navigator.of(context).pop(RecordingCancelAction.restart),
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Restart instead'),
            style: FilledButton.styleFrom(
              foregroundColor: VideoFeatureTheme.primaryDeep,
              backgroundColor: VideoFeatureTheme.panelMuted.withValues(
                alpha: 0.7,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: phone ? 16 : 18,
                vertical: phone ? 14 : 16,
              ),
            ),
          ),
        const Spacer(),
        OutlinedButton(
          onPressed: () =>
              Navigator.of(context).pop(RecordingCancelAction.resume),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: phone ? 18 : 22,
              vertical: phone ? 14 : 16,
            ),
          ),
          child: const Text('Resume'),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            isRestartDialog
                ? RecordingCancelAction.restart
                : RecordingCancelAction.cancelRecording,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: VideoFeatureTheme.accent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: phone ? 18 : 22,
              vertical: phone ? 14 : 16,
            ),
          ),
          child: Text(primaryActionLabel),
        ),
      ],
    );
  }
}

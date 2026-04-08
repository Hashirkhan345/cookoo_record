import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/video_recording_flow_model.dart';
import '../../provider/video_provider.dart';
import '../../provider/video_state.dart';
import '../widgets/compact_control_strip.dart';
import '../controller/recording_panel_options_resolver.dart';
import '../widgets/profile_bubble.dart';
import '../widgets/recording_cancel_dialog.dart';
import '../widgets/recorder_control_rail.dart';
import '../widgets/recorder_panel.dart';

class RecordVideoFlowScreen extends ConsumerStatefulWidget {
  const RecordVideoFlowScreen({super.key});

  @override
  ConsumerState<RecordVideoFlowScreen> createState() =>
      _RecordVideoFlowScreenState();
}

class _RecordVideoFlowScreenState extends ConsumerState<RecordVideoFlowScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen<VideoState>(videoControllerProvider, (previous, next) {
      if (previous?.isRecordingFlowVisible == true &&
          !next.isRecordingFlowVisible &&
          Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    final VideoState state = ref.watch(videoControllerProvider);
    final VideoRecordingFlowModel? flow = state.flow;
    if (flow == null) {
      return const SizedBox.shrink();
    }

    final Size screenSize = MediaQuery.sizeOf(context);
    final bool isCompact = screenSize.width < 1040;
    final bool isBusy = state.isPreparingRecording || state.isFinalizing;
    final bool hasActiveRecording = state.hasActiveRecording;
    final bool showLiveControls = state.isRecording || state.isPaused;
    final bool canPauseResume = state.supportsPauseResume && !isBusy;
    final videoController = ref.read(videoControllerProvider.notifier);
    final panelOptions = resolveRecordingPanelOptions(flow: flow, state: state);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: PopScope(
          canPop: !state.hasActiveRecording,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop) {
              return;
            }

            unawaited(videoController.closeRecordingFlow());
          },
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double horizontalPadding = isCompact ? 12 : 24;

              return Stack(
                children: <Widget>[
                  if (!isCompact && showLiveControls)
                    Positioned(
                      left: 22,
                      top: 120,
                      child: RecorderControlRail(
                        durationLabel: _formatDuration(state.recordingDuration),
                        isPaused: state.isPaused,
                        canPauseResume: canPauseResume,
                        isBusy: isBusy,
                        onStop: videoController.stopRecordingSession,
                        onPauseResume:
                            videoController.togglePauseResumeRecording,
                        onRestart: () => _handleRestartRequest(videoController),
                        onDelete: () => _handleDeleteRequest(videoController),
                      ),
                    ),
                  if (isCompact && showLiveControls)
                    Positioned(
                      top: 32,
                      left: 20,
                      right: 20,
                      child: CompactControlStrip(
                        durationLabel: _formatDuration(state.recordingDuration),
                        isPaused: state.isPaused,
                        canPauseResume: canPauseResume,
                        isBusy: isBusy,
                        onStop: videoController.stopRecordingSession,
                        onPauseResume:
                            videoController.togglePauseResumeRecording,
                        onRestart: () => _handleRestartRequest(videoController),
                        onDelete: () => _handleDeleteRequest(videoController),
                      ),
                    ),
                  if (isCompact)
                    Positioned(
                      left: 16,
                      bottom: 18,
                      child: ProfileBubble(
                        size: 132,
                        cameraController: state.cameraController,
                      ),
                    )
                  else
                    Positioned(
                      left: 18,
                      bottom: 18,
                      child: ProfileBubble(
                        size: 220,
                        cameraController: state.cameraController,
                      ),
                    ),
                  if (!hasActiveRecording)
                    Align(
                      alignment: isCompact
                          ? Alignment.bottomCenter
                          : Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          isCompact ? 106 : 16,
                          horizontalPadding,
                          16,
                        ),
                        child: RecorderPanel(
                          brandLabel: flow.brandLabel,
                          options: panelOptions,
                          statusLabel: _panelStatusLabel(flow, state),
                          recordingLimitLabel: flow.recordingLimitLabel,
                          tutorialLabel: flow.tutorialLabel,
                          onClose: videoController.closeRecordingFlow,
                          selectedRecordingMode: state.selectedRecordingMode,
                          onSelectRecordingMode: (selectedRecordingMode) async {
                            videoController.selectRecordingMode(
                              selectedRecordingMode,
                            );
                          },
                          onStartRecording:
                              videoController.startRecordingSession,
                          isRecordingActive: hasActiveRecording,
                          isBusy: isBusy,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final String minutes = duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final String seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _panelStatusLabel(VideoRecordingFlowModel flow, VideoState state) {
    if (state.isPreparingRecording) {
      return 'Starting camera...';
    }

    if (state.isFinalizing) {
      return 'Finishing recording...';
    }

    if (state.isPaused) {
      return 'Recording paused';
    }

    if (state.isRecording) {
      return 'Recording live';
    }

    return flow.startRecordingLabel;
  }

  Future<void> _handleDeleteRequest(VideoController videoController) async {
    final RecordingCancelAction? action =
        await RecordingCancelDialog.showCancel(context);
    if (!mounted || action == null || action == RecordingCancelAction.resume) {
      return;
    }

    switch (action) {
      case RecordingCancelAction.resume:
        return;
      case RecordingCancelAction.restart:
        await videoController.restartRecordingSession();
        return;
      case RecordingCancelAction.cancelRecording:
        await videoController.deleteRecordingSession();
        return;
    }
  }

  Future<void> _handleRestartRequest(VideoController videoController) async {
    final RecordingCancelAction? action =
        await RecordingCancelDialog.showRestart(context);
    if (!mounted || action == null || action == RecordingCancelAction.resume) {
      return;
    }

    if (action == RecordingCancelAction.restart) {
      await videoController.restartRecordingSession();
    }
  }
}

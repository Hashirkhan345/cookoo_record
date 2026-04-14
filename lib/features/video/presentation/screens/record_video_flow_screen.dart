import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/video_recording_flow_model.dart';
import '../../provider/video_provider.dart';
import '../../provider/video_state.dart';
import '../widgets/compact_control_strip.dart';
import '../controller/recording_panel_options_resolver.dart';
import '../controller/video_feature_theme.dart';
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
  Offset? _bubblePosition;
  int _bubbleSizeIndex = 0;
  bool _showBubbleSizeControls = false;
  bool _isBubbleHovered = false;

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
    final bool isBusy =
        state.isPreparingRecording ||
        state.isFinalizing ||
        state.isCountingDown;
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
              final bool canMoveBubble =
                  hasActiveRecording && !state.isCountingDown;
              final double bubbleBaseSize = isCompact ? 188 : 220;
              final double bubbleSize =
                  bubbleBaseSize * _bubbleSizeMultiplierFor(_bubbleSizeIndex);
              final Offset bubblePosition =
                  _bubblePosition ??
                  _defaultBubblePosition(
                    constraints: constraints,
                    bubbleSize: bubbleSize,
                    isCompact: isCompact,
                  );

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: canMoveBubble
                    ? (TapDownDetails details) {
                        if (_isPointInsideBubbleRegion(
                          point: details.localPosition,
                          bubblePosition: bubblePosition,
                          bubbleSize: bubbleSize,
                        )) {
                          return;
                        }

                        setState(() {
                          _showBubbleSizeControls = false;
                          _bubblePosition = _clampBubblePosition(
                            desiredPosition: Offset(
                              details.localPosition.dx - (bubbleSize / 2),
                              details.localPosition.dy - (bubbleSize / 2),
                            ),
                            constraints: constraints,
                            bubbleSize: bubbleSize,
                            isCompact: isCompact,
                          );
                        });
                      }
                    : null,
                child: Stack(
                  children: <Widget>[
                    if (!isCompact && showLiveControls)
                      Positioned(
                        left: 22,
                        top: 120,
                        child: RecorderControlRail(
                          durationLabel: _formatDuration(
                            state.recordingDuration,
                          ),
                          isPaused: state.isPaused,
                          canPauseResume: canPauseResume,
                          isBusy: isBusy,
                          onStop: videoController.stopRecordingSession,
                          onPauseResume:
                              videoController.togglePauseResumeRecording,
                          onRestart: () =>
                              _handleRestartRequest(videoController),
                          onDelete: () => _handleDeleteRequest(videoController),
                        ),
                      ),
                    if (isCompact && showLiveControls)
                      Positioned(
                        top: 32,
                        left: 20,
                        right: 20,
                        child: CompactControlStrip(
                          durationLabel: _formatDuration(
                            state.recordingDuration,
                          ),
                          isPaused: state.isPaused,
                          canPauseResume: canPauseResume,
                          isBusy: isBusy,
                          onStop: videoController.stopRecordingSession,
                          onPauseResume:
                              videoController.togglePauseResumeRecording,
                          onRestart: () =>
                              _handleRestartRequest(videoController),
                          onDelete: () => _handleDeleteRequest(videoController),
                        ),
                      ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      left: bubblePosition.dx,
                      top: bubblePosition.dy,
                      child: GestureDetector(
                        onPanUpdate: canMoveBubble
                            ? (DragUpdateDetails details) {
                                setState(() {
                                  _bubblePosition = _clampBubblePosition(
                                    desiredPosition:
                                        (_bubblePosition ?? bubblePosition) +
                                        details.delta,
                                    constraints: constraints,
                                    bubbleSize: bubbleSize,
                                    isCompact: isCompact,
                                  );
                                });
                              }
                            : null,
                        child: MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              _isBubbleHovered = true;
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              _isBubbleHovered = false;
                            });
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: <Widget>[
                              if (canMoveBubble &&
                                  (_showBubbleSizeControls ||
                                      _isBubbleHovered)) ...<Widget>[
                                Positioned(
                                  top: -54,
                                  left: 0,
                                  right: 0,
                                  child: MouseRegion(
                                    onEnter: (_) {
                                      setState(() {
                                        _isBubbleHovered = true;
                                      });
                                    },
                                    onExit: (_) {
                                      setState(() {
                                        _isBubbleHovered = false;
                                      });
                                    },
                                    child: _BubbleSizeControls(
                                      selectedIndex: _bubbleSizeIndex,
                                      onSelected: (int index) {
                                        setState(() {
                                          _bubbleSizeIndex = index;
                                          _showBubbleSizeControls = true;
                                          final Offset currentPosition =
                                              _bubblePosition ?? bubblePosition;
                                          final double nextBubbleSize =
                                              bubbleBaseSize *
                                              _bubbleSizeMultiplierFor(index);
                                          _bubblePosition =
                                              _clampBubblePosition(
                                                desiredPosition:
                                                    currentPosition,
                                                constraints: constraints,
                                                bubbleSize: nextBubbleSize,
                                                isCompact: isCompact,
                                              );
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                              GestureDetector(
                                onTap: canMoveBubble
                                    ? () {
                                        setState(() {
                                          _showBubbleSizeControls = true;
                                        });
                                      }
                                    : null,
                                child: ProfileBubble(
                                  size: bubbleSize,
                                  cameraController: state.cameraController,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!hasActiveRecording)
                      Align(
                        alignment: isCompact
                            ? Alignment.bottomCenter
                            : Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            isCompact ? 106 : 24,
                            horizontalPadding,
                            24,
                          ),
                          child: RecorderPanel(
                            brandLabel: flow.brandLabel,
                            options: panelOptions,
                            statusLabel: _panelStatusLabel(flow, state),
                            recordingLimitLabel: flow.recordingLimitLabel,
                            tutorialLabel: flow.tutorialLabel,
                            onClose: videoController.closeRecordingFlow,
                            selectedRecordingMode: state.selectedRecordingMode,
                            onSelectRecordingMode:
                                (selectedRecordingMode) async {
                                  videoController.selectRecordingMode(
                                    selectedRecordingMode,
                                  );
                                },
                            onStartRecording:
                                videoController.startRecordingSession,
                            isRecordingActive: hasActiveRecording,
                            isBusy: isBusy,
                            isRecordingRestricted:
                                state.hasReachedRecordingRestriction,
                          ),
                        ),
                      ),
                    if (state.isCountingDown)
                      Positioned.fill(
                        child: _RecordingCountdownOverlay(
                          label: state.countdownLabel!,
                          isCompact: isCompact,
                        ),
                      ),
                  ],
                ),
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
    if (state.isCountingDown) {
      return 'Get ready...';
    }

    if (state.isPreparingRecording) {
      return 'Starting camera...';
    }

    if (state.isFinalizing) {
      return 'Finishing recording...';
    }

    if (state.hasReachedRecordingRestriction) {
      return 'Recording limit reached';
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

  Offset _defaultBubblePosition({
    required BoxConstraints constraints,
    required double bubbleSize,
    required bool isCompact,
  }) {
    const double sideMargin = 18;
    const double bottomMargin = 18;

    return _clampBubblePosition(
      desiredPosition: Offset(
        isCompact ? 16 : sideMargin,
        constraints.maxHeight - bubbleSize - bottomMargin,
      ),
      constraints: constraints,
      bubbleSize: bubbleSize,
      isCompact: isCompact,
    );
  }

  Offset _clampBubblePosition({
    required Offset desiredPosition,
    required BoxConstraints constraints,
    required double bubbleSize,
    required bool isCompact,
  }) {
    const double sideMargin = 18;
    const double bottomMargin = 18;
    final double minLeft = sideMargin;
    final double maxLeft = constraints.maxWidth - bubbleSize - sideMargin;
    final double minTop = isCompact ? 112 : 18;
    final double maxTop = constraints.maxHeight - bubbleSize - bottomMargin;

    return Offset(
      desiredPosition.dx.clamp(minLeft, maxLeft),
      desiredPosition.dy.clamp(minTop, maxTop),
    );
  }

  bool _isPointInsideBubbleRegion({
    required Offset point,
    required Offset bubblePosition,
    required double bubbleSize,
  }) {
    final Rect bubbleRect = Rect.fromLTWH(
      bubblePosition.dx,
      bubblePosition.dy - 58,
      bubbleSize,
      bubbleSize + 72,
    );
    return bubbleRect.contains(point);
  }

  double _bubbleSizeMultiplierFor(int index) {
    switch (index) {
      case 0:
        return 1.0;
      case 1:
        return 1.3;
      case 2:
        return 1.58;
    }
    return 1.0;
  }
}

class _BubbleSizeControls extends StatelessWidget {
  const _BubbleSizeControls({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: VideoFeatureTheme.ink.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int index) {
            final bool isSelected = index == selectedIndex;
            final double dotSize = 8 + (index * 4);

            return Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 10),
              child: GestureDetector(
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? VideoFeatureTheme.accent
                        : Colors.white.withValues(alpha: 0.74),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? VideoFeatureTheme.glowShadow
                        : const <BoxShadow>[],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _RecordingCountdownOverlay extends StatelessWidget {
  const _RecordingCountdownOverlay({
    required this.label,
    required this.isCompact,
  });

  final String label;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final double badgeSize = isCompact ? 188 : 228;
    final String caption = label == 'Go'
        ? 'Starting now'
        : 'Recording starts in';

    return ColoredBox(
      key: const Key('recordingCountdownOverlay'),
      color: const Color(0xA60B1326),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFF5B90F8), VideoFeatureTheme.primary],
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x551D63E8),
                    blurRadius: 42,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.72,
                              end: 1,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                  child: Text(
                    label,
                    key: ValueKey<String>(label),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: label == 'Go'
                          ? badgeSize * 0.28
                          : badgeSize * 0.54,
                      fontWeight: FontWeight.w900,
                      letterSpacing: label == 'Go' ? -1.4 : -4.2,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                caption,
                key: ValueKey<String>(caption),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: isCompact ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

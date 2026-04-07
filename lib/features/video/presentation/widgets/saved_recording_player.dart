import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/models/saved_video_recording_model.dart';
import '../controller/saved_recording_player_controller_factory.dart';
import '../controller/video_feature_theme.dart';

class SavedRecordingPlayer extends StatefulWidget {
  const SavedRecordingPlayer({
    super.key,
    required this.recording,
    this.autoplayMuted = true,
  });

  final SavedVideoRecordingModel recording;
  final bool autoplayMuted;

  @override
  State<SavedRecordingPlayer> createState() => _SavedRecordingPlayerState();
}

class _SavedRecordingPlayerState extends State<SavedRecordingPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initialization;
  Object? _initializationError;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant SavedRecordingPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recording.id != widget.recording.id ||
        oldWidget.recording.playbackPath != widget.recording.playbackPath) {
      _disposeController();
      _initializeController();
      return;
    }

    if (!oldWidget.autoplayMuted && widget.autoplayMuted) {
      unawaited(_playMuted());
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _initializeController() {
    final VideoPlayerController controller =
        createSavedRecordingPlayerController(widget.recording);

    _controller = controller;
    _initializationError = null;
    controller.addListener(_handleControllerChanged);

    _initialization = controller
        .initialize()
        .then((_) async {
          await controller.setLooping(true);
          await controller.setVolume(_isMuted ? 0 : 1);

          if (widget.autoplayMuted) {
            await controller.play();
          }

          if (mounted) {
            setState(() {});
          }
        })
        .catchError((Object error) {
          _initializationError = error;
          if (mounted) {
            setState(() {});
          }
        });
  }

  void _disposeController() {
    final VideoPlayerController? controller = _controller;
    if (controller != null) {
      controller.removeListener(_handleControllerChanged);
      controller.dispose();
    }
    _controller = null;
    _initialization = null;
    _initializationError = null;
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _togglePlayPause() async {
    final VideoPlayerController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final bool isCompleted = _isPlaybackComplete(controller.value);
    if (controller.value.isPlaying) {
      await controller.pause();
      return;
    }

    if (isCompleted) {
      await controller.seekTo(Duration.zero);
    }

    await controller.play();
  }

  Future<void> _restartPlayback() async {
    final VideoPlayerController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    await controller.seekTo(Duration.zero);
    await controller.play();
  }

  Future<void> _toggleMute() async {
    final VideoPlayerController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      _isMuted = !_isMuted;
    });
    await controller.setVolume(_isMuted ? 0 : 1);
  }

  Future<void> _openFullscreenPreview() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: SavedRecordingPlayer(
              recording: widget.recording,
              autoplayMuted: false,
            ),
          ),
        );
      },
    );
  }

  Future<void> _playMuted() async {
    final VideoPlayerController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (!_isMuted) {
      setState(() {
        _isMuted = true;
      });
    }

    await controller.setVolume(0);
    if (_isPlaybackComplete(controller.value)) {
      await controller.seekTo(Duration.zero);
    }
    await controller.play();
  }

  bool _isPlaybackComplete(VideoPlayerValue value) {
    if (!value.isInitialized || value.duration == Duration.zero) {
      return false;
    }

    return value.position >= value.duration - const Duration(milliseconds: 250);
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? controller = _controller;
    final Future<void>? initialization = _initialization;

    if (controller == null || initialization == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<void>(
      future: initialization,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        final bool isReady =
            snapshot.connectionState == ConnectionState.done &&
            _initializationError == null &&
            controller.value.isInitialized;
        final bool isPlaying = isReady && controller.value.isPlaying;
        final bool isComplete =
            isReady && _isPlaybackComplete(controller.value);

        return Container(
          key: Key('savedRecordingStage_${widget.recording.id}'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x260B1326),
                blurRadius: 34,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: 1.7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: Stack(
                children: <Widget>[
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0xFF2A3049),
                            Color(0xFF151A2E),
                            Color(0xFF0E1220),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isReady)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ColoredBox(
                          color: Colors.black,
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: controller.value.aspectRatio == 0
                                  ? 16 / 9
                                  : controller.value.aspectRatio,
                              child: VideoPlayer(controller),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.white.withValues(alpha: 0.06),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.32),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // const Positioned(
                  //   left: 86,
                  //   top: 86,
                  //   child: _StageBubble(size: 82, secondary: true),
                  // ),
                  // const Positioned(
                  //   right: 130,
                  //   bottom: 94,
                  //   child: _StageBubble(size: 162),
                  // ),
                  Positioned.fill(
                    child: Center(
                      child: _CenterAction(
                        isVisible: !isPlaying,
                        isReady: isReady,
                        isComplete: isComplete,
                        hasError:
                            snapshot.hasError || _initializationError != null,
                        onPressed: _togglePlayPause,
                      ),
                    ),
                  ),
                  if (snapshot.connectionState != ConnectionState.done)
                    const Center(child: CircularProgressIndicator())
                  else if (snapshot.hasError || _initializationError != null)
                    const Center(
                      child: Text(
                        'Unable to load this recording.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 72,
                    child: IgnorePointer(
                      ignoring: !isReady,
                      child: ColoredBox(
                        color: VideoFeatureTheme.primary,
                        child: SizedBox(
                          height: 4,
                          child: isReady
                              ? VideoProgressIndicator(
                                  controller,
                                  allowScrubbing: true,
                                  padding: EdgeInsets.zero,
                                  colors: VideoProgressColors(
                                    playedColor: VideoFeatureTheme.primary,
                                    bufferedColor: Colors.white30,
                                    backgroundColor: Colors.white12,
                                  ),
                                )
                              : const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _BottomControlBar(
                      isMuted: _isMuted,
                      isReady: isReady,
                      onReplay: _restartPlayback,
                      onVolume: _toggleMute,
                      onFullscreen: _openFullscreenPreview,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CenterAction extends StatelessWidget {
  const _CenterAction({
    required this.isVisible,
    required this.isReady,
    required this.isComplete,
    required this.hasError,
    required this.onPressed,
  });

  final bool isVisible;
  final bool isReady;
  final bool isComplete;
  final bool hasError;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: !isVisible || !isReady,
      child: AnimatedOpacity(
        opacity: isVisible && isReady ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  isComplete ? Icons.replay_outlined : Icons.play_arrow_rounded,
                  color: Colors.white70,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Text(
                  isComplete ? 'Watch again' : 'Play recording',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
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

class _BottomControlBar extends StatelessWidget {
  const _BottomControlBar({
    required this.isMuted,
    required this.isReady,
    required this.onReplay,
    required this.onVolume,
    required this.onFullscreen,
  });

  final bool isMuted;
  final bool isReady;
  final VoidCallback onReplay;
  final VoidCallback onVolume;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.black.withValues(alpha: 0.04),
            Colors.black.withValues(alpha: 0.58),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: isReady ? onReplay : null,
            icon: const Icon(
              Icons.replay_outlined,
              color: Colors.white70,
              size: 34,
            ),
            tooltip: 'Replay recording',
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: isReady ? onVolume : null,
            icon: Icon(
              isMuted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
              color: Colors.white70,
              size: 34,
            ),
            tooltip: isMuted ? 'Unmute recording' : 'Mute recording',
          ),
          const Spacer(),
          const Icon(Icons.settings_outlined, color: Colors.white54, size: 34),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onFullscreen,
            icon: const Icon(
              Icons.open_in_full_rounded,
              color: Colors.white70,
              size: 34,
            ),
            tooltip: 'Open full screen preview',
          ),
        ],
      ),
    );
  }
}

// class _StageBubble extends StatelessWidget {
//   const _StageBubble({required this.size, this.secondary = false});

//   final double size;
//   final bool secondary;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         border: Border.all(
//           color: Colors.white.withValues(alpha: 0.28),
//           width: 4,
//         ),
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: secondary
//               ? <Color>[const Color(0xFF8CA4CC), const Color(0xFF445D8B)]
//               : <Color>[const Color(0xFFE1BE79), const Color(0xFFAF753F)],
//         ),
//       ),
//       child: Icon(
//         Icons.person_rounded,
//         color: Colors.white.withValues(alpha: 0.88),
//         size: size * 0.48,
//       ),
//     );
//   }
// }

import 'dart:async';

import 'package:flutter/foundation.dart';
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
    this.isFullscreen = false,
  });

  final SavedVideoRecordingModel recording;
  final bool autoplayMuted;
  final bool isFullscreen;

  static Future<void> showFullscreenDialog(
    BuildContext context, {
    required SavedVideoRecordingModel recording,
    bool autoplayMuted = false,
  }) {
    return showDialog<void>(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (BuildContext context) {
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            minimum: const EdgeInsets.all(18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1480),
                child: SavedRecordingPlayer(
                  recording: recording,
                  autoplayMuted: autoplayMuted,
                  isFullscreen: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

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

    await SavedRecordingPlayer.showFullscreenDialog(
      context,
      recording: widget.recording,
      autoplayMuted: false,
    );
  }

  Future<void> _closeFullscreenPreview() async {
    if (!mounted) {
      return;
    }

    Navigator.of(context).maybePop();
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

  String _formatPlaybackLabel(Duration duration) {
    final Duration safeDuration = duration.isNegative
        ? Duration.zero
        : duration;
    final int hours = safeDuration.inHours;
    final int minutes = safeDuration.inMinutes.remainder(60);
    final int seconds = safeDuration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '${safeDuration.inMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _buildPlaybackErrorMessage() {
    final String path = widget.recording.playbackPath.toLowerCase();
    final bool isWebm = path.contains('.webm');

    if (!kIsWeb && isWebm) {
      return 'This device does not support this WebM demo. Use an MP4 demo video for mobile.';
    }

    return 'Unable to load this recording.';
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
        final Duration duration = isReady
            ? controller.value.duration
            : Duration.zero;
        final Duration position = isReady
            ? (controller.value.position > duration
                  ? duration
                  : controller.value.position)
            : Duration.zero;
        final double playerAspectRatio = isReady
            ? _resolvePlayerAspectRatio(controller)
            : 1.7;

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
            aspectRatio: playerAspectRatio,
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
                          child: FittedBox(
                            fit: widget.isFullscreen
                                ? BoxFit.contain
                                : BoxFit.cover,
                            clipBehavior: Clip.hardEdge,
                            child: SizedBox(
                              width: controller.value.size.width <= 0
                                  ? 16
                                  : controller.value.size.width,
                              height: controller.value.size.height <= 0
                                  ? 9
                                  : controller.value.size.height,
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
                  if (widget.isFullscreen)
                    Positioned(
                      top: 18,
                      left: 18,
                      child: _OverlayIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back to player',
                        onPressed: _closeFullscreenPreview,
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
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _buildPlaybackErrorMessage(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _BottomControlBar(
                      controller: controller,
                      isMuted: _isMuted,
                      isReady: isReady,
                      isPlaying: isPlaying,
                      isFullscreen: widget.isFullscreen,
                      elapsedLabel: _formatPlaybackLabel(position),
                      durationLabel: _formatPlaybackLabel(duration),
                      onReplay: _restartPlayback,
                      onPlayPause: _togglePlayPause,
                      onVolume: _toggleMute,
                      onToggleFullscreen: widget.isFullscreen
                          ? _closeFullscreenPreview
                          : _openFullscreenPreview,
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

  double _resolvePlayerAspectRatio(VideoPlayerController controller) {
    final double aspectRatio = controller.value.aspectRatio;
    if (aspectRatio <= 0) {
      return widget.isFullscreen ? 16 / 9 : 1.7;
    }

    if (widget.isFullscreen) {
      return aspectRatio.clamp(0.56, 2.1);
    }

    return 1.7;
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.46),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      ),
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
    required this.controller,
    required this.isMuted,
    required this.isReady,
    required this.isPlaying,
    required this.isFullscreen,
    required this.elapsedLabel,
    required this.durationLabel,
    required this.onReplay,
    required this.onPlayPause,
    required this.onVolume,
    required this.onToggleFullscreen,
  });

  final VideoPlayerController controller;
  final bool isMuted;
  final bool isReady;
  final bool isPlaying;
  final bool isFullscreen;
  final String elapsedLabel;
  final String durationLabel;
  final VoidCallback onReplay;
  final VoidCallback onPlayPause;
  final VoidCallback onVolume;
  final VoidCallback onToggleFullscreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.black.withValues(alpha: 0.04),
            Colors.black.withValues(alpha: 0.58),
          ],
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                elapsedLabel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 6,
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
                        : ColoredBox(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                durationLabel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              _ControlButton(
                onPressed: isReady ? onPlayPause : null,
                icon: isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                tooltip: isPlaying ? 'Pause recording' : 'Play recording',
                highlighted: true,
              ),
              const SizedBox(width: 12),
              _ControlButton(
                onPressed: isReady ? onReplay : null,
                icon: Icons.replay_rounded,
                tooltip: 'Replay recording',
              ),
              const Spacer(),
              _ControlButton(
                onPressed: isReady ? onVolume : null,
                icon: isMuted
                    ? Icons.volume_off_outlined
                    : Icons.volume_up_outlined,
                tooltip: isMuted ? 'Unmute recording' : 'Mute recording',
              ),
              const SizedBox(width: 12),
              _ControlButton(
                onPressed: onToggleFullscreen,
                icon: isFullscreen
                    ? Icons.fullscreen_exit_rounded
                    : Icons.open_in_full_rounded,
                tooltip: isFullscreen
                    ? 'Close full screen preview'
                    : 'Open full screen preview',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.highlighted = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = onPressed == null
        ? Colors.white38
        : (highlighted ? Colors.white : Colors.white70);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: highlighted
                  ? VideoFeatureTheme.primary
                  : Colors.white.withValues(
                      alpha: onPressed == null ? 0.08 : 0.12,
                    ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: highlighted ? 0 : 0.14),
              ),
            ),
            child: Icon(icon, color: foregroundColor, size: 28),
          ),
        ),
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

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../controller/video_feature_theme.dart';

class ProfileBubble extends StatelessWidget {
  const ProfileBubble({super.key, required this.size, this.cameraController});

  final double size;
  final CameraController? cameraController;

  @override
  Widget build(BuildContext context) {
    final double badgeSize = size * 0.22;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          key: const Key('userProfileBubble'),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 6),
            boxShadow: VideoFeatureTheme.panelShadow,
          ),
          child: ClipOval(
            child: _ProfileBubbleContent(
              size: size,
              cameraController: cameraController,
            ),
          ),
        ),
        Positioned(
          left: size * 0.02,
          bottom: -badgeSize * 0.08,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              gradient: VideoFeatureTheme.accentGradient,
              borderRadius: BorderRadius.circular(badgeSize * 0.35),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: Icon(
              Icons.videocam_rounded,
              color: Colors.white,
              size: badgeSize * 0.48,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileBubbleContent extends StatelessWidget {
  const _ProfileBubbleContent({
    required this.size,
    required this.cameraController,
  });

  final double size;
  final CameraController? cameraController;

  @override
  Widget build(BuildContext context) {
    final CameraController? controller = cameraController;
    if (controller != null && controller.value.isInitialized) {
      final double previewAspectRatio = controller.value.aspectRatio == 0
          ? 1
          : controller.value.aspectRatio;

      return ColoredBox(
        color: Colors.black,
        child: Transform.scale(
          scale: previewAspectRatio,
          child: Center(
            child: AspectRatio(
              aspectRatio: previewAspectRatio,
              child: CameraPreview(
                key: ValueKey<CameraController>(controller),
                controller,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: <Widget>[
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFFE7C989), Color(0xFFD5A460)],
              ),
            ),
          ),
        ),
        Positioned(
          top: size * 0.18,
          left: size * 0.27,
          child: Container(
            width: size * 0.46,
            height: size * 0.42,
            decoration: BoxDecoration(
              color: const Color(0xFFF2C8A5),
              borderRadius: BorderRadius.circular(size),
            ),
          ),
        ),
        Positioned(
          top: size * 0.12,
          left: size * 0.24,
          child: Container(
            width: size * 0.52,
            height: size * 0.24,
            decoration: BoxDecoration(
              color: const Color(0xFF24130F),
              borderRadius: BorderRadius.circular(size),
            ),
          ),
        ),
        Positioned(
          top: size * 0.34,
          left: size * 0.31,
          child: Row(
            children: <Widget>[
              _GlassesLens(size: size),
              SizedBox(width: size * 0.03),
              _GlassesLens(size: size),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: size * 0.08,
          right: size * 0.08,
          child: Container(
            height: size * 0.34,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1E8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(size)),
            ),
          ),
        ),
        Positioned(
          bottom: size * 0.06,
          left: size * 0.18,
          right: size * 0.18,
          child: Container(
            height: size * 0.19,
            decoration: BoxDecoration(
              color: const Color(0xFFF2E0C7),
              borderRadius: BorderRadius.circular(size),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassesLens extends StatelessWidget {
  const _GlassesLens({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.11,
      height: size * 0.08,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF3A2A22), width: 2),
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}

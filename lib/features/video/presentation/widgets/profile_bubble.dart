import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../controller/video_feature_theme.dart';

class ProfileBubble extends StatelessWidget {
  const ProfileBubble({super.key, required this.size, this.cameraController});

  final double size;
  final CameraController? cameraController;

  @override
  Widget build(BuildContext context) {
    final double borderWidth = size < 180 ? 3 : 5;
    final double badgeSize = size * 0.15;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          key: const Key('userProfileBubble'),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: borderWidth),
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
          left: size * 0.03,
          bottom: size * 0.03,
          child: Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              gradient: VideoFeatureTheme.accentGradient,
              borderRadius: BorderRadius.circular(badgeSize * 0.35),
              border: Border.all(
                color: Colors.white,
                width: size < 180 ? 2 : 2.5,
              ),
            ),
            child: Icon(
              Icons.videocam_rounded,
              color: Colors.white,
              size: badgeSize * 0.46,
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
      final Size previewSize = controller.value.previewSize ?? Size(size, size);
      final double previewWidth = previewSize.width <= 0
          ? size
          : previewSize.width;
      final double previewHeight = previewSize.height <= 0
          ? size
          : previewSize.height;

      return ColoredBox(
        color: Colors.black,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          alignment: const Alignment(0, -0.2),
          child: SizedBox(
            width: previewWidth,
            height: previewHeight,
            child: CameraPreview(
              key: ValueKey<CameraController>(controller),
              controller,
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

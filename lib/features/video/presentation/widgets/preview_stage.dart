import 'package:flutter/material.dart';

import '../controller/video_feature_theme.dart';

class PreviewStage extends StatelessWidget {
  const PreviewStage({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 880),
      child: Container(
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
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.white.withValues(alpha: 0.06),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.36),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 18,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.link_rounded, color: Colors.white, size: 26),
                        SizedBox(width: 14),
                        Icon(
                          Icons.open_in_full_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  left: 86,
                  top: 86,
                  child: _PreviewBubble(size: 82, secondary: true),
                ),
                const Positioned(
                  right: 130,
                  bottom: 94,
                  child: _PreviewBubble(size: 162),
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 72,
                  child: ColoredBox(
                    color: VideoFeatureTheme.primary,
                    child: SizedBox(height: 4),
                  ),
                ),
                const Align(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.replay_outlined,
                        color: Colors.white70,
                        size: 46,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Watch again',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
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
                    child: const Row(
                      children: <Widget>[
                        Icon(
                          Icons.replay_outlined,
                          color: Colors.white70,
                          size: 34,
                        ),
                        SizedBox(width: 16),
                        Icon(
                          Icons.volume_up_outlined,
                          color: Colors.white70,
                          size: 34,
                        ),
                        Spacer(),
                        Icon(
                          Icons.settings_outlined,
                          color: Colors.white70,
                          size: 34,
                        ),
                        SizedBox(width: 16),
                        Icon(
                          Icons.open_in_full_rounded,
                          color: Colors.white70,
                          size: 34,
                        ),
                      ],
                    ),
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

class _PreviewBubble extends StatelessWidget {
  const _PreviewBubble({required this.size, this.secondary = false});

  final double size;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 4,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: secondary
              ? <Color>[const Color(0xFF8CA4CC), const Color(0xFF445D8B)]
              : <Color>[const Color(0xFFE1BE79), const Color(0xFFAF753F)],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        color: Colors.white.withValues(alpha: 0.88),
        size: size * 0.48,
      ),
    );
  }
}

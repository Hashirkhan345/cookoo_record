import 'package:flutter/material.dart';

import '../../../video/presentation/controller/video_feature_theme.dart';
import '../../../video/presentation/widgets/brand_lockup.dart';

class AuthScreenScaffold extends StatelessWidget {
  const AuthScreenScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final bool isWide = screenSize.width >= 920;
    final bool isPhone = screenSize.width < 520;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: VideoFeatureTheme.screenBackground,
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -20,
            child: _BackdropGlow(
              size: screenSize.width * 0.48,
              colors: const <Color>[Color(0x33E8BC67), Color(0x00E8BC67)],
            ),
          ),
          Positioned(
            right: -120,
            top: 120,
            child: _BackdropGlow(
              size: screenSize.width * 0.5,
              colors: const <Color>[Color(0x33209D8C), Color(0x00209D8C)],
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isPhone ? 14 : 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(isPhone ? 28 : 40),
                      border: Border.all(color: VideoFeatureTheme.line),
                      boxShadow: VideoFeatureTheme.panelShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isPhone ? 28 : 40),
                      child: isWide
                          ? Row(
                              children: <Widget>[
                                const Expanded(
                                  flex: 12,
                                  child: _AuthFeaturePanel(),
                                ),
                                Expanded(
                                  flex: 10,
                                  child: _AuthFormPanel(
                                    compact: false,
                                    title: title,
                                    subtitle: subtitle,
                                    footer: footer,
                                    child: child,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: <Widget>[
                                const _AuthFeaturePanel(compact: true),
                                _AuthFormPanel(
                                  compact: true,
                                  title: title,
                                  subtitle: subtitle,
                                  footer: footer,
                                  child: child,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _AuthFeaturePanel extends StatelessWidget {
  const _AuthFeaturePanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.sizeOf(context).width < 520;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? (isPhone ? 16 : 20) : 40,
        compact ? (isPhone ? 16 : 20) : 40,
        compact ? (isPhone ? 16 : 20) : 40,
        compact ? (isPhone ? 18 : 22) : 40,
      ),
      decoration: const BoxDecoration(gradient: VideoFeatureTheme.heroGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              BrandMark(size: compact ? (isPhone ? 38 : 42) : 54),
              SizedBox(width: compact ? (isPhone ? 10 : 12) : 14),
              Text(
                'bloop',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.96),
                  fontSize: compact ? (isPhone ? 18 : 20) : 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? (isPhone ? 14 : 18) : 40),
          Text(
            'Record with clarity.',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? (isPhone ? 18 : 22) : 42,
              fontWeight: FontWeight.w700,
              height: 1.06,
              letterSpacing: -1.3,
            ),
          ),
          SizedBox(height: compact ? (isPhone ? 8 : 10) : 16),
          Text(
            'Screen, camera, mic.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: compact ? (isPhone ? 12 : 13) : 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: compact ? (isPhone ? 12 : 16) : 34),
          _AuthPreviewPanel(compact: compact),
          if (!compact) ...<Widget>[
            const SizedBox(height: 22),
            Text(
              'Fast setup. Clean capture.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.76),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuthPreviewPanel extends StatelessWidget {
  const _AuthPreviewPanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.sizeOf(context).width < 520;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? (isPhone ? 12 : 14) : 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? (isPhone ? 20 : 24) : 32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const _PreviewDot(color: Color(0xFFFF7A59)),
              const SizedBox(width: 8),
              const _PreviewDot(color: Color(0xFFE8BC67)),
              const SizedBox(width: 8),
              const _PreviewDot(color: Color(0xFF3DDC97)),
              const Spacer(),
              _PreviewBadge(label: compact ? 'REC' : 'LIVE'),
            ],
          ),
          SizedBox(height: compact ? (isPhone ? 10 : 12) : 18),
          Container(
            height: compact ? (isPhone ? 82 : 96) : 188,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(
                compact ? (isPhone ? 16 : 20) : 28,
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  right: -10,
                  top: -16,
                  child: Container(
                    width: compact ? 58 : 118,
                    height: compact ? 58 : 118,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: compact ? 48 : 84,
                    height: compact ? 48 : 84,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: compact ? 28 : 34,
                    ),
                  ),
                ),
                Positioned(
                  left: compact ? 12 : 16,
                  right: compact ? 12 : 16,
                  bottom: compact ? 12 : 16,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          height: compact ? 8 : 10,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: compact ? 24 : 42,
                        height: compact ? 8 : 10,
                        decoration: BoxDecoration(
                          color: VideoFeatureTheme.focus.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? (isPhone ? 8 : 10) : 16),
          Row(
            children: const <Widget>[
              Expanded(
                child: _PreviewToggle(
                  icon: Icons.web_asset_rounded,
                  label: 'Screen',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _PreviewToggle(
                  icon: Icons.videocam_rounded,
                  label: 'Cam',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _PreviewToggle(icon: Icons.mic_rounded, label: 'Mic'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewDot extends StatelessWidget {
  const _PreviewDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _PreviewToggle extends StatelessWidget {
  const _PreviewToggle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool iconOnly = constraints.maxWidth < 84;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Icon(icon, color: Colors.white, size: 16),
              if (!iconOnly) ...<Widget>[
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AuthFormPanel extends StatelessWidget {
  const _AuthFormPanel({
    required this.compact,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  });

  final bool compact;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.sizeOf(context).width < 520;
    return Container(
      width: double.infinity,
      color: VideoFeatureTheme.panel,
      padding: EdgeInsets.all(compact ? (isPhone ? 18 : 24) : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          BrandMark(size: isPhone ? 24 : 28),
          SizedBox(height: isPhone ? 16 : 20),
          Text(
            title,
            style: TextStyle(
              color: VideoFeatureTheme.ink,
              fontSize: compact ? (isPhone ? 24 : 30) : 34,
              fontWeight: FontWeight.w700,
              height: 1.05,
              letterSpacing: -1.2,
            ),
          ),
          SizedBox(height: isPhone ? 8 : 10),
          Text(
            subtitle,
            style: TextStyle(
              color: VideoFeatureTheme.muted,
              fontSize: isPhone ? 14 : 15,
              height: 1.5,
            ),
          ),
          SizedBox(height: compact ? (isPhone ? 18 : 24) : 28),
          child,
          SizedBox(height: isPhone ? 18 : 24),
          Align(alignment: Alignment.center, child: footer),
        ],
      ),
    );
  }
}

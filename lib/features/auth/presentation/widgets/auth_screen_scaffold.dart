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
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: VideoFeatureTheme.line),
                      boxShadow: VideoFeatureTheme.panelShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 24 : 36,
        compact ? 24 : 36,
        compact ? 24 : 36,
        compact ? 28 : 36,
      ),
      decoration: const BoxDecoration(gradient: VideoFeatureTheme.heroGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const BrandMark(size: 54),
              const SizedBox(width: 14),
              Text(
                'bloop studio',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.96),
                  fontSize: compact ? 22 : 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 26 : 40),
          Text(
            'Screen, camera, and voice capture in one place.',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 28 : 40,
              fontWeight: FontWeight.w700,
              height: 1.06,
              letterSpacing: -1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start fast. Save locally. Share when ready.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 16,
              height: 1.6,
            ),
          ),
          SizedBox(height: compact ? 20 : 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const <Widget>[
              _FeatureChip(
                icon: Icons.screen_share_rounded,
                label: 'Screen + camera',
              ),
              _FeatureChip(
                icon: Icons.folder_open_rounded,
                label: 'Saved library',
              ),
            ],
          ),
          SizedBox(height: compact ? 20 : 28),
          const Wrap(
            spacing: 18,
            runSpacing: 12,
            children: <Widget>[
              _StoryMetric(value: '1 click', label: 'to record'),
              _StoryMetric(value: '5 min', label: 'default limit'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryMetric extends StatelessWidget {
  const _StoryMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: VideoFeatureTheme.focus,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
            children: <TextSpan>[
              TextSpan(
                text: '$value ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: label),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthFormPanel extends StatelessWidget {
  const _AuthFormPanel({
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
    return Container(
      width: double.infinity,
      color: VideoFeatureTheme.panel,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: VideoFeatureTheme.accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'bloop',
              style: TextStyle(
                color: VideoFeatureTheme.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: VideoFeatureTheme.ink,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.05,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              color: VideoFeatureTheme.muted,
              fontSize: 16,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 30),
          child,
          const SizedBox(height: 24),
          Align(alignment: Alignment.center, child: footer),
        ],
      ),
    );
  }
}

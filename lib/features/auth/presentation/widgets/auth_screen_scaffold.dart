import 'package:flutter/material.dart';

import '../../../video/presentation/controller/video_feature_theme.dart';

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
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: VideoFeatureTheme.screenBackground,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: VideoFeatureTheme.line),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x120B1326),
                        blurRadius: 28,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              VideoFeatureTheme.primary,
                              VideoFeatureTheme.accent,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_open_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        style: const TextStyle(
                          color: VideoFeatureTheme.ink,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: VideoFeatureTheme.muted,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      child,
                      const SizedBox(height: 20),
                      Align(alignment: Alignment.center, child: footer),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

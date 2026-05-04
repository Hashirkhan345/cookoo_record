import 'package:flutter/material.dart';

import '../controller/video_feature_theme.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
  });

  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.sizeOf(context).width < 600;

    return Container(
      constraints: BoxConstraints(minHeight: isPhone ? 180 : 220),
      padding: EdgeInsets.fromLTRB(
        isPhone ? 20 : 30,
        isPhone ? 22 : 30,
        isPhone ? 20 : 30,
        isPhone ? 22 : 30,
      ),
      decoration: BoxDecoration(
        color: VideoFeatureTheme.panelFor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VideoFeatureTheme.lineFor(context)),
      ),
      child: _HeroPanel(
        title: title,
        subtitle: subtitle,
        primaryActionLabel: primaryActionLabel,
        onPrimaryAction: onPrimaryAction,
        isPhone: isPhone,
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    required this.isPhone,
  });

  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final bool isPhone;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: VideoFeatureTheme.inkFor(context),
                fontSize: isPhone ? 30 : 40,
                fontWeight: FontWeight.w800,
                height: 1.02,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: VideoFeatureTheme.mutedFor(context),
                fontSize: isPhone ? 15 : 16,
                height: 1.55,
              ),
            ),
            SizedBox(height: isPhone ? 20 : 24),
            FilledButton.icon(
              key: const Key('recordVideoButton'),
              onPressed: onPrimaryAction,
              icon: const Icon(Icons.videocam_rounded),
              label: Text(primaryActionLabel),
              style: FilledButton.styleFrom(
                backgroundColor: VideoFeatureTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 54),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

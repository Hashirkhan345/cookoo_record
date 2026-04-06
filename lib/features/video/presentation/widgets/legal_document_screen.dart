import 'package:flutter/material.dart';

import '../controller/video_feature_theme.dart';

@immutable
class LegalDocumentSection {
  const LegalDocumentSection({required this.heading, required this.body});

  final String heading;
  final String body;
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.effectiveDateLabel,
    required this.icon,
    required this.heroColor,
    required this.highlights,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final String effectiveDateLabel;
  final IconData icon;
  final Color heroColor;
  final List<String> highlights;
  final List<LegalDocumentSection> sections;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isDesktop = screenWidth >= 1100;
    final bool isTablet = screenWidth >= 760;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFF7F7F4)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  color: heroColor,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          18,
                          24,
                          isTablet ? 44 : 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Back'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0x4DFFFFFF),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 40 : 26),
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.24),
                                ),
                              ),
                              child: Icon(icon, color: Colors.white, size: 34),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 46 : 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.4,
                                height: 1.04,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              effectiveDateLabel,
                              style: const TextStyle(
                                color: Color(0xE6FFFFFF),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: Text(
                                subtitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  height: 1.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SizedBox(
                                  width: 260,
                                  child: _LegalSideRail(
                                    title: title,
                                    effectiveDateLabel: effectiveDateLabel,
                                    highlights: highlights,
                                    sections: sections,
                                  ),
                                ),
                                const SizedBox(width: 34),
                                Expanded(
                                  child: _LegalDocumentCard(
                                    title: title,
                                    sections: sections,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _LegalSideRail(
                                  title: title,
                                  effectiveDateLabel: effectiveDateLabel,
                                  highlights: highlights,
                                  sections: sections,
                                  compact: true,
                                ),
                                const SizedBox(height: 20),
                                _LegalDocumentCard(
                                  title: title,
                                  sections: sections,
                                ),
                              ],
                            ),
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

class _LegalSideRail extends StatelessWidget {
  const _LegalSideRail({
    required this.title,
    required this.effectiveDateLabel,
    required this.highlights,
    required this.sections,
    this.compact = false,
  });

  final String title;
  final String effectiveDateLabel;
  final List<String> highlights;
  final List<LegalDocumentSection> sections;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SideRailCard(
          title: 'Document',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: VideoFeatureTheme.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                effectiveDateLabel,
                style: const TextStyle(
                  color: VideoFeatureTheme.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 16 : 18),
        _SideRailCard(
          title: 'Applies to',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: highlights
                .map(
                  (String item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: const BoxDecoration(
                            color: VideoFeatureTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: VideoFeatureTheme.ink,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        SizedBox(height: compact ? 16 : 18),
        _SideRailCard(
          title: 'On this page',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sections.asMap().entries.map((
              MapEntry<int, LegalDocumentSection> entry,
            ) {
              final int index = entry.key + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '$index. ${entry.value.heading}',
                  style: const TextStyle(
                    color: VideoFeatureTheme.muted,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SideRailCard extends StatelessWidget {
  const _SideRailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE8E5DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: VideoFeatureTheme.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LegalDocumentCard extends StatelessWidget {
  const _LegalDocumentCard({required this.title, required this.sections});

  final String title;
  final List<LegalDocumentSection> sections;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE8E5DE)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x080B1326),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: VideoFeatureTheme.ink,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 20),
          ...sections.asMap().entries.map((
            MapEntry<int, LegalDocumentSection> entry,
          ) {
            final int index = entry.key + 1;
            final LegalDocumentSection section = entry.value;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == sections.length ? 0 : 30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '$index. ${section.heading}',
                    style: const TextStyle(
                      color: VideoFeatureTheme.ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    section.body,
                    style: const TextStyle(
                      color: VideoFeatureTheme.muted,
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),
                  if (index != sections.length) ...<Widget>[
                    const SizedBox(height: 26),
                    const Divider(color: Color(0xFFEAE7E0), thickness: 1),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

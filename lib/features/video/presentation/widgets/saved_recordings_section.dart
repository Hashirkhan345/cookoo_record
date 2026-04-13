import 'package:flutter/material.dart';

import '../../../auth/data/models/app_user.dart';
import '../../data/models/saved_video_recording_model.dart';
import '../controller/video_feature_theme.dart';
import 'saved_recording_card.dart';

class SavedRecordingsSection extends StatelessWidget {
  const SavedRecordingsSection({
    super.key,
    required this.recordings,
    required this.currentUser,
    required this.onDeleteRecording,
    required this.onStartRecording,
  });

  final List<SavedVideoRecordingModel> recordings;
  final AppUser? currentUser;
  final ValueChanged<SavedVideoRecordingModel> onDeleteRecording;
  final VoidCallback onStartRecording;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final List<SavedVideoRecordingModel> sortedRecordings = recordings.toList()
      ..sort(
        (SavedVideoRecordingModel a, SavedVideoRecordingModel b) =>
            b.savedAt.compareTo(a.savedAt),
      );

    if (sortedRecordings.isEmpty) {
      return EmptySavedRecordingsExperience(
        key: const Key('emptySavedRecordingsState'),
        onStartRecording: onStartRecording,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 980),
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: VideoFeatureTheme.line),
          boxShadow: VideoFeatureTheme.floatingShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool stackHeader = constraints.maxWidth < 760;
                final Widget titleBlock = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Recording library',
                      style: textTheme.headlineMedium?.copyWith(fontSize: 34),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Saved clips.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: VideoFeatureTheme.muted,
                        fontSize: 15,
                      ),
                    ),
                  ],
                );
                final Widget chips = Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    _HeaderChip(label: '${sortedRecordings.length} Saved'),
                    const _HeaderChip(
                      label: 'Newest first',
                      icon: Icons.schedule,
                    ),
                  ],
                );

                if (stackHeader) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      titleBlock,
                      const SizedBox(height: 18),
                      chips,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(child: titleBlock),
                    const SizedBox(width: 16),
                    chips,
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const double spacing = 22;
                final bool isSingleColumn = constraints.maxWidth < 760;
                final double cardWidth = isSingleColumn
                    ? constraints.maxWidth
                    : (constraints.maxWidth - spacing) / 2;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: sortedRecordings
                      .map((SavedVideoRecordingModel recording) {
                        return SizedBox(
                          width: cardWidth,
                          child: SavedRecordingCard(
                            key: Key('savedRecordingCard_${recording.id}'),
                            recording: recording,
                            currentUser: currentUser,
                            onDelete: () => onDeleteRecording(recording),
                          ),
                        );
                      })
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: VideoFeatureTheme.panel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VideoFeatureTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, color: VideoFeatureTheme.muted, size: 16),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              color: VideoFeatureTheme.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptySavedRecordingsExperience extends StatelessWidget {
  const EmptySavedRecordingsExperience({
    super.key,
    required this.onStartRecording,
  });

  final VoidCallback onStartRecording;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 780;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 8),
        child: Column(
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: <Widget>[
                  Text(
                    'Hassle-free video communication,\nno need to install',
                    textAlign: TextAlign.center,
                    style: textTheme.displayMedium?.copyWith(
                      fontSize: compact ? 30 : 48,
                    ),
                  ),
                  SizedBox(height: compact ? 14 : 18),
                  Text(
                    'Start recording instantly, keep your workspace clean, and let Firebase videos appear below when your library begins to fill.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: VideoFeatureTheme.muted,
                      fontSize: compact ? 15 : 18,
                    ),
                  ),
                  SizedBox(height: compact ? 22 : 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    runSpacing: 14,
                    children: <Widget>[
                      FilledButton(
                        onPressed: onStartRecording,
                        style: FilledButton.styleFrom(
                          backgroundColor: VideoFeatureTheme.accent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 22 : 28,
                            vertical: compact ? 16 : 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontFamily: VideoFeatureTheme.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Intro preview will be added here.',
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: VideoFeatureTheme.accent,
                          side: const BorderSide(
                            color: VideoFeatureTheme.lineStrong,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 20 : 26,
                            vertical: compact ? 16 : 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.play_arrow_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Watch Intro',
                              style: TextStyle(
                                fontFamily: VideoFeatureTheme.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 20 : 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 22,
                    runSpacing: 12,
                    children: const <Widget>[
                      _FeaturePoint(label: 'Auto video encoding'),
                      _FeaturePoint(label: 'Easy to use'),
                      _FeaturePoint(label: 'Complete controls'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 26 : 34),
            _EmptyFirebasePreview(compact: compact),
          ],
        ),
      ),
    );
  }
}

class _FeaturePoint extends StatelessWidget {
  const _FeaturePoint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: VideoFeatureTheme.focus,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: VideoFeatureTheme.muted,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyFirebasePreview extends StatelessWidget {
  const _EmptyFirebasePreview({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Widget overview = Container(
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VideoFeatureTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: VideoFeatureTheme.panelMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.search_rounded, color: VideoFeatureTheme.muted),
                const SizedBox(width: 10),
                const Text(
                  'Search recordings',
                  style: TextStyle(
                    color: VideoFeatureTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: VideoFeatureTheme.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'New Request',
                    style: TextStyle(
                      color: VideoFeatureTheme.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 16 : 18),
          if (compact)
            Column(
              children: <Widget>[
                const _PreviewMetricRow(),
                const SizedBox(height: 16),
                _PreviewVideoPlaceholder(compact: compact),
                const SizedBox(height: 16),
                const _PreviewListPlaceholder(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Expanded(flex: 3, child: _PreviewMetricRow()),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: _PreviewVideoPlaceholder(compact: compact),
                ),
                const SizedBox(width: 16),
                const Expanded(flex: 3, child: _PreviewListPlaceholder()),
              ],
            ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2530),
        borderRadius: BorderRadius.circular(compact ? 24 : 28),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1A0F2530),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: overview,
    );
  }
}

class _PreviewMetricRow extends StatelessWidget {
  const _PreviewMetricRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(3, (int index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 2 ? 0 : 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VideoFeatureTheme.panelMuted,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  index == 0
                      ? 'Total users'
                      : index == 1
                      ? 'Monthly active'
                      : 'Contributing',
                  style: const TextStyle(
                    color: VideoFeatureTheme.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  index == 0
                      ? '84,573'
                      : index == 1
                      ? '62,405'
                      : '48,413',
                  style: const TextStyle(
                    color: VideoFeatureTheme.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _PreviewVideoPlaceholder extends StatelessWidget {
  const _PreviewVideoPlaceholder({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 220 : 286,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            VideoFeatureTheme.canvasShade,
            VideoFeatureTheme.panelMuted,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Firebase videos',
            style: TextStyle(
              color: VideoFeatureTheme.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Empty container until remote clips load.',
            style: TextStyle(
              color: VideoFeatureTheme.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            height: compact ? 116 : 154,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_outline_rounded,
                size: 44,
                color: VideoFeatureTheme.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewListPlaceholder extends StatelessWidget {
  const _PreviewListPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: VideoFeatureTheme.panelMuted,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List<Widget>.generate(4, (int index) {
          return Container(
            margin: EdgeInsets.only(bottom: index == 3 ? 0 : 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VideoFeatureTheme.line),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: VideoFeatureTheme.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.video_library_rounded,
                    color: VideoFeatureTheme.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Video slot',
                        style: TextStyle(
                          color: VideoFeatureTheme.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Waiting for Firebase content',
                        style: TextStyle(
                          color: VideoFeatureTheme.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../auth/data/models/app_user.dart';
import '../../data/models/admin_config_model.dart';
import '../../data/models/saved_video_recording_model.dart';
import '../controller/video_feature_theme.dart';
import 'saved_recording_player.dart';
import 'saved_recording_card.dart';

class SavedRecordingsSection extends StatelessWidget {
  const SavedRecordingsSection({
    super.key,
    required this.recordings,
    required this.currentUser,
    required this.adminConfig,
    required this.savedCountLabel,
    required this.onDeleteRecording,
    required this.onStartRecording,
  });

  final List<SavedVideoRecordingModel> recordings;
  final AppUser? currentUser;
  final AdminConfigModel? adminConfig;
  final String savedCountLabel;
  final ValueChanged<SavedVideoRecordingModel> onDeleteRecording;
  final VoidCallback? onStartRecording;

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
        config: adminConfig ?? AdminConfigModel.defaults,
        onStartRecording: onStartRecording,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1240),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool stackHeader = constraints.maxWidth < 640;
              final Widget title = Text(
                'Video library',
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              );
              final Widget chip = _SavedCountChip(label: savedCountLabel);

              if (stackHeader) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[title, const SizedBox(height: 8), chip],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: title),
                  const SizedBox(width: 12),
                  chip,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              const double spacing = 22;
              final int columnCount = constraints.maxWidth >= 1080
                  ? 3
                  : constraints.maxWidth >= 760
                  ? 2
                  : 1;
              double cardWidth =
                  (constraints.maxWidth - (spacing * (columnCount - 1))) /
                  columnCount;

              if (columnCount == 1) {
                cardWidth = cardWidth.clamp(0, 340);
              }

              return Wrap(
                alignment: columnCount == 1
                    ? WrapAlignment.center
                    : WrapAlignment.start,
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
    );
  }
}

class _SavedCountChip extends StatelessWidget {
  const _SavedCountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VideoFeatureTheme.line),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: VideoFeatureTheme.ink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class EmptySavedRecordingsExperience extends StatelessWidget {
  const EmptySavedRecordingsExperience({
    super.key,
    required this.config,
    required this.onStartRecording,
  });

  final AdminConfigModel config;
  final VoidCallback? onStartRecording;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 780;
    final bool isPhone = MediaQuery.sizeOf(context).width < 520;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? (isPhone ? 0 : 0) : 8,
        ),
        child: Column(
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: <Widget>[
                  Text(
                    config.title,
                    textAlign: TextAlign.center,
                    style: textTheme.displayMedium?.copyWith(
                      fontSize: compact ? (isPhone ? 24 : 30) : 48,
                    ),
                  ),
                  SizedBox(height: compact ? (isPhone ? 10 : 14) : 18),
                  Text(
                    config.subtitle,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: VideoFeatureTheme.muted,
                      fontSize: compact ? (isPhone ? 13 : 15) : 18,
                      height: isPhone ? 1.45 : null,
                    ),
                  ),
                  SizedBox(height: compact ? (isPhone ? 16 : 22) : 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: isPhone ? 10 : 14,
                    runSpacing: isPhone ? 10 : 14,
                    children: <Widget>[
                      FilledButton(
                        onPressed: onStartRecording,
                        style: FilledButton.styleFrom(
                          backgroundColor: VideoFeatureTheme.accent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? (isPhone ? 18 : 22) : 28,
                            vertical: compact ? (isPhone ? 14 : 16) : 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              config.primaryActionLabel,
                              style: TextStyle(
                                fontFamily: VideoFeatureTheme.fontFamily,
                                fontSize: isPhone ? 14 : 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: config.hasDemoVideo
                            ? () {
                                SavedRecordingPlayer.showFullscreenDialog(
                                  context,
                                  recording: config.toDemoRecording(),
                                  autoplayMuted: false,
                                );
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Demo video is not configured yet.',
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
                            horizontal: compact ? (isPhone ? 16 : 20) : 26,
                            vertical: compact ? (isPhone ? 14 : 16) : 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.play_arrow_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              config.secondaryActionLabel,
                              style: TextStyle(
                                fontFamily: VideoFeatureTheme.fontFamily,
                                fontSize: isPhone ? 14 : 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? (isPhone ? 14 : 20) : 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: isPhone ? 14 : 22,
                    runSpacing: isPhone ? 10 : 12,
                    children: config.featurePoints
                        .map((String label) => _FeaturePoint(label: label))
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? (isPhone ? 18 : 26) : 34),
            _EmptyFirebasePreview(compact: compact, config: config),
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
    final bool isPhone = MediaQuery.sizeOf(context).width < 520;
    return Container(
      constraints: BoxConstraints(maxWidth: isPhone ? 160 : 220),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: isPhone ? 22 : 26,
            height: isPhone ? 22 : 26,
            decoration: const BoxDecoration(
              color: VideoFeatureTheme.focus,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: isPhone ? 14 : 16,
            ),
          ),
          SizedBox(width: isPhone ? 8 : 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: VideoFeatureTheme.muted,
                fontSize: isPhone ? 13 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFirebasePreview extends StatelessWidget {
  const _EmptyFirebasePreview({required this.compact, required this.config});

  final bool compact;
  final AdminConfigModel config;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.sizeOf(context).width < 520;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? (isPhone ? 10 : 14) : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2530),
        borderRadius: BorderRadius.circular(compact ? (isPhone ? 18 : 24) : 28),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1A0F2530),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: _PreviewVideoPlaceholder(compact: compact, config: config),
    );
  }
}

class _PreviewVideoPlaceholder extends StatelessWidget {
  const _PreviewVideoPlaceholder({required this.compact, required this.config});

  final bool compact;
  final AdminConfigModel config;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.sizeOf(context).width < 520;
    final double radius = compact ? (isPhone ? 14 : 18) : 20;
    final double videoHeight = compact ? (isPhone ? 200 : 240) : 500;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: double.infinity,
        height: videoHeight,
        child: config.hasDemoVideo
            ? SavedRecordingPlayer(recording: config.toDemoRecording())
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      VideoFeatureTheme.canvasShade,
                      VideoFeatureTheme.panelMuted,
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    size: 44,
                    color: VideoFeatureTheme.accent,
                  ),
                ),
              ),
      ),
    );
  }
}

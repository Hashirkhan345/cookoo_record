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
  });

  final List<SavedVideoRecordingModel> recordings;
  final AppUser? currentUser;
  final ValueChanged<SavedVideoRecordingModel> onDeleteRecording;

  @override
  Widget build(BuildContext context) {
    final List<SavedVideoRecordingModel> sortedRecordings = recordings.toList()
      ..sort(
        (SavedVideoRecordingModel a, SavedVideoRecordingModel b) =>
            b.savedAt.compareTo(a.savedAt),
      );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 980),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Videos',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              _HeaderChip(label: '${sortedRecordings.length} Saved'),
              const SizedBox(width: 12),
              const _HeaderChip(label: 'Newest first', icon: Icons.schedule),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Your latest captures live here with quick preview, sharing, and download actions.',
            style: TextStyle(
              color: VideoFeatureTheme.muted,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          if (sortedRecordings.isEmpty)
            Container(
              key: const Key('emptySavedRecordingsState'),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: VideoFeatureTheme.line),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x120B1326),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: const Row(
                children: <Widget>[
                  _EmptyStateArtwork(),
                  SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'No recordings saved yet',
                          style: TextStyle(
                            color: VideoFeatureTheme.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Finish a capture and it will appear here as a preview card with quick actions.',
                          style: TextStyle(
                            color: VideoFeatureTheme.muted,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
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
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
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

class _EmptyStateArtwork extends StatelessWidget {
  const _EmptyStateArtwork();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFDCE8FF), Color(0xFFF4F7FF)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: VideoFeatureTheme.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          Positioned(
            left: 16,
            top: 18,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: VideoFeatureTheme.primary.withValues(alpha: 0.8),
              size: 18,
            ),
          ),
          Positioned(
            right: 16,
            bottom: 18,
            child: Icon(
              Icons.video_collection_outlined,
              color: VideoFeatureTheme.muted,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

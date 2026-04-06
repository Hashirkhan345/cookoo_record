import 'package:flutter/material.dart';

import '../../data/models/saved_video_recording_model.dart';
import '../controller/video_feature_theme.dart';
import 'saved_recording_card.dart';

class SavedRecordingsSection extends StatelessWidget {
  const SavedRecordingsSection({
    super.key,
    required this.recordings,
    required this.storageLocationLabel,
    required this.onDeleteRecording,
  });

  final List<SavedVideoRecordingModel> recordings;
  final String? storageLocationLabel;
  final ValueChanged<SavedVideoRecordingModel> onDeleteRecording;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 920),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Saved recordings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            storageLocationLabel == null || storageLocationLabel!.isEmpty
                ? 'Your saved videos will appear here after recording.'
                : 'Stored in $storageLocationLabel',
            style: const TextStyle(
              color: VideoFeatureTheme.muted,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          if (recordings.isEmpty)
            Container(
              key: const Key('emptySavedRecordingsState'),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: VideoFeatureTheme.line),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(
                    Icons.video_collection_outlined,
                    color: VideoFeatureTheme.primary,
                    size: 28,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'No recordings saved yet. Stop a recording to add it here.',
                      style: TextStyle(
                        color: VideoFeatureTheme.muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: recordings.map((SavedVideoRecordingModel recording) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SavedRecordingCard(
                    key: Key('savedRecordingCard_${recording.id}'),
                    recording: recording,
                    onDelete: () => onDeleteRecording(recording),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

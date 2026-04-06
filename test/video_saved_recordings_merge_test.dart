import 'package:flutter_test/flutter_test.dart';

import 'package:bloop/features/video/data/enums/video_recording_storage_kind.dart';
import 'package:bloop/features/video/data/models/saved_video_recording_model.dart';
import 'package:bloop/features/video/provider/video_saved_recordings_merge.dart';

void main() {
  test(
    'mergeSavedRecordingIntoList keeps older items and prepends the new one',
    () {
      final SavedVideoRecordingModel olderRecording = SavedVideoRecordingModel(
        id: 'older',
        fileName: 'older.webm',
        savedAt: DateTime(2026, 3, 13, 12, 0),
        duration: const Duration(seconds: 8),
        storageKind: VideoRecordingStorageKind.browserLocalStorage,
        storagePath: 'video_saved_recording_data_older',
        playbackPath: 'blob:older',
        mimeType: 'video/webm',
        sizeInBytes: 1024,
      );

      final SavedVideoRecordingModel newestRecording = SavedVideoRecordingModel(
        id: 'newest',
        fileName: 'newest.webm',
        savedAt: DateTime(2026, 3, 13, 12, 5),
        duration: const Duration(seconds: 10),
        storageKind: VideoRecordingStorageKind.browserLocalStorage,
        storagePath: 'video_saved_recording_data_newest',
        playbackPath: 'blob:newest',
        mimeType: 'video/webm',
        sizeInBytes: 2048,
      );

      final List<SavedVideoRecordingModel> mergedRecordings =
          mergeSavedRecordingIntoList(
            newestRecording,
            <SavedVideoRecordingModel>[olderRecording],
          );

      expect(mergedRecordings, hasLength(2));
      expect(mergedRecordings.first.id, newestRecording.id);
      expect(mergedRecordings.last.id, olderRecording.id);
    },
  );
}

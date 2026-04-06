import '../data/models/saved_video_recording_model.dart';

List<SavedVideoRecordingModel> mergeSavedRecordingIntoList(
  SavedVideoRecordingModel savedRecording,
  List<SavedVideoRecordingModel> existingRecordings,
) {
  final List<SavedVideoRecordingModel> mergedRecordings =
      <SavedVideoRecordingModel>[
        savedRecording,
        ...existingRecordings.where(
          (SavedVideoRecordingModel recording) =>
              recording.id != savedRecording.id,
        ),
      ];

  mergedRecordings.sort(
    (SavedVideoRecordingModel a, SavedVideoRecordingModel b) =>
        b.savedAt.compareTo(a.savedAt),
  );

  return mergedRecordings;
}

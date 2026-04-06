import '../../data/models/saved_video_recording_model.dart';

Future<String> downloadSavedRecording(
  SavedVideoRecordingModel recording,
) async {
  return 'Recording is stored at ${recording.storageSummary}.';
}

Future<String> shareSavedRecording(SavedVideoRecordingModel recording) async {
  return 'Sharing is not available on this platform yet.';
}

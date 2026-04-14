import 'package:camera/camera.dart';

import '../models/saved_video_recording_model.dart';

abstract class VideoRecordingStorage {
  Future<String> getStorageLocationLabel();

  Future<List<SavedVideoRecordingModel>> loadSavedRecordings();

  Future<int> loadLifetimeRecordingCount();

  Future<SavedVideoRecordingModel> saveRecording(
    XFile recordedVideo, {
    required Duration duration,
  });

  Future<void> deleteSavedRecording(SavedVideoRecordingModel recording);

  Future<void> clearSavedRecordings();
}

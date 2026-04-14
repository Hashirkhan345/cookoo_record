import 'package:camera/camera.dart';

import '../models/saved_video_recording_model.dart';
import 'video_recording_storage_contract.dart';

VideoRecordingStorage createVideoRecordingStorage() {
  return const _StubVideoRecordingStorage();
}

class _StubVideoRecordingStorage implements VideoRecordingStorage {
  const _StubVideoRecordingStorage();

  @override
  Future<String> getStorageLocationLabel() async {
    return 'Unsupported storage';
  }

  @override
  Future<List<SavedVideoRecordingModel>> loadSavedRecordings() async {
    return const <SavedVideoRecordingModel>[];
  }

  @override
  Future<int> loadLifetimeRecordingCount() async {
    return 0;
  }

  @override
  Future<SavedVideoRecordingModel> saveRecording(
    XFile recordedVideo, {
    required Duration duration,
  }) {
    throw UnsupportedError('Video recording storage is not available.');
  }

  @override
  Future<void> deleteSavedRecording(SavedVideoRecordingModel recording) async {}

  @override
  Future<void> clearSavedRecordings() async {}
}

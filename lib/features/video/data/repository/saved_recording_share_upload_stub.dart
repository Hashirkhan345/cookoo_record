import 'package:firebase_storage/firebase_storage.dart';

import '../models/saved_video_recording_model.dart';

Future<String> uploadSavedRecordingAndGetDownloadUrl(
  Reference ref,
  SavedVideoRecordingModel recording,
) {
  throw UnsupportedError('Uploading saved recordings is not available.');
}

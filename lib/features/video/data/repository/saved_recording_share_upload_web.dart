import 'package:firebase_storage/firebase_storage.dart';

import '../models/saved_video_recording_model.dart';
import 'saved_recording_upload_source_web.dart';

Future<String> uploadSavedRecordingAndGetDownloadUrl(
  Reference ref,
  SavedVideoRecordingModel recording,
) async {
  final bytes = await loadSavedRecordingUploadBytes(recording);
  await ref.putData(
    bytes,
    SettableMetadata(
      contentType: recording.mimeType,
      customMetadata: <String, String>{
        'recordingId': recording.id,
        'fileName': recording.fileName,
      },
    ),
  );
  return ref.getDownloadURL();
}

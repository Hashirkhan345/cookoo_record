import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../models/saved_video_recording_model.dart';

Future<String> uploadSavedRecordingAndGetDownloadUrl(
  Reference ref,
  SavedVideoRecordingModel recording,
) async {
  final File file = File(recording.storagePath);
  await ref.putFile(
    file,
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

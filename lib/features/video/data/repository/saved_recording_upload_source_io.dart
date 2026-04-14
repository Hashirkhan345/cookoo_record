import 'dart:io';
import 'dart:typed_data';

import '../models/saved_video_recording_model.dart';

Future<Uint8List> loadSavedRecordingUploadBytes(
  SavedVideoRecordingModel recording,
) async {
  return File(recording.storagePath).readAsBytes();
}

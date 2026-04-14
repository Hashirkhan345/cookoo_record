// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';

import '../models/saved_video_recording_model.dart';

Future<Uint8List> loadSavedRecordingUploadBytes(
  SavedVideoRecordingModel recording,
) async {
  final html.HttpRequest request = await html.HttpRequest.request(
    recording.playbackPath,
    responseType: 'arraybuffer',
  );
  final Object? response = request.response;
  if (response is ByteBuffer) {
    return Uint8List.view(response);
  }
  if (response is Uint8List) {
    return response;
  }
  throw StateError('Unable to read this recording for upload.');
}

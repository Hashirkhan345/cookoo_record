import 'dart:io';

import 'package:flutter/services.dart';

import '../../data/models/saved_video_recording_model.dart';

const MethodChannel _videoTransferChannel = MethodChannel(
  'bloop/video_transfer',
);

Future<String> downloadSavedRecording(
  SavedVideoRecordingModel recording,
) async {
  if (Platform.isAndroid) {
    final String? result = await _videoTransferChannel
        .invokeMethod<String>('exportRecordingToDownloads', <String, String>{
          'path': recording.storagePath,
          'fileName': recording.fileName,
          'mimeType': recording.mimeType,
        });

    return result ??
        'Recording exported from app storage. Check your Downloads folder.';
  }

  return 'Recording is already saved on this device at ${recording.storageSummary}.';
}

Future<String> shareSavedRecording(SavedVideoRecordingModel recording) async {
  return 'Sharing is not available on this platform yet.';
}

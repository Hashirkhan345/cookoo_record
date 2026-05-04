import 'dart:io';

import 'package:flutter/services.dart';

import '../../data/models/saved_video_recording_model.dart';
import '../../data/repository/public_video_share_repository.dart';

const MethodChannel _videoTransferChannel = MethodChannel('Aks/video_transfer');

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
  final String url = await PublicVideoShareRepository().ensureShareUrl(
    recording,
  );
  await Clipboard.setData(ClipboardData(text: url));
  return 'Share link copied. Anyone with the link can view this recording.';
}

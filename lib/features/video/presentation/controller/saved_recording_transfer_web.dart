// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

import '../../data/models/saved_video_recording_model.dart';

Future<String> downloadSavedRecording(
  SavedVideoRecordingModel recording,
) async {
  final html.AnchorElement anchor =
      html.AnchorElement(href: recording.playbackPath)
        ..download = recording.fileName
        ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  return 'Downloading ${recording.fileName}.';
}

Future<String> shareSavedRecording(SavedVideoRecordingModel recording) async {
  final html.Blob blob = await _loadRecordingBlob(recording);
  final html.File file = html.File(
    <Object>[blob],
    recording.fileName,
    <String, Object>{'type': recording.mimeType},
  );

  try {
    await html.window.navigator.share(<String, Object>{
      'files': <html.File>[file],
      'title': recording.fileName,
      'text': 'Shared from bloop',
    });
    return 'Share sheet opened.';
  } catch (error) {
    final String message = error.toString();
    if (message.contains('AbortError')) {
      return 'Sharing cancelled.';
    }

    await downloadSavedRecording(recording);
    return 'Sharing is not available in this browser. Download started instead.';
  }
}

Future<html.Blob> _loadRecordingBlob(SavedVideoRecordingModel recording) async {
  final html.HttpRequest request = await html.HttpRequest.request(
    recording.playbackPath,
    responseType: 'blob',
  );
  final Object? response = request.response;
  if (response is html.Blob) {
    return response;
  }

  throw StateError('Unable to access this recording for sharing.');
}

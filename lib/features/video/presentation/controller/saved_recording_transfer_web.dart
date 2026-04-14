// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'package:flutter/services.dart';

import '../../data/models/saved_video_recording_model.dart';
import '../../data/repository/public_video_share_repository.dart';

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
  final String url = await PublicVideoShareRepository().ensureShareUrl(
    recording,
  );

  try {
    await html.window.navigator.share(<String, Object>{
      'title': recording.fileName,
      'text': 'Watch this bloop recording',
      'url': url,
    });
    return 'Share sheet opened.';
  } catch (error) {
    final String message = error.toString();
    if (message.contains('AbortError')) {
      return 'Sharing cancelled.';
    }

    await Clipboard.setData(ClipboardData(text: url));
    return 'Share link copied. Anyone with the link can view this recording.';
  }
}

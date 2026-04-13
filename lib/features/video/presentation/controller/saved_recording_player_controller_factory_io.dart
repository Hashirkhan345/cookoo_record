import 'dart:io';

import 'package:video_player/video_player.dart';

import '../../data/models/saved_video_recording_model.dart';

VideoPlayerController createSavedRecordingPlayerController(
  SavedVideoRecordingModel recording,
) {
  final Uri? playbackUri = Uri.tryParse(recording.playbackPath);
  final bool isRemoteSource =
      playbackUri != null &&
      (playbackUri.scheme == 'http' || playbackUri.scheme == 'https');

  if (isRemoteSource) {
    return VideoPlayerController.networkUrl(playbackUri);
  }

  return VideoPlayerController.file(File(recording.playbackPath));
}

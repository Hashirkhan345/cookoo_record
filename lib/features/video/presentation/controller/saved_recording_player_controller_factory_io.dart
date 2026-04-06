import 'dart:io';

import 'package:video_player/video_player.dart';

import '../../data/models/saved_video_recording_model.dart';

VideoPlayerController createSavedRecordingPlayerController(
  SavedVideoRecordingModel recording,
) {
  return VideoPlayerController.file(File(recording.playbackPath));
}

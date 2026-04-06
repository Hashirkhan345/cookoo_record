import 'package:video_player/video_player.dart';

import '../../data/models/saved_video_recording_model.dart';

VideoPlayerController createSavedRecordingPlayerController(
  SavedVideoRecordingModel recording,
) {
  return VideoPlayerController.networkUrl(Uri.parse(recording.playbackPath));
}

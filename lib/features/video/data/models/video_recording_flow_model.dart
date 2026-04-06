import 'package:flutter/foundation.dart';

import 'video_recording_option_model.dart';
import 'video_shortcut_model.dart';

@immutable
class VideoRecordingFlowModel {
  const VideoRecordingFlowModel({
    required this.brandLabel,
    required this.heroTitle,
    required this.heroDescription,
    required this.heroActionLabel,
    required this.helperMessage,
    required this.previewTitle,
    required this.startRecordingLabel,
    required this.recordingLimitLabel,
    required this.tutorialLabel,
    required this.successMessage,
    required this.panelOptions,
    required this.shortcuts,
  });

  final String brandLabel;
  final String heroTitle;
  final String heroDescription;
  final String heroActionLabel;
  final String helperMessage;
  final String previewTitle;
  final String startRecordingLabel;
  final String recordingLimitLabel;
  final String tutorialLabel;
  final String successMessage;
  final List<VideoRecordingOptionModel> panelOptions;
  final List<VideoShortcutModel> shortcuts;
}

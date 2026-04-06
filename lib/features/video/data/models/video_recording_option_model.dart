import 'package:flutter/foundation.dart';

import '../enums/video_recording_mode.dart';
import '../enums/video_recording_option_kind.dart';

@immutable
class VideoRecordingOptionModel {
  const VideoRecordingOptionModel({
    required this.kind,
    required this.label,
    this.status,
    this.highlighted = false,
    this.selectedRecordingMode,
  });

  final VideoRecordingOptionKind kind;
  final String label;
  final String? status;
  final bool highlighted;
  final VideoRecordingMode? selectedRecordingMode;
}

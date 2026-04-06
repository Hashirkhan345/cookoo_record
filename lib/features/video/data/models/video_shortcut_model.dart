import 'package:flutter/foundation.dart';

import '../enums/video_shortcut_type.dart';

@immutable
class VideoShortcutModel {
  const VideoShortcutModel({required this.type, required this.label});

  final VideoShortcutType type;
  final String label;
}

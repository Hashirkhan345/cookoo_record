import 'package:flutter/foundation.dart';

enum VideoRecordingMode { fullScreen, window, currentTab, cameraOnly }

extension VideoRecordingModeX on VideoRecordingMode {
  String get label {
    switch (this) {
      case VideoRecordingMode.fullScreen:
        return 'Full Screen';
      case VideoRecordingMode.window:
        return 'Window';
      case VideoRecordingMode.currentTab:
        return 'Current Tab';
      case VideoRecordingMode.cameraOnly:
        return 'Camera Only';
    }
  }

  bool get capturesDisplay => this != VideoRecordingMode.cameraOnly;

  bool get isSupportedOnCurrentPlatform =>
      supportedRecordingModesForCurrentPlatform().contains(this);
}

List<VideoRecordingMode> supportedRecordingModesForCurrentPlatform() {
  if (kIsWeb) {
    return VideoRecordingMode.values;
  }

  return const <VideoRecordingMode>[VideoRecordingMode.cameraOnly];
}

VideoRecordingMode defaultRecordingModeForCurrentPlatform() {
  if (kIsWeb) {
    return VideoRecordingMode.fullScreen;
  }

  return VideoRecordingMode.cameraOnly;
}

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
}

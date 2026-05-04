import 'package:camera/camera.dart';

import '../enums/video_recording_mode.dart';

abstract class BrowserVideoRecorder {
  bool get isSupported;

  void setExternalStopListener(void Function()? listener);

  Future<void> prepareRecording({
    required VideoRecordingMode mode,
    bool includeMicrophone = true,
  });

  Future<void> startPreparedRecording();

  Future<void> cancelPreparedRecording();

  Future<void> startRecording({
    required VideoRecordingMode mode,
    bool includeMicrophone = true,
  });

  Future<void> pauseRecording();

  Future<void> resumeRecording();

  Future<XFile> stopRecording();
}

BrowserVideoRecorder createBrowserVideoRecorder() {
  return const UnsupportedBrowserVideoRecorder();
}

class UnsupportedBrowserVideoRecorder implements BrowserVideoRecorder {
  const UnsupportedBrowserVideoRecorder();

  @override
  bool get isSupported => false;

  @override
  void setExternalStopListener(void Function()? listener) {}

  @override
  Future<void> prepareRecording({
    required VideoRecordingMode mode,
    bool includeMicrophone = true,
  }) async {
    throw UnsupportedError('Browser recording is not available.');
  }

  @override
  Future<void> startPreparedRecording() async {
    throw UnsupportedError('Browser recording is not available.');
  }

  @override
  Future<void> cancelPreparedRecording() async {}

  @override
  Future<void> startRecording({
    required VideoRecordingMode mode,
    bool includeMicrophone = true,
  }) async {
    throw UnsupportedError('Browser recording is not available.');
  }

  @override
  Future<void> pauseRecording() async {
    throw UnsupportedError('Browser recording is not available.');
  }

  @override
  Future<void> resumeRecording() async {
    throw UnsupportedError('Browser recording is not available.');
  }

  @override
  Future<XFile> stopRecording() async {
    throw UnsupportedError('Browser recording is not available.');
  }
}

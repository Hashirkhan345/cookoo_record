import 'package:camera/camera.dart';

abstract class NativeDisplayRecorder {
  bool get isSupported;

  Future<void> prepareRecording();

  Future<void> startPreparedRecording();

  Future<void> cancelPreparedRecording();

  Future<void> pauseRecording();

  Future<void> resumeRecording();

  Future<XFile> stopRecording();
}

import 'package:camera/camera.dart';

import 'native_display_recorder_contract.dart';

NativeDisplayRecorder createNativeDisplayRecorder() {
  return const UnsupportedNativeDisplayRecorder();
}

class UnsupportedNativeDisplayRecorder implements NativeDisplayRecorder {
  const UnsupportedNativeDisplayRecorder();

  @override
  bool get isSupported => false;

  @override
  Future<void> cancelPreparedRecording() async {}

  @override
  Future<void> pauseRecording() async {
    throw StateError('Native screen recording is not available.');
  }

  @override
  Future<void> prepareRecording() async {
    throw StateError('Native screen recording is not available.');
  }

  @override
  Future<void> resumeRecording() async {
    throw StateError('Native screen recording is not available.');
  }

  @override
  Future<void> startPreparedRecording() async {
    throw StateError('Native screen recording is not available.');
  }

  @override
  Future<XFile> stopRecording() async {
    throw StateError('Native screen recording is not available.');
  }
}

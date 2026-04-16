import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import 'native_display_recorder_contract.dart';

const MethodChannel _nativeDisplayRecorderChannel = MethodChannel(
  'bloop/native_display_recorder',
);

NativeDisplayRecorder createNativeDisplayRecorder() {
  return const MethodChannelNativeDisplayRecorder();
}

class MethodChannelNativeDisplayRecorder implements NativeDisplayRecorder {
  const MethodChannelNativeDisplayRecorder();

  @override
  bool get isSupported => Platform.isAndroid;

  @override
  Future<void> prepareRecording() async {
    _ensureSupported();

    try {
      await _nativeDisplayRecorderChannel.invokeMethod<void>(
        'prepareDisplayCapture',
      );
    } on PlatformException catch (error) {
      throw StateError(
        error.message ?? 'Screen recording permission was not granted.',
      );
    }
  }

  @override
  Future<void> startPreparedRecording() async {
    _ensureSupported();

    try {
      await _nativeDisplayRecorderChannel.invokeMethod<void>(
        'startPreparedDisplayCapture',
      );
    } on PlatformException catch (error) {
      throw StateError(
        error.message ?? 'Unable to start screen recording on this device.',
      );
    }
  }

  @override
  Future<void> cancelPreparedRecording() async {
    if (!isSupported) {
      return;
    }

    try {
      await _nativeDisplayRecorderChannel.invokeMethod<void>(
        'cancelPreparedDisplayCapture',
      );
    } on PlatformException catch (_) {
      // Cancellation is best-effort.
    }
  }

  @override
  Future<void> pauseRecording() async {
    _ensureSupported();

    try {
      await _nativeDisplayRecorderChannel.invokeMethod<void>(
        'pauseDisplayCapture',
      );
    } on PlatformException catch (error) {
      throw StateError(
        error.message ?? 'Unable to pause screen recording right now.',
      );
    }
  }

  @override
  Future<void> resumeRecording() async {
    _ensureSupported();

    try {
      await _nativeDisplayRecorderChannel.invokeMethod<void>(
        'resumeDisplayCapture',
      );
    } on PlatformException catch (error) {
      throw StateError(
        error.message ?? 'Unable to resume screen recording right now.',
      );
    }
  }

  @override
  Future<XFile> stopRecording() async {
    _ensureSupported();

    try {
      final String? recordingPath = await _nativeDisplayRecorderChannel
          .invokeMethod<String>('stopDisplayCapture');
      final String safePath = recordingPath?.trim() ?? '';
      if (safePath.isEmpty) {
        throw StateError('The device did not return a recorded screen file.');
      }

      return XFile(
        safePath,
        mimeType: 'video/mp4',
        name: path.basename(safePath),
      );
    } on PlatformException catch (error) {
      throw StateError(
        error.message ?? 'Unable to finish screen recording on this device.',
      );
    }
  }

  void _ensureSupported() {
    if (Platform.isAndroid) {
      return;
    }

    if (Platform.isIOS) {
      throw StateError(
        'Native screen recording is not implemented on iOS yet.',
      );
    }

    throw StateError(
      'Native screen recording is not available on this platform.',
    );
  }
}

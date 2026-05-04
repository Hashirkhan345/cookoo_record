import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../enums/video_recording_mode.dart';
import '../enums/video_recording_option_kind.dart';
import '../enums/video_shortcut_type.dart';
import '../models/video_recording_flow_model.dart';
import '../models/video_recording_option_model.dart';
import '../models/saved_video_recording_model.dart';
import '../models/video_shortcut_model.dart';
import 'native_display_recorder_contract.dart';
import 'video_browser_recorder.dart';
import 'video_file_disposer.dart';
import 'native_display_recorder_stub.dart'
    if (dart.library.io) 'native_display_recorder_io.dart';
import 'video_recording_storage.dart';
import 'video_recording_storage_contract.dart';

abstract class VideoRepository {
  Future<VideoRecordingFlowModel> loadVideoRecordingFlow();

  void setExternalStopListener(void Function()? listener);

  Future<String> getSavedRecordingsStorageLocationLabel();

  Future<List<SavedVideoRecordingModel>> loadSavedRecordings();

  Future<int> loadLifetimeRecordingCount();

  Future<List<CameraDescription>> getAvailableCameras();

  Future<CameraController> createCameraController(
    CameraDescription camera, {
    required bool enableAudio,
  });

  Future<void> initializeCameraController(CameraController controller);

  Future<void> prepareDisplayCapture({
    required VideoRecordingMode mode,
    bool isMicrophoneEnabled = true,
  });

  Future<void> startPreparedDisplayCapture();

  Future<void> cancelPreparedDisplayCapture();

  Future<void> startRecording(
    CameraController? controller, {
    required VideoRecordingMode mode,
    bool isMicrophoneEnabled = true,
  });

  Future<void> pauseRecording(CameraController? controller);

  Future<void> resumeRecording(CameraController? controller);

  Future<XFile> stopRecording(CameraController? controller);

  Future<SavedVideoRecordingModel> saveRecording(
    XFile recordedFile, {
    required Duration duration,
  });

  Future<void> deleteRecording(XFile recordedFile);

  Future<void> deleteSavedRecording(SavedVideoRecordingModel recording);

  Future<void> clearSavedRecordings();

  bool supportsPauseResume();
}

class LocalVideoRepository implements VideoRepository {
  LocalVideoRepository({VideoRecordingStorage? recordingStorage})
    : _recordingStorage = recordingStorage ?? createVideoRecordingStorage(),
      _browserRecorder = createBrowserVideoRecorder(),
      _nativeDisplayRecorder = createNativeDisplayRecorder();

  final VideoRecordingStorage _recordingStorage;
  final BrowserVideoRecorder _browserRecorder;
  final NativeDisplayRecorder _nativeDisplayRecorder;
  bool _isBrowserRecordingActive = false;
  bool _isNativeDisplayRecordingActive = false;

  @override
  Future<VideoRecordingFlowModel> loadVideoRecordingFlow() async {
    return loadVideoRecordingFlowSync();
  }

  VideoRecordingFlowModel loadVideoRecordingFlowSync() {
    final bool isMobileNative =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final bool supportsNativeDisplayRecording =
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        _nativeDisplayRecorder.isSupported;

    return VideoRecordingFlowModel(
      brandLabel: 'Aks',
      heroTitle: 'Your recording workspace',
      heroDescription: supportsNativeDisplayRecording
          ? 'Capture your screen or camera from mobile, keep your presenter visible, and save polished updates without extra setup.'
          : isMobileNative
          ? 'Capture polished camera videos directly from your phone and keep the presenter visible throughout the session.'
          : 'Start a polished screen or camera recording from one workspace, then review, save, and export it from your library.',
      heroActionLabel: 'Start recording',
      helperMessage: supportsNativeDisplayRecording
          ? 'Camera, microphone, and screen recording are available on this device.'
          : isMobileNative
          ? 'Camera and microphone recording are available on this device.'
          : 'For the best recording experience, use a larger screen and confirm browser permissions before you start.',
      previewTitle: 'Use Aks for walkthroughs, lessons, and updates',
      startRecordingLabel: 'Start recording',
      recordingLimitLabel: '20 recordings lifetime · 5 min each',
      tutorialLabel: 'Open recording guide',
      successMessage: 'Recording workspace opened successfully.',
      panelOptions: supportsNativeDisplayRecording
          ? const <VideoRecordingOptionModel>[
              VideoRecordingOptionModel(
                kind: VideoRecordingOptionKind.display,
                label: 'Screen Recording',
              ),
              VideoRecordingOptionModel(
                kind: VideoRecordingOptionKind.camera,
                label: 'Front Camera',
                status: 'On',
              ),
              VideoRecordingOptionModel(
                kind: VideoRecordingOptionKind.microphone,
                label: 'Device Microphone',
                status: 'On',
                highlighted: true,
              ),
            ]
          : isMobileNative
          ? const <VideoRecordingOptionModel>[
              VideoRecordingOptionModel(
                kind: VideoRecordingOptionKind.camera,
                label: 'Front Camera',
                status: 'On',
              ),
              VideoRecordingOptionModel(
                kind: VideoRecordingOptionKind.microphone,
                label: 'Device Microphone',
                status: 'On',
                highlighted: true,
              ),
            ]
          : const <VideoRecordingOptionModel>[
              VideoRecordingOptionModel(
                kind: VideoRecordingOptionKind.display,
                label: 'Full Screen',
              ),
              VideoRecordingOptionModel(
                kind: VideoRecordingOptionKind.camera,
                label: 'FaceTime HD Camera',
                status: 'On',
              ),
              VideoRecordingOptionModel(
                kind: VideoRecordingOptionKind.microphone,
                label: 'Default - MacBook Microphone',
                status: 'On',
                highlighted: true,
              ),
            ],
      shortcuts: <VideoShortcutModel>[
        VideoShortcutModel(
          type: VideoShortcutType.brainstorm,
          label: 'Brainstorm',
        ),
        VideoShortcutModel(type: VideoShortcutType.build, label: 'Build'),
        VideoShortcutModel(type: VideoShortcutType.narrate, label: 'Narrate'),
      ],
    );
  }

  @override
  void setExternalStopListener(void Function()? listener) {
    _browserRecorder.setExternalStopListener(listener);
  }

  @override
  Future<String> getSavedRecordingsStorageLocationLabel() {
    return _recordingStorage.getStorageLocationLabel();
  }

  @override
  Future<List<SavedVideoRecordingModel>> loadSavedRecordings() {
    return _recordingStorage.loadSavedRecordings();
  }

  @override
  Future<int> loadLifetimeRecordingCount() {
    return _recordingStorage.loadLifetimeRecordingCount();
  }

  @override
  Future<List<CameraDescription>> getAvailableCameras() {
    return availableCameras();
  }

  @override
  Future<CameraController> createCameraController(
    CameraDescription camera, {
    required bool enableAudio,
  }) async {
    return CameraController(
      camera,
      ResolutionPreset.veryHigh,
      enableAudio: enableAudio,
    );
  }

  @override
  Future<void> initializeCameraController(CameraController controller) async {
    await controller.initialize();
    await controller.prepareForVideoRecording();
  }

  @override
  Future<void> startRecording(
    CameraController? controller, {
    required VideoRecordingMode mode,
    bool isMicrophoneEnabled = true,
  }) async {
    if (kIsWeb && mode.capturesDisplay) {
      await prepareDisplayCapture(
        mode: mode,
        isMicrophoneEnabled: isMicrophoneEnabled,
      );
      await startPreparedDisplayCapture();
      return;
    }

    if (!kIsWeb && mode.capturesDisplay) {
      await _nativeDisplayRecorder.prepareRecording();
      await _nativeDisplayRecorder.startPreparedRecording();
      _isNativeDisplayRecordingActive = true;
      return;
    }

    _isBrowserRecordingActive = false;
    _isNativeDisplayRecordingActive = false;
    final CameraController activeController =
        controller ??
        (throw StateError('A camera controller is required for this mode.'));
    await activeController.startVideoRecording();
  }

  @override
  Future<void> prepareDisplayCapture({
    required VideoRecordingMode mode,
    bool isMicrophoneEnabled = true,
  }) async {
    if (!mode.capturesDisplay) {
      throw StateError('Camera-only mode does not prepare display capture.');
    }
    if (!kIsWeb) {
      await _nativeDisplayRecorder.prepareRecording();
      return;
    }

    _isBrowserRecordingActive = true;
    try {
      await _browserRecorder.prepareRecording(
        mode: mode,
        includeMicrophone: isMicrophoneEnabled,
      );
    } catch (_) {
      _isBrowserRecordingActive = false;
      rethrow;
    }
  }

  @override
  Future<void> startPreparedDisplayCapture() async {
    if (!kIsWeb) {
      await _nativeDisplayRecorder.startPreparedRecording();
      _isNativeDisplayRecordingActive = true;
      return;
    }
    if (!_isBrowserRecordingActive) {
      throw StateError('No prepared display capture is available to start.');
    }

    try {
      await _browserRecorder.startPreparedRecording();
    } catch (_) {
      _isBrowserRecordingActive = false;
      rethrow;
    }
  }

  @override
  Future<void> cancelPreparedDisplayCapture() async {
    if (!kIsWeb) {
      _isNativeDisplayRecordingActive = false;
      await _nativeDisplayRecorder.cancelPreparedRecording();
      return;
    }

    if (!_isBrowserRecordingActive) {
      return;
    }

    await _browserRecorder.cancelPreparedRecording();
    _isBrowserRecordingActive = false;
  }

  @override
  Future<void> pauseRecording(CameraController? controller) {
    if (_isNativeDisplayRecordingActive) {
      return _nativeDisplayRecorder.pauseRecording();
    }

    if (kIsWeb && _isBrowserRecordingActive) {
      return _browserRecorder.pauseRecording();
    }

    final CameraController activeController =
        controller ??
        (throw StateError('No active recording is available to pause.'));
    return activeController.pauseVideoRecording();
  }

  @override
  Future<void> resumeRecording(CameraController? controller) {
    if (_isNativeDisplayRecordingActive) {
      return _nativeDisplayRecorder.resumeRecording();
    }

    if (kIsWeb && _isBrowserRecordingActive) {
      return _browserRecorder.resumeRecording();
    }

    final CameraController activeController =
        controller ??
        (throw StateError('No active recording is available to resume.'));
    return activeController.resumeVideoRecording();
  }

  @override
  Future<XFile> stopRecording(CameraController? controller) {
    if (_isNativeDisplayRecordingActive) {
      _isNativeDisplayRecordingActive = false;
      return _nativeDisplayRecorder.stopRecording();
    }

    if (kIsWeb && _isBrowserRecordingActive) {
      _isBrowserRecordingActive = false;
      return _browserRecorder.stopRecording();
    }

    final CameraController activeController =
        controller ??
        (throw StateError('No active recording is available to stop.'));
    return activeController.stopVideoRecording();
  }

  @override
  Future<SavedVideoRecordingModel> saveRecording(
    XFile recordedFile, {
    required Duration duration,
  }) {
    return _recordingStorage.saveRecording(recordedFile, duration: duration);
  }

  @override
  Future<void> deleteRecording(XFile recordedFile) {
    return deleteRecordedFile(recordedFile.path);
  }

  @override
  Future<void> deleteSavedRecording(SavedVideoRecordingModel recording) {
    return _recordingStorage.deleteSavedRecording(recording);
  }

  @override
  Future<void> clearSavedRecordings() {
    return _recordingStorage.clearSavedRecordings();
  }

  @override
  bool supportsPauseResume() {
    if (kIsWeb) {
      return true;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return false;
    }
  }
}

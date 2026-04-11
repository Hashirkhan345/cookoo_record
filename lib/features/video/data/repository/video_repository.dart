import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../enums/video_recording_mode.dart';
import '../enums/video_recording_option_kind.dart';
import '../enums/video_shortcut_type.dart';
import '../models/video_recording_flow_model.dart';
import '../models/video_recording_option_model.dart';
import '../models/saved_video_recording_model.dart';
import '../models/video_shortcut_model.dart';
import 'video_browser_recorder.dart';
import 'video_file_disposer.dart';
import 'video_recording_storage.dart';
import 'video_recording_storage_contract.dart';

abstract class VideoRepository {
  Future<VideoRecordingFlowModel> loadVideoRecordingFlow();

  void setExternalStopListener(void Function()? listener);

  Future<String> getSavedRecordingsStorageLocationLabel();

  Future<List<SavedVideoRecordingModel>> loadSavedRecordings();

  Future<List<CameraDescription>> getAvailableCameras();

  Future<CameraController> createCameraController(CameraDescription camera);

  Future<void> initializeCameraController(CameraController controller);

  Future<void> prepareDisplayCapture({required VideoRecordingMode mode});

  Future<void> startPreparedDisplayCapture();

  Future<void> cancelPreparedDisplayCapture();

  Future<void> startRecording(
    CameraController? controller, {
    required VideoRecordingMode mode,
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
      _browserRecorder = createBrowserVideoRecorder();

  final VideoRecordingStorage _recordingStorage;
  final BrowserVideoRecorder _browserRecorder;
  bool _isBrowserRecordingActive = false;

  @override
  Future<VideoRecordingFlowModel> loadVideoRecordingFlow() async {
    return loadVideoRecordingFlowSync();
  }

  VideoRecordingFlowModel loadVideoRecordingFlowSync() {
    final bool isMobileNative =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    return VideoRecordingFlowModel(
      brandLabel: 'bloop',
      heroTitle: 'Record your video',
      heroDescription: isMobileNative
          ? 'Record polished camera videos directly from your phone and keep your presenter visible throughout the session.'
          : 'Launch a polished recording flow directly from the home screen and keep the presenter visible in the lower section.',
      heroActionLabel: 'Record a Video',
      helperMessage: isMobileNative
          ? 'Camera and microphone recording are available on this device.'
          : 'For the best recording experience, open this flow on a larger screen.',
      previewTitle: 'Ways to use bloop for education',
      startRecordingLabel: 'Start recording',
      recordingLimitLabel: '5 min limit',
      tutorialLabel: '1 minute tutorial',
      successMessage: 'Recording setup opened successfully.',
      panelOptions: isMobileNative
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
  Future<List<CameraDescription>> getAvailableCameras() {
    return availableCameras();
  }

  @override
  Future<CameraController> createCameraController(
    CameraDescription camera,
  ) async {
    return CameraController(camera, ResolutionPreset.high, enableAudio: true);
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
  }) async {
    if (kIsWeb && mode.capturesDisplay) {
      await prepareDisplayCapture(mode: mode);
      await startPreparedDisplayCapture();
      return;
    }

    _isBrowserRecordingActive = false;
    final CameraController activeController =
        controller ??
        (throw StateError('A camera controller is required for this mode.'));
    await activeController.startVideoRecording();
  }

  @override
  Future<void> prepareDisplayCapture({required VideoRecordingMode mode}) async {
    if (!mode.capturesDisplay) {
      throw StateError('Camera-only mode does not prepare display capture.');
    }
    if (!kIsWeb) {
      throw StateError('Display capture preparation is only available on web.');
    }

    _isBrowserRecordingActive = true;
    try {
      await _browserRecorder.prepareRecording(mode: mode);
    } catch (_) {
      _isBrowserRecordingActive = false;
      rethrow;
    }
  }

  @override
  Future<void> startPreparedDisplayCapture() async {
    if (!kIsWeb) {
      throw StateError('Prepared display capture is only available on web.');
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
    if (!kIsWeb || !_isBrowserRecordingActive) {
      return;
    }

    await _browserRecorder.cancelPreparedRecording();
    _isBrowserRecordingActive = false;
  }

  @override
  Future<void> pauseRecording(CameraController? controller) {
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

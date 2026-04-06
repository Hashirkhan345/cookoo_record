import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/enums/video_recording_mode.dart';
import '../data/enums/video_recording_status.dart';
import '../data/models/saved_video_recording_model.dart';
import '../data/repository/video_repository.dart';
import 'video_state.dart';
import 'video_saved_recordings_merge.dart';

final videoRepositoryProvider = Provider<VideoRepository>(
  (ref) => LocalVideoRepository(),
);

final videoControllerProvider =
    StateNotifierProvider<VideoController, VideoState>(
      (ref) => VideoController(ref.read(videoRepositoryProvider))..load(),
    );

class VideoController extends StateNotifier<VideoState> {
  VideoController(this._repository) : super(const VideoState()) {
    _repository.setExternalStopListener(_handleExternalRecordingStop);
  }

  final VideoRepository _repository;
  Timer? _recordingTimer;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFeedbackMessage: true);

    try {
      final flow = await _repository.loadVideoRecordingFlow();
      List<SavedVideoRecordingModel> savedRecordings =
          const <SavedVideoRecordingModel>[];
      String? storageLocationLabel;
      String? feedbackMessage;

      try {
        savedRecordings = await _repository.loadSavedRecordings();
        storageLocationLabel = await _repository
            .getSavedRecordingsStorageLocationLabel();
      } catch (_) {
        storageLocationLabel = await _safeStorageLocationLabel();
        feedbackMessage =
            'Saved recordings could not be restored. You can keep recording.';
      }

      state = state.copyWith(
        isLoading: false,
        flow: flow,
        savedRecordings: savedRecordings,
        savedRecordingsStorageLocationLabel: storageLocationLabel,
        feedbackMessage: feedbackMessage,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        feedbackMessage: 'Unable to load the video recording flow.',
      );
    }
  }

  void openRecordingFlow() {
    if (state.flow == null) {
      return;
    }

    state = state.copyWith(
      isRecordingFlowVisible: true,
      clearFeedbackMessage: true,
      recordingStatus: VideoRecordingStatus.idle,
      recordingDuration: Duration.zero,
      clearRecordedVideo: true,
      selectedRecordingMode: VideoRecordingMode.fullScreen,
    );
  }

  void dismissRecordingFlow() {
    state = state.copyWith(isRecordingFlowVisible: false);
  }

  void selectRecordingMode(VideoRecordingMode mode) {
    if (state.hasActiveRecording) {
      return;
    }

    state = state.copyWith(
      selectedRecordingMode: mode,
      clearFeedbackMessage: true,
    );
  }

  Future<void> startRecordingSession() async {
    if (state.isPreparingRecording || state.isRecording || state.isPaused) {
      return;
    }

    final VideoRecordingMode selectedMode = state.selectedRecordingMode;

    state = state.copyWith(
      recordingStatus: VideoRecordingStatus.preparing,
      recordingDuration: Duration.zero,
      clearFeedbackMessage: true,
      clearRecordedVideo: true,
    );

    try {
      final CameraController? controller =
          selectedMode == VideoRecordingMode.cameraOnly
          ? await _ensureCameraController()
          : await _ensureOptionalCameraController();
      await _repository.startRecording(controller, mode: selectedMode);
      _startTimer();
      state = state.copyWith(
        recordingStatus: VideoRecordingStatus.recording,
        supportsPauseResume: _repository.supportsPauseResume(),
      );
    } catch (error, stackTrace) {
      debugPrint('[video] startRecordingSession failed: $error');
      debugPrintStack(
        label: '[video] startRecordingSession stack',
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        recordingStatus: VideoRecordingStatus.idle,
        feedbackMessage: _describeRecordingError(error),
      );
    }
  }

  Future<void> togglePauseResumeRecording() async {
    if (state.isPreparingRecording || state.isFinalizing) {
      return;
    }

    if (state.isRecording) {
      try {
        await _repository.pauseRecording(state.cameraController);
        _recordingTimer?.cancel();
        state = state.copyWith(recordingStatus: VideoRecordingStatus.paused);
      } catch (error) {
        state = state.copyWith(feedbackMessage: _describeRecordingError(error));
      }
      return;
    }

    if (state.isPaused) {
      try {
        await _repository.resumeRecording(state.cameraController);
        _startTimer();
        state = state.copyWith(recordingStatus: VideoRecordingStatus.recording);
      } catch (error) {
        state = state.copyWith(feedbackMessage: _describeRecordingError(error));
      }
    }
  }

  Future<void> stopRecordingSession() async {
    if (!state.hasActiveRecording || state.isFinalizing) {
      return;
    }

    state = state.copyWith(recordingStatus: VideoRecordingStatus.finalizing);
    _recordingTimer?.cancel();
    final Duration completedDuration = state.recordingDuration;
    final List<SavedVideoRecordingModel> previousSavedRecordings =
        state.savedRecordings;

    try {
      final XFile recordedVideo = await _repository.stopRecording(
        state.cameraController,
      );
      final SavedVideoRecordingModel savedRecording = await _repository
          .saveRecording(recordedVideo, duration: completedDuration);
      List<SavedVideoRecordingModel> savedRecordings =
          mergeSavedRecordingIntoList(savedRecording, previousSavedRecordings);

      try {
        final List<SavedVideoRecordingModel> reloadedRecordings =
            await _repository.loadSavedRecordings();
        if (reloadedRecordings.any(
          (SavedVideoRecordingModel recording) =>
              recording.id == savedRecording.id,
        )) {
          savedRecordings = reloadedRecordings;
        }
      } catch (_) {
        // Keep the optimistic in-memory list when storage reload lags or fails.
      }

      final String? storageLocationLabel = await _safeStorageLocationLabel();

      await _disposeCameraController();
      state = state.copyWith(
        isRecordingFlowVisible: false,
        recordingStatus: VideoRecordingStatus.idle,
        recordedVideo: XFile(
          savedRecording.playbackPath,
          mimeType: savedRecording.mimeType,
          name: savedRecording.fileName,
        ),
        savedRecordings: savedRecordings,
        savedRecordingsStorageLocationLabel: storageLocationLabel,
        feedbackMessage: 'Recording saved to ${savedRecording.storageSummary}.',
      );
    } catch (error) {
      await _disposeCameraController();
      state = state.copyWith(
        isRecordingFlowVisible: false,
        recordingStatus: VideoRecordingStatus.idle,
        feedbackMessage: _describeRecordingError(error),
      );
    }
  }

  Future<void> deleteRecordingSession() async {
    if (!state.hasActiveRecording || state.isFinalizing) {
      return;
    }

    state = state.copyWith(recordingStatus: VideoRecordingStatus.finalizing);
    _recordingTimer?.cancel();

    try {
      final XFile recordedVideo = await _repository.stopRecording(
        state.cameraController,
      );
      await _repository.deleteRecording(recordedVideo);
      await _disposeCameraController();
      state = state.copyWith(
        isRecordingFlowVisible: false,
        recordingStatus: VideoRecordingStatus.idle,
        clearRecordedVideo: true,
        feedbackMessage: 'Recording deleted.',
      );
    } catch (error) {
      await _disposeCameraController();
      state = state.copyWith(
        isRecordingFlowVisible: false,
        recordingStatus: VideoRecordingStatus.idle,
        feedbackMessage: _describeRecordingError(error),
      );
    }
  }

  Future<void> closeRecordingFlow() async {
    _recordingTimer?.cancel();
    await _disposeCameraController();
    state = state.copyWith(
      isRecordingFlowVisible: false,
      recordingStatus: VideoRecordingStatus.idle,
      recordingDuration: Duration.zero,
    );
  }

  void clearFeedbackMessage() {
    state = state.copyWith(clearFeedbackMessage: true);
  }

  Future<void> deleteSavedRecording(SavedVideoRecordingModel recording) async {
    try {
      await _repository.deleteSavedRecording(recording);
      final List<SavedVideoRecordingModel> savedRecordings = await _repository
          .loadSavedRecordings();
      state = state.copyWith(
        savedRecordings: savedRecordings,
        feedbackMessage: '${recording.fileName} deleted.',
      );
    } catch (error) {
      state = state.copyWith(feedbackMessage: error.toString());
    }
  }

  Future<String?> _safeStorageLocationLabel() async {
    try {
      return await _repository.getSavedRecordingsStorageLocationLabel();
    } catch (_) {
      return null;
    }
  }

  Future<CameraController> _ensureCameraController() async {
    final CameraController? existingController = state.cameraController;
    if (existingController != null && existingController.value.isInitialized) {
      return existingController;
    }

    final List<CameraDescription> cameras = state.availableCameras.isNotEmpty
        ? state.availableCameras
        : await _repository.getAvailableCameras();

    if (cameras.isEmpty) {
      throw StateError('No available camera was found on this device.');
    }

    final CameraDescription activeCamera = cameras.firstWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final CameraController controller = await _repository
        .createCameraController(activeCamera);
    await _repository.initializeCameraController(controller);

    state = state.copyWith(
      cameraController: controller,
      activeCamera: activeCamera,
      availableCameras: cameras,
      supportsPauseResume: _repository.supportsPauseResume(),
    );

    return controller;
  }

  Future<CameraController?> _ensureOptionalCameraController() async {
    try {
      return await _ensureCameraController();
    } catch (_) {
      return null;
    }
  }

  void _startTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        recordingDuration: state.recordingDuration + const Duration(seconds: 1),
      );
    });
  }

  Future<void> _disposeCameraController() async {
    final CameraController? controller = state.cameraController;
    if (controller != null) {
      await controller.dispose();
    }

    state = state.copyWith(
      clearCameraController: true,
      clearActiveCamera: true,
      recordingDuration: Duration.zero,
    );
  }

  String _describeRecordingError(Object error) {
    if (error is CameraException) {
      switch (error.code) {
        case 'CameraAccessDenied':
          return 'Camera permission was denied.';
        case 'CameraAccessDeniedWithoutPrompt':
          return 'Camera access was previously denied. Enable it in settings.';
        case 'CameraAccessRestricted':
          return 'Camera access is restricted on this device.';
        case 'AudioAccessDenied':
          return 'Microphone permission was denied.';
        case 'AudioAccessDeniedWithoutPrompt':
          return 'Microphone access was previously denied. Enable it in settings.';
        case 'AudioAccessRestricted':
          return 'Microphone access is restricted on this device.';
        default:
          return error.description ?? error.code;
      }
    }

    if (error is StateError) {
      final String message = error.message.toString();
      if (message.isNotEmpty) {
        return message;
      }
    }

    final String rawMessage = error.toString();
    if (rawMessage.contains('NotAllowedError')) {
      return 'Screen sharing was cancelled or denied.';
    }
    if (rawMessage.contains('NotFoundError')) {
      return 'No screen, tab, or window is available to share.';
    }
    if (rawMessage.contains('NotReadableError')) {
      return 'The selected screen source could not be captured.';
    }
    if (rawMessage.contains('Please choose a browser tab')) {
      return 'Choose a browser tab in Chrome to use Current Tab recording.';
    }
    if (rawMessage.contains('Bad state: ')) {
      return rawMessage.replaceFirst('Bad state: ', '');
    }

    return rawMessage;
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _repository.setExternalStopListener(null);
    final CameraController? controller = state.cameraController;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  void _handleExternalRecordingStop() {
    if (!mounted || !state.hasActiveRecording || state.isFinalizing) {
      return;
    }
    unawaited(stopRecordingSession());
  }
}

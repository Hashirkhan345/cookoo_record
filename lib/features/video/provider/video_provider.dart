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

  static const List<String> _recordingCountdownLabels = <String>[
    '3',
    '2',
    '1',
    'Go',
  ];
  static const Duration _countdownTick = Duration(seconds: 1);
  static const Duration _countdownGoTick = Duration(milliseconds: 650);

  final VideoRepository _repository;
  Timer? _recordingTimer;
  Future<CameraController>? _cameraControllerInitialization;
  int _countdownRunId = 0;

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
        selectedRecordingMode: defaultRecordingModeForCurrentPlatform(),
        feedbackMessage: feedbackMessage,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        feedbackMessage: 'Unable to load the video recording flow.',
      );
    }
  }

  Future<void> openRecordingFlow() async {
    if (state.flow == null ||
        state.isRecordingFlowVisible ||
        state.isPreparingCameraPreview) {
      return;
    }

    _cancelCountdown();
    state = state.copyWith(
      isRecordingFlowVisible: false,
      clearFeedbackMessage: true,
      recordingStatus: VideoRecordingStatus.idle,
      clearCountdownLabel: true,
      isPreparingCameraPreview: true,
      recordingDuration: Duration.zero,
      clearRecordedVideo: true,
      selectedRecordingMode: defaultRecordingModeForCurrentPlatform(),
    );

    String? feedbackMessage;
    try {
      await _ensureCameraController();
    } on _CancelledCameraPreviewPreparation {
      return;
    } catch (error, stackTrace) {
      debugPrint('[video] openRecordingFlow preview setup failed: $error');
      debugPrintStack(
        label: '[video] openRecordingFlow preview setup stack',
        stackTrace: stackTrace,
      );
      feedbackMessage = _describeRecordingError(error);
    }

    if (!mounted) {
      return;
    }

    state = state.copyWith(
      isRecordingFlowVisible: true,
      isPreparingCameraPreview: false,
      feedbackMessage: feedbackMessage,
    );
  }

  void dismissRecordingFlow() {
    _cancelCountdown();
    state = state.copyWith(
      isRecordingFlowVisible: false,
      clearCountdownLabel: true,
    );
  }

  void selectRecordingMode(VideoRecordingMode mode) {
    if (state.hasActiveRecording ||
        !supportedRecordingModesForCurrentPlatform().contains(mode)) {
      return;
    }

    state = state.copyWith(
      selectedRecordingMode: mode,
      clearFeedbackMessage: true,
    );
  }

  Future<void> startRecordingSession() async {
    if (state.isPreparingRecording ||
        state.isRecording ||
        state.isPaused ||
        state.isCountingDown) {
      return;
    }

    final VideoRecordingMode selectedMode = state.selectedRecordingMode;
    if (_usesWebDisplayCaptureHandshake(selectedMode)) {
      await _startWebDisplayRecordingSession(selectedMode);
      return;
    }

    final bool didCompleteCountdown = await _runRecordingCountdown();
    if (!didCompleteCountdown || !mounted) {
      return;
    }

    await _startRecordingSessionNow(selectedMode: selectedMode);
  }

  Future<void> _startRecordingSessionNow({
    required VideoRecordingMode selectedMode,
  }) async {
    state = state.copyWith(
      recordingStatus: VideoRecordingStatus.preparing,
      recordingDuration: Duration.zero,
      clearFeedbackMessage: true,
      clearRecordedVideo: true,
      clearCountdownLabel: true,
    );

    try {
      final CameraController? controller =
          selectedMode == VideoRecordingMode.cameraOnly
          ? await _ensureCameraController()
          : await _ensureOptionalCameraController();
      await _repository.startRecording(controller, mode: selectedMode);
      if (kIsWeb && selectedMode.capturesDisplay) {
        await _refreshWebCameraPreviewAfterDisplayCapture();
      }
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
        clearCountdownLabel: true,
        feedbackMessage: _describeRecordingError(error),
      );
    }
  }

  Future<void> _startWebDisplayRecordingSession(
    VideoRecordingMode selectedMode,
  ) async {
    state = state.copyWith(
      recordingStatus: VideoRecordingStatus.preparing,
      recordingDuration: Duration.zero,
      clearFeedbackMessage: true,
      clearRecordedVideo: true,
      clearCountdownLabel: true,
    );

    try {
      await _ensureOptionalCameraController();
      await _repository.prepareDisplayCapture(mode: selectedMode);
      if (!mounted) {
        await _repository.cancelPreparedDisplayCapture();
        return;
      }

      await _refreshWebCameraPreviewAfterDisplayCapture();

      final bool didCompleteCountdown = await _runRecordingCountdown();
      if (!didCompleteCountdown || !mounted) {
        await _repository.cancelPreparedDisplayCapture();
        if (mounted) {
          state = state.copyWith(
            recordingStatus: VideoRecordingStatus.idle,
            clearCountdownLabel: true,
          );
        }
        return;
      }

      await _repository.startPreparedDisplayCapture();
      await _refreshWebCameraPreviewAfterDisplayCapture();
      unawaited(_refreshWebCameraPreviewAfterRecordingStart());
      _startTimer();
      state = state.copyWith(
        recordingStatus: VideoRecordingStatus.recording,
        supportsPauseResume: _repository.supportsPauseResume(),
        clearCountdownLabel: true,
      );
    } catch (error, stackTrace) {
      await _repository.cancelPreparedDisplayCapture();
      debugPrint('[video] startRecordingSession failed: $error');
      debugPrintStack(
        label: '[video] startRecordingSession stack',
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        recordingStatus: VideoRecordingStatus.idle,
        clearCountdownLabel: true,
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

    _cancelCountdown();
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

    _cancelCountdown();
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
        clearFeedbackMessage: true,
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

  Future<void> restartRecordingSession() async {
    if (!state.hasActiveRecording || state.isFinalizing) {
      return;
    }

    _cancelCountdown();
    state = state.copyWith(
      recordingStatus: VideoRecordingStatus.finalizing,
      clearFeedbackMessage: true,
    );
    _recordingTimer?.cancel();

    try {
      final XFile recordedVideo = await _repository.stopRecording(
        state.cameraController,
      );
      await _repository.deleteRecording(recordedVideo);
      state = state.copyWith(
        recordingStatus: VideoRecordingStatus.idle,
        recordingDuration: Duration.zero,
        clearRecordedVideo: true,
        clearFeedbackMessage: true,
      );
      await startRecordingSession();
    } catch (error) {
      state = state.copyWith(
        recordingStatus: VideoRecordingStatus.idle,
        recordingDuration: Duration.zero,
        clearRecordedVideo: true,
        feedbackMessage: _describeRecordingError(error),
      );
    }
  }

  Future<void> closeRecordingFlow() async {
    _cancelCountdown();
    _recordingTimer?.cancel();
    await _repository.cancelPreparedDisplayCapture();
    await _disposeCameraController();
    state = state.copyWith(
      isRecordingFlowVisible: false,
      recordingStatus: VideoRecordingStatus.idle,
      recordingDuration: Duration.zero,
      clearCountdownLabel: true,
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

  Future<void> clearSavedRecordings({String? feedbackMessage}) async {
    try {
      await _repository.clearSavedRecordings();
      final String? storageLocationLabel = await _safeStorageLocationLabel();
      state = state.copyWith(
        savedRecordings: const <SavedVideoRecordingModel>[],
        savedRecordingsStorageLocationLabel: storageLocationLabel,
        clearRecordedVideo: true,
        feedbackMessage: feedbackMessage,
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

    final Future<CameraController>? existingInitialization =
        _cameraControllerInitialization;
    if (existingInitialization != null) {
      return existingInitialization;
    }

    final Future<CameraController> initialization = _createCameraController();
    _cameraControllerInitialization = initialization;

    try {
      return await initialization;
    } finally {
      if (identical(_cameraControllerInitialization, initialization)) {
        _cameraControllerInitialization = null;
      }
    }
  }

  Future<CameraController> _createCameraController() async {
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
    try {
      await _repository.initializeCameraController(controller);
    } catch (_) {
      await controller.dispose();
      rethrow;
    }

    if (!mounted) {
      await controller.dispose();
      throw const _CancelledCameraPreviewPreparation();
    }

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
    } on _CancelledCameraPreviewPreparation {
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _usesWebDisplayCaptureHandshake(VideoRecordingMode mode) {
    return kIsWeb && mode.capturesDisplay;
  }

  Future<bool> _runRecordingCountdown() async {
    final int runId = ++_countdownRunId;

    state = state.copyWith(
      countdownLabel: _recordingCountdownLabels.first,
      recordingDuration: Duration.zero,
      clearFeedbackMessage: true,
      clearRecordedVideo: true,
    );

    for (int index = 0; index < _recordingCountdownLabels.length; index++) {
      if (!_isCountdownRunActive(runId)) {
        return false;
      }

      state = state.copyWith(countdownLabel: _recordingCountdownLabels[index]);
      await Future<void>.delayed(
        index == _recordingCountdownLabels.length - 1
            ? _countdownGoTick
            : _countdownTick,
      );
    }

    return _isCountdownRunActive(runId);
  }

  bool _isCountdownRunActive(int runId) {
    return mounted &&
        runId == _countdownRunId &&
        state.isRecordingFlowVisible &&
        state.isCountingDown;
  }

  void _cancelCountdown() {
    _countdownRunId++;
    if (state.isCountingDown) {
      state = state.copyWith(clearCountdownLabel: true);
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
    _cameraControllerInitialization = null;
    final CameraController? controller = state.cameraController;
    if (controller != null) {
      await controller.dispose();
    }

    state = state.copyWith(
      isPreparingCameraPreview: false,
      clearCameraController: true,
      clearActiveCamera: true,
      recordingDuration: Duration.zero,
    );
  }

  Future<void> _refreshWebCameraPreviewAfterDisplayCapture() async {
    final CameraController? controller = state.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      await controller.pausePreview();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await controller.resumePreview();
      return;
    } catch (error, stackTrace) {
      debugPrint(
        '[video] refreshWebCameraPreviewAfterDisplayCapture '
        'pause/resume failed: $error',
      );
      debugPrintStack(
        label:
            '[video] refreshWebCameraPreviewAfterDisplayCapture '
            'pause/resume stack',
        stackTrace: stackTrace,
      );
    }

    final CameraDescription? activeCamera = state.activeCamera;
    if (activeCamera == null) {
      return;
    }

    try {
      await controller.dispose();
      state = state.copyWith(clearCameraController: true);

      final CameraController refreshedController = await _repository
          .createCameraController(activeCamera);
      await _repository.initializeCameraController(refreshedController);

      if (!mounted) {
        await refreshedController.dispose();
        return;
      }

      state = state.copyWith(
        cameraController: refreshedController,
        activeCamera: activeCamera,
        supportsPauseResume: _repository.supportsPauseResume(),
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[video] refreshWebCameraPreviewAfterDisplayCapture '
        'reinitialize failed: $error',
      );
      debugPrintStack(
        label:
            '[video] refreshWebCameraPreviewAfterDisplayCapture '
            'reinitialize stack',
        stackTrace: stackTrace,
      );
      if (mounted) {
        state = state.copyWith(feedbackMessage: _describeRecordingError(error));
      }
    }
  }

  Future<void> _refreshWebCameraPreviewAfterRecordingStart() async {
    if (!mounted || !kIsWeb) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted || !state.isRecordingFlowVisible) {
      return;
    }

    await _refreshWebCameraPreviewAfterDisplayCapture();
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
    _cancelCountdown();
    unawaited(_repository.cancelPreparedDisplayCapture());
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

final class _CancelledCameraPreviewPreparation implements Exception {
  const _CancelledCameraPreviewPreparation();
}

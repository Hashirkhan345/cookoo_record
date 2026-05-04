import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_provider.dart';
import '../data/enums/video_recording_storage_kind.dart';
import '../data/enums/video_recording_mode.dart';
import '../data/enums/video_recording_status.dart';
import '../data/models/saved_video_recording_model.dart';
import '../data/repository/user_video_upload_repository.dart';
import '../data/repository/video_repository.dart';
import '../data/repository/video_recording_storage_support.dart';
import 'video_state.dart';
import 'video_saved_recordings_merge.dart';

final videoRepositoryProvider = Provider<VideoRepository>(
  (ref) => LocalVideoRepository(),
);

final userVideoUploadRepositoryProvider = Provider<UserVideoUploadRepository>(
  (ref) => UserVideoUploadRepository(),
);

final videoControllerProvider =
    StateNotifierProvider<VideoController, VideoState>((ref) {
      final VideoController controller = VideoController(
        ref.read(videoRepositoryProvider),
        userVideoUploadRepositoryFactory: () =>
            ref.read(userVideoUploadRepositoryProvider),
        currentUserUid: () => ref.read(authControllerProvider).user?.uid,
      )..load();

      ref.listen(authControllerProvider, (previous, next) {
        final String? previousUid = previous?.user?.uid;
        final String? nextUid = next.user?.uid;
        if (previousUid != nextUid) {
          unawaited(controller.load());
        }
      });

      return controller;
    });

class VideoController extends StateNotifier<VideoState> {
  VideoController(
    this._repository, {
    UserVideoUploadRepository Function()? userVideoUploadRepositoryFactory,
    String? Function()? currentUserUid,
    Future<UserVideoUploadResult> Function(
      String userUid,
      SavedVideoRecordingModel recording,
    )?
    uploadRecordingForUser,
    Future<List<SavedVideoRecordingModel>> Function(String userUid)?
    loadCloudRecordingsForUser,
    Future<void> Function(String userUid, String recordingId, String title)?
    renameCloudRecordingForUser,
    Stream<List<SavedVideoRecordingModel>> Function(String userUid)?
    watchCloudRecordingsForUser,
    Future<void> Function(String userUid, SavedVideoRecordingModel recording)?
    deleteCloudRecordingForUser,
  }) : _userVideoUploadRepositoryFactory = userVideoUploadRepositoryFactory,
       _currentUserUid = currentUserUid ?? (() => null),
       _uploadRecordingForUser = uploadRecordingForUser,
       _loadCloudRecordingsForUser = loadCloudRecordingsForUser,
       _renameCloudRecordingForUser = renameCloudRecordingForUser,
       _watchCloudRecordingsForUser = watchCloudRecordingsForUser,
       _deleteCloudRecordingForUser = deleteCloudRecordingForUser,
       super(const VideoState()) {
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
  static const Duration _countdownDismissDelay = Duration(milliseconds: 240);
  final VideoRepository _repository;
  final UserVideoUploadRepository Function()? _userVideoUploadRepositoryFactory;
  final String? Function() _currentUserUid;
  final Future<UserVideoUploadResult> Function(
    String userUid,
    SavedVideoRecordingModel recording,
  )?
  _uploadRecordingForUser;
  final Future<List<SavedVideoRecordingModel>> Function(String userUid)?
  _loadCloudRecordingsForUser;
  final Future<void> Function(String userUid, String recordingId, String title)?
  _renameCloudRecordingForUser;
  final Stream<List<SavedVideoRecordingModel>> Function(String userUid)?
  _watchCloudRecordingsForUser;
  final Future<void> Function(
    String userUid,
    SavedVideoRecordingModel recording,
  )?
  _deleteCloudRecordingForUser;
  Timer? _recordingTimer;
  Future<CameraController>? _cameraControllerInitialization;
  StreamSubscription<List<SavedVideoRecordingModel>>?
  _cloudRecordingsSubscription;
  List<SavedVideoRecordingModel> _localSavedRecordings =
      const <SavedVideoRecordingModel>[];
  List<SavedVideoRecordingModel> _cloudSavedRecordings =
      const <SavedVideoRecordingModel>[];
  int _countdownRunId = 0;
  int _loadRunId = 0;

  Future<void> load() async {
    final int loadRunId = ++_loadRunId;
    await _cloudRecordingsSubscription?.cancel();
    _cloudRecordingsSubscription = null;
    _cloudSavedRecordings = const <SavedVideoRecordingModel>[];
    state = state.copyWith(isLoading: true, clearFeedbackMessage: true);

    try {
      final flow = await _repository.loadVideoRecordingFlow();
      List<SavedVideoRecordingModel> localSavedRecordings =
          const <SavedVideoRecordingModel>[];
      int lifetimeRecordedCount = 0;
      String? storageLocationLabel;
      String? feedbackMessage;

      try {
        localSavedRecordings = await _repository.loadSavedRecordings();
        lifetimeRecordedCount = await _repository.loadLifetimeRecordingCount();
        storageLocationLabel = await _repository
            .getSavedRecordingsStorageLocationLabel();
      } catch (_) {
        storageLocationLabel = await _safeStorageLocationLabel();
        feedbackMessage =
            'Saved recordings could not be restored. You can keep recording.';
      }

      _localSavedRecordings = localSavedRecordings;
      _cloudSavedRecordings = const <SavedVideoRecordingModel>[];

      try {
        _cloudSavedRecordings = await _loadCloudRecordingsForCurrentUser();
        if (_cloudSavedRecordings.length > lifetimeRecordedCount) {
          lifetimeRecordedCount = _cloudSavedRecordings.length;
        }
        unawaited(
          _syncStoredUsageCountIfPossible(_cloudSavedRecordings.length),
        );
      } catch (error, stackTrace) {
        debugPrint('[video] cloud recordings load failed: $error');
        debugPrintStack(
          label: '[video] cloud recordings load stack',
          stackTrace: stackTrace,
        );
        feedbackMessage ??=
            'Cloud recordings could not be loaded. Local recordings are still available.';
      }

      if (!mounted || loadRunId != _loadRunId) {
        return;
      }

      await _restartCloudRecordingsSubscription();

      state = state.copyWith(
        isLoading: false,
        flow: flow,
        savedRecordings: _mergedSavedRecordings(),
        lifetimeRecordedCount: lifetimeRecordedCount,
        savedRecordingsStorageLocationLabel: storageLocationLabel,
        selectedRecordingMode: defaultRecordingModeForCurrentPlatform(),
        feedbackMessage: feedbackMessage,
      );
    } catch (_) {
      if (!mounted || loadRunId != _loadRunId) {
        return;
      }

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
      isCameraEnabled: true,
      isMicrophoneEnabled: true,
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

  Future<void> selectRecordingMode(VideoRecordingMode mode) async {
    if (state.hasActiveRecording ||
        !supportedRecordingModesForCurrentPlatform().contains(mode)) {
      return;
    }

    state = state.copyWith(
      selectedRecordingMode: mode,
      clearFeedbackMessage: true,
    );

    final bool isAndroidNativeDisplayMode =
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        mode.capturesDisplay;
    final bool isAndroidCameraMode =
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        mode == VideoRecordingMode.cameraOnly;

    if (isAndroidNativeDisplayMode) {
      await _disposeCameraController();
      return;
    }

    if (!isAndroidCameraMode || state.cameraController != null) {
      return;
    }

    state = state.copyWith(isPreparingCameraPreview: true);
    String? feedbackMessage;
    try {
      await _ensureCameraController();
    } on _CancelledCameraPreviewPreparation {
      return;
    } catch (error, stackTrace) {
      debugPrint('[video] selectRecordingMode preview setup failed: $error');
      debugPrintStack(
        label: '[video] selectRecordingMode preview stack',
        stackTrace: stackTrace,
      );
      feedbackMessage = _describeRecordingError(error);
    }

    if (!mounted) {
      return;
    }

    state = state.copyWith(
      isPreparingCameraPreview: false,
      feedbackMessage: feedbackMessage,
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
    if (selectedMode == VideoRecordingMode.cameraOnly &&
        !state.isCameraEnabled) {
      state = state.copyWith(
        feedbackMessage: 'Turn the camera on to use camera-only recording.',
      );
      return;
    }
    if (_usesDisplayCaptureHandshake(selectedMode)) {
      await _startDisplayRecordingSession(selectedMode);
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
      final CameraController? controller = !state.isCameraEnabled
          ? null
          : selectedMode == VideoRecordingMode.cameraOnly
          ? await _ensureCameraController()
          : await _ensureOptionalCameraController();
      await _repository.startRecording(
        controller,
        mode: selectedMode,
        isMicrophoneEnabled: state.isMicrophoneEnabled,
      );
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

  Future<void> _startDisplayRecordingSession(
    VideoRecordingMode selectedMode,
  ) async {
    final bool usesNativeMobileDisplayCapture =
        !kIsWeb && selectedMode.capturesDisplay;

    state = state.copyWith(
      recordingStatus: VideoRecordingStatus.preparing,
      recordingDuration: Duration.zero,
      clearFeedbackMessage: true,
      clearRecordedVideo: true,
      clearCountdownLabel: true,
    );

    try {
      if (kIsWeb) {
        if (state.isCameraEnabled) {
          await _ensureOptionalCameraController();
        }
      }
      await _repository.prepareDisplayCapture(
        mode: selectedMode,
        isMicrophoneEnabled: state.isMicrophoneEnabled,
      );
      if (!mounted) {
        await _repository.cancelPreparedDisplayCapture();
        return;
      }

      if (usesNativeMobileDisplayCapture) {
        await _repository.startPreparedDisplayCapture();
        _startTimer();
        state = state.copyWith(
          recordingStatus: VideoRecordingStatus.recording,
          supportsPauseResume: _repository.supportsPauseResume(),
          clearCountdownLabel: true,
          feedbackMessage:
              'Screen recording started. You can switch to another app now.',
        );
        return;
      }

      if (kIsWeb) {
        await _refreshWebCameraPreviewAfterDisplayCapture();
      }
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

      state = state.copyWith(clearCountdownLabel: true);
      final bool didDismissOverlay =
          await _waitForCountdownOverlayToDisappear();
      if (!didDismissOverlay) {
        await _repository.cancelPreparedDisplayCapture();
        return;
      }

      await _repository.startPreparedDisplayCapture();
      if (kIsWeb) {
        await _refreshWebCameraPreviewAfterDisplayCapture();
        unawaited(_refreshWebCameraPreviewAfterRecordingStart());
      }
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

    try {
      final XFile recordedVideo = await _repository.stopRecording(
        state.cameraController,
      );
      SavedVideoRecordingModel savedRecording = await _repository.saveRecording(
        recordedVideo,
        duration: completedDuration,
      );
      String feedbackMessage =
          'Recording saved to ${savedRecording.storageSummary}.';
      try {
        final SavedVideoRecordingModel? uploadedRecording =
            await _uploadSavedRecordingForCurrentUser(savedRecording);
        if (uploadedRecording != null) {
          savedRecording = uploadedRecording;
          feedbackMessage = 'Recording saved and uploaded to your workspace.';
        }
      } catch (error, stackTrace) {
        debugPrint('[video] cloud upload failed: $error');
        debugPrintStack(
          label: '[video] cloud upload stack',
          stackTrace: stackTrace,
        );
        feedbackMessage =
            'Recording saved locally, but cloud upload failed. Please try again later.';
      }
      final int lifetimeRecordedCount = state.lifetimeRecordedCount + 1;
      _localSavedRecordings = await _refreshLocalRecordingsAfterMutation(
        baseRecordings: mergeSavedRecordingIntoList(
          savedRecording,
          _localSavedRecordings,
        ),
      );

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
        savedRecordings: _mergedSavedRecordings(),
        lifetimeRecordedCount: lifetimeRecordedCount,
        savedRecordingsStorageLocationLabel: storageLocationLabel,
        feedbackMessage: feedbackMessage,
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

  Future<SavedVideoRecordingModel?> _uploadSavedRecordingForCurrentUser(
    SavedVideoRecordingModel savedRecording,
  ) async {
    final String? userUid = _currentUserUid();
    if (userUid == null || userUid.isEmpty) {
      return null;
    }
    final UserVideoUploadRepository Function()? uploadRepositoryFactory =
        _userVideoUploadRepositoryFactory;
    if (uploadRepositoryFactory == null) {
      if (_uploadRecordingForUser == null) {
        return null;
      }
    }

    final UserVideoUploadResult uploadResult = uploadRepositoryFactory != null
        ? await uploadRepositoryFactory().uploadRecordingForUser(
            userUid: userUid,
            recording: savedRecording,
          )
        : await _uploadRecordingForUser!(userUid, savedRecording);
    final SavedVideoRecordingModel uploadedRecording = savedRecording.copyWith(
      publicShareUrl: uploadResult.shareUrl,
      publicShareStoragePath: uploadResult.storagePath,
      sharedAt: uploadResult.uploadedAt,
    );
    await persistSavedRecordingMetadata(uploadedRecording);
    return uploadedRecording;
  }

  Future<List<SavedVideoRecordingModel>>
  _loadCloudRecordingsForCurrentUser() async {
    final String? userUid = _currentUserUid();
    if (userUid == null || userUid.isEmpty) {
      return const <SavedVideoRecordingModel>[];
    }
    final UserVideoUploadRepository Function()? uploadRepositoryFactory =
        _userVideoUploadRepositoryFactory;
    if (uploadRepositoryFactory == null) {
      if (_loadCloudRecordingsForUser == null) {
        return const <SavedVideoRecordingModel>[];
      }
    }

    return uploadRepositoryFactory != null
        ? uploadRepositoryFactory().loadRecordingsForUser(userUid: userUid)
        : _loadCloudRecordingsForUser!(userUid);
  }

  Stream<List<SavedVideoRecordingModel>>? _watchCloudRecordings(
    String userUid,
  ) {
    final UserVideoUploadRepository Function()? uploadRepositoryFactory =
        _userVideoUploadRepositoryFactory;
    if (uploadRepositoryFactory != null) {
      return uploadRepositoryFactory().watchRecordingsForUser(userUid: userUid);
    }
    return _watchCloudRecordingsForUser?.call(userUid);
  }

  Future<void> _deleteCloudRecordingIfNeeded(
    SavedVideoRecordingModel recording,
  ) async {
    if (!_hasCloudBackedRecording(recording)) {
      return;
    }

    final String? userUid = _currentUserUid();
    if (userUid == null || userUid.isEmpty) {
      return;
    }

    final UserVideoUploadRepository Function()? uploadRepositoryFactory =
        _userVideoUploadRepositoryFactory;
    if (uploadRepositoryFactory != null) {
      await uploadRepositoryFactory().deleteRecordingForUser(
        userUid: userUid,
        recording: recording,
      );
      return;
    }

    if (_deleteCloudRecordingForUser != null) {
      await _deleteCloudRecordingForUser!(userUid, recording);
    }
  }

  Future<void> _renameCloudRecordingIfNeeded(
    SavedVideoRecordingModel recording,
  ) async {
    final String? userUid = _currentUserUid();
    if (userUid == null || userUid.isEmpty) {
      return;
    }

    final UserVideoUploadRepository Function()? uploadRepositoryFactory =
        _userVideoUploadRepositoryFactory;
    if (uploadRepositoryFactory != null) {
      await uploadRepositoryFactory().updateRecordingTitleForUser(
        userUid: userUid,
        recordingId: recording.id,
        title: recording.title ?? '',
      );
      return;
    }

    if (_renameCloudRecordingForUser != null) {
      await _renameCloudRecordingForUser!(
        userUid,
        recording.id,
        recording.title ?? '',
      );
    }
  }

  Future<void> _restartCloudRecordingsSubscription() async {
    await _cloudRecordingsSubscription?.cancel();
    _cloudRecordingsSubscription = null;

    final String? userUid = _currentUserUid();
    if (userUid == null || userUid.isEmpty) {
      _cloudSavedRecordings = const <SavedVideoRecordingModel>[];
      if (mounted) {
        state = state.copyWith(savedRecordings: _mergedSavedRecordings());
      }
      return;
    }

    final Stream<List<SavedVideoRecordingModel>>? stream =
        _watchCloudRecordings(userUid);
    if (stream == null) {
      return;
    }

    _cloudRecordingsSubscription = stream.listen(
      (List<SavedVideoRecordingModel> cloudRecordings) {
        _cloudSavedRecordings = cloudRecordings;
        if (!mounted) {
          return;
        }

        state = state.copyWith(
          savedRecordings: _mergedSavedRecordings(),
          lifetimeRecordedCount:
              cloudRecordings.length > state.lifetimeRecordedCount
              ? cloudRecordings.length
              : state.lifetimeRecordedCount,
        );
        unawaited(_syncStoredUsageCountIfPossible(cloudRecordings.length));
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[video] cloud recordings stream failed: $error');
        debugPrintStack(
          label: '[video] cloud recordings stream stack',
          stackTrace: stackTrace,
        );
      },
    );
  }

  List<SavedVideoRecordingModel> _mergedSavedRecordings() {
    if (_cloudSavedRecordings.isEmpty) {
      return _localSavedRecordings;
    }
    if (_localSavedRecordings.isEmpty) {
      return _cloudSavedRecordings;
    }

    return _mergeRecordingLists(
      primary: _cloudSavedRecordings,
      secondary: _localSavedRecordings,
    );
  }

  Future<List<SavedVideoRecordingModel>> _refreshLocalRecordingsAfterMutation({
    required List<SavedVideoRecordingModel> baseRecordings,
  }) async {
    List<SavedVideoRecordingModel> merged = baseRecordings;

    try {
      final List<SavedVideoRecordingModel> reloadedLocalRecordings =
          await _repository.loadSavedRecordings();
      merged = _mergeRecordingLists(
        primary: merged,
        secondary: reloadedLocalRecordings,
      );
    } catch (_) {
      // Keep the optimistic in-memory list when local storage reload lags.
    }

    return merged;
  }

  Future<void> _syncStoredUsageCountIfPossible(int count) async {
    final String? userUid = _currentUserUid();
    if (userUid == null || userUid.isEmpty) {
      return;
    }

    final UserVideoUploadRepository Function()? uploadRepositoryFactory =
        _userVideoUploadRepositoryFactory;
    if (uploadRepositoryFactory == null) {
      return;
    }

    try {
      await uploadRepositoryFactory().syncRecordedVideosCountForUser(
        userUid: userUid,
        count: count,
      );
    } catch (error, stackTrace) {
      debugPrint('[video] stored usage sync failed: $error');
      debugPrintStack(
        label: '[video] stored usage sync stack',
        stackTrace: stackTrace,
      );
    }
  }

  bool _hasCloudBackedRecording(SavedVideoRecordingModel recording) {
    return recording.storageKind == VideoRecordingStorageKind.firebaseStorage ||
        (recording.publicShareStoragePath?.trim().isNotEmpty ?? false);
  }

  List<SavedVideoRecordingModel> _replaceRecordingInList(
    List<SavedVideoRecordingModel> recordings,
    SavedVideoRecordingModel updatedRecording,
  ) {
    return recordings
        .map((SavedVideoRecordingModel item) {
          return item.id == updatedRecording.id ? updatedRecording : item;
        })
        .toList(growable: false);
  }

  List<SavedVideoRecordingModel> _mergeRecordingLists({
    required List<SavedVideoRecordingModel> primary,
    required List<SavedVideoRecordingModel> secondary,
  }) {
    final Map<String, SavedVideoRecordingModel> recordingsById =
        <String, SavedVideoRecordingModel>{};
    for (final SavedVideoRecordingModel recording in secondary) {
      recordingsById[recording.id] = recording;
    }
    for (final SavedVideoRecordingModel recording in primary) {
      recordingsById[recording.id] = recording;
    }

    final List<SavedVideoRecordingModel> merged = recordingsById.values.toList(
      growable: false,
    );
    merged.sort(
      (SavedVideoRecordingModel a, SavedVideoRecordingModel b) =>
          b.savedAt.compareTo(a.savedAt),
    );
    return merged;
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

  Future<void> renameSavedRecording(
    SavedVideoRecordingModel recording, {
    required String title,
  }) async {
    final String trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      state = state.copyWith(
        feedbackMessage: 'Recording name cannot be empty.',
      );
      return;
    }

    final SavedVideoRecordingModel updatedRecording = recording.copyWith(
      title: trimmedTitle,
    );

    try {
      await persistSavedRecordingMetadata(updatedRecording);
      _localSavedRecordings = _replaceRecordingInList(
        _localSavedRecordings,
        updatedRecording,
      );

      if (_hasCloudBackedRecording(recording)) {
        await _renameCloudRecordingIfNeeded(updatedRecording);
        _cloudSavedRecordings = _replaceRecordingInList(
          _cloudSavedRecordings,
          updatedRecording,
        );
      }

      state = state.copyWith(
        savedRecordings: _mergedSavedRecordings(),
        feedbackMessage: 'Recording renamed to $trimmedTitle.',
      );
    } catch (error) {
      state = state.copyWith(feedbackMessage: error.toString());
    }
  }

  Future<void> deleteSavedRecording(SavedVideoRecordingModel recording) async {
    try {
      await _deleteCloudRecordingIfNeeded(recording);
      await _repository.deleteSavedRecording(recording);
      _localSavedRecordings = await _refreshLocalRecordingsAfterMutation(
        baseRecordings: _localSavedRecordings
            .where((SavedVideoRecordingModel item) => item.id != recording.id)
            .toList(growable: false),
      );
      _cloudSavedRecordings = _cloudSavedRecordings
          .where((SavedVideoRecordingModel item) => item.id != recording.id)
          .toList(growable: false);
      state = state.copyWith(
        savedRecordings: _mergedSavedRecordings(),
        feedbackMessage: '${recording.fileName} deleted.',
      );
    } catch (error) {
      state = state.copyWith(feedbackMessage: error.toString());
    }
  }

  Future<void> clearSavedRecordings({String? feedbackMessage}) async {
    try {
      await _repository.clearSavedRecordings();
      _localSavedRecordings = const <SavedVideoRecordingModel>[];
      final String? storageLocationLabel = await _safeStorageLocationLabel();
      state = state.copyWith(
        savedRecordings: _mergedSavedRecordings(),
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

    final CameraDescription activeCamera = _preferredCameraFrom(cameras);

    final CameraController controller = await _repository
        .createCameraController(
          activeCamera,
          enableAudio: state.isMicrophoneEnabled,
        );
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

  Future<void> toggleCameraEnabled() async {
    if (state.hasActiveRecording || state.isPreparingCameraPreview) {
      return;
    }

    if (state.isCameraEnabled) {
      await _disposeCameraController(clearActiveCamera: false);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isCameraEnabled: false,
        clearFeedbackMessage: true,
      );
      return;
    }

    state = state.copyWith(
      isCameraEnabled: true,
      isPreparingCameraPreview: true,
      clearFeedbackMessage: true,
    );

    String? feedbackMessage;
    try {
      await _ensureCameraController();
    } on _CancelledCameraPreviewPreparation {
      return;
    } catch (error, stackTrace) {
      debugPrint('[video] toggleCameraEnabled failed: $error');
      debugPrintStack(
        label: '[video] toggleCameraEnabled stack',
        stackTrace: stackTrace,
      );
      feedbackMessage = _describeRecordingError(error);
    }

    if (!mounted) {
      return;
    }

    state = state.copyWith(
      isCameraEnabled: feedbackMessage == null,
      isPreparingCameraPreview: false,
      feedbackMessage: feedbackMessage,
    );
  }

  Future<void> toggleMicrophoneEnabled() async {
    if (state.hasActiveRecording || state.isPreparingCameraPreview) {
      return;
    }

    final bool nextValue = !state.isMicrophoneEnabled;
    state = state.copyWith(
      isMicrophoneEnabled: nextValue,
      clearFeedbackMessage: true,
    );

    if (!state.isCameraEnabled) {
      return;
    }

    final CameraDescription? activeCamera = state.activeCamera;
    final CameraController? existingController = state.cameraController;
    if (activeCamera == null && existingController == null) {
      return;
    }

    state = state.copyWith(isPreparingCameraPreview: true);

    try {
      await _rebuildCameraController();
      if (!mounted) {
        return;
      }
      state = state.copyWith(isPreparingCameraPreview: false);
    } catch (error, stackTrace) {
      debugPrint('[video] toggleMicrophoneEnabled failed: $error');
      debugPrintStack(
        label: '[video] toggleMicrophoneEnabled stack',
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isPreparingCameraPreview: false,
        feedbackMessage: _describeRecordingError(error),
      );
    }
  }

  bool _usesDisplayCaptureHandshake(VideoRecordingMode mode) {
    return mode.capturesDisplay;
  }

  Future<bool> _waitForCountdownOverlayToDisappear() async {
    await Future<void>.delayed(Duration.zero);
    await SchedulerBinding.instance.endOfFrame;
    await Future<void>.delayed(_countdownDismissDelay);
    return mounted && state.isRecordingFlowVisible && !state.isCountingDown;
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

  Future<void> _disposeCameraController({bool clearActiveCamera = true}) async {
    _cameraControllerInitialization = null;
    final CameraController? controller = state.cameraController;
    state = state.copyWith(
      isPreparingCameraPreview: false,
      clearCameraController: true,
      clearActiveCamera: clearActiveCamera,
      recordingDuration: Duration.zero,
    );

    if (controller != null) {
      try {
        await controller.dispose();
      } catch (error, stackTrace) {
        debugPrint('[video] disposeCameraController failed: $error');
        debugPrintStack(
          label: '[video] disposeCameraController stack',
          stackTrace: stackTrace,
        );
      }
    }
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
          .createCameraController(
            activeCamera,
            enableAudio: state.isMicrophoneEnabled,
          );
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

  CameraDescription _preferredCameraFrom(List<CameraDescription> cameras) {
    final CameraDescription? previousCamera = state.activeCamera;
    if (previousCamera != null) {
      for (final CameraDescription camera in cameras) {
        if (camera.name == previousCamera.name &&
            camera.lensDirection == previousCamera.lensDirection) {
          return camera;
        }
      }
    }

    return cameras.firstWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
  }

  Future<void> _rebuildCameraController() async {
    final List<CameraDescription> cameras = state.availableCameras.isNotEmpty
        ? state.availableCameras
        : await _repository.getAvailableCameras();
    final CameraDescription selectedCamera = _preferredCameraFrom(cameras);

    final CameraController? existingController = state.cameraController;
    state = state.copyWith(clearCameraController: true);
    _cameraControllerInitialization = null;

    if (existingController != null) {
      await existingController.dispose();
    }

    final CameraController refreshedController = await _repository
        .createCameraController(
          selectedCamera,
          enableAudio: state.isMicrophoneEnabled,
        );
    try {
      await _repository.initializeCameraController(refreshedController);
    } catch (_) {
      await refreshedController.dispose();
      rethrow;
    }

    if (!mounted) {
      await refreshedController.dispose();
      return;
    }

    state = state.copyWith(
      cameraController: refreshedController,
      activeCamera: selectedCamera,
      availableCameras: cameras,
      supportsPauseResume: _repository.supportsPauseResume(),
    );
  }

  String _describeRecordingError(Object error) {
    if (error is PlatformException) {
      final String message = (error.message ?? '').trim();
      if (message.isNotEmpty) {
        return message;
      }
      if (error.code.isNotEmpty) {
        return error.code;
      }
    }

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
    unawaited(_cloudRecordingsSubscription?.cancel());
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

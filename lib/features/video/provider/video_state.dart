import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../data/enums/video_recording_mode.dart';
import '../data/enums/video_recording_status.dart';
import '../data/models/video_recording_flow_model.dart';
import '../data/models/saved_video_recording_model.dart';
import '../data/repository/video_recording_storage_support.dart';

@immutable
class VideoState {
  const VideoState({
    this.isLoading = true,
    this.flow,
    this.isRecordingFlowVisible = false,
    this.recordingStatus = VideoRecordingStatus.idle,
    this.countdownLabel,
    this.isPreparingCameraPreview = false,
    this.cameraController,
    this.availableCameras = const <CameraDescription>[],
    this.activeCamera,
    this.recordedVideo,
    this.savedRecordings = const <SavedVideoRecordingModel>[],
    this.lifetimeRecordedCount = 0,
    this.savedRecordingsStorageLocationLabel,
    this.recordingDuration = Duration.zero,
    this.supportsPauseResume = true,
    this.selectedRecordingMode = VideoRecordingMode.fullScreen,
    this.feedbackMessage,
  });

  final bool isLoading;
  final VideoRecordingFlowModel? flow;
  final bool isRecordingFlowVisible;
  final VideoRecordingStatus recordingStatus;
  final String? countdownLabel;
  final bool isPreparingCameraPreview;
  final CameraController? cameraController;
  final List<CameraDescription> availableCameras;
  final CameraDescription? activeCamera;
  final XFile? recordedVideo;
  final List<SavedVideoRecordingModel> savedRecordings;
  final int lifetimeRecordedCount;
  final String? savedRecordingsStorageLocationLabel;
  final Duration recordingDuration;
  final bool supportsPauseResume;
  final VideoRecordingMode selectedRecordingMode;
  final String? feedbackMessage;

  bool get isPreparingRecording =>
      recordingStatus == VideoRecordingStatus.preparing;

  bool get isCountingDown => countdownLabel != null;

  bool get isRecording => recordingStatus == VideoRecordingStatus.recording;

  bool get isPaused => recordingStatus == VideoRecordingStatus.paused;

  bool get isFinalizing => recordingStatus == VideoRecordingStatus.finalizing;

  bool get hasActiveRecording =>
      isRecording || isPaused || isPreparingRecording || isFinalizing;

  bool get hasReachedRecordingRestriction =>
      lifetimeRecordedCount >= lifetimeRecordedVideosRestrictionLimit;

  VideoState copyWith({
    bool? isLoading,
    VideoRecordingFlowModel? flow,
    bool? isRecordingFlowVisible,
    VideoRecordingStatus? recordingStatus,
    String? countdownLabel,
    bool? isPreparingCameraPreview,
    CameraController? cameraController,
    List<CameraDescription>? availableCameras,
    CameraDescription? activeCamera,
    XFile? recordedVideo,
    List<SavedVideoRecordingModel>? savedRecordings,
    int? lifetimeRecordedCount,
    String? savedRecordingsStorageLocationLabel,
    Duration? recordingDuration,
    bool? supportsPauseResume,
    VideoRecordingMode? selectedRecordingMode,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
    bool clearCameraController = false,
    bool clearActiveCamera = false,
    bool clearRecordedVideo = false,
    bool clearCountdownLabel = false,
  }) {
    return VideoState(
      isLoading: isLoading ?? this.isLoading,
      flow: flow ?? this.flow,
      isRecordingFlowVisible:
          isRecordingFlowVisible ?? this.isRecordingFlowVisible,
      recordingStatus: recordingStatus ?? this.recordingStatus,
      countdownLabel: clearCountdownLabel
          ? null
          : countdownLabel ?? this.countdownLabel,
      isPreparingCameraPreview:
          isPreparingCameraPreview ?? this.isPreparingCameraPreview,
      cameraController: clearCameraController
          ? null
          : cameraController ?? this.cameraController,
      availableCameras: availableCameras ?? this.availableCameras,
      activeCamera: clearActiveCamera
          ? null
          : activeCamera ?? this.activeCamera,
      recordedVideo: clearRecordedVideo
          ? null
          : recordedVideo ?? this.recordedVideo,
      savedRecordings: savedRecordings ?? this.savedRecordings,
      lifetimeRecordedCount:
          lifetimeRecordedCount ?? this.lifetimeRecordedCount,
      savedRecordingsStorageLocationLabel:
          savedRecordingsStorageLocationLabel ??
          this.savedRecordingsStorageLocationLabel,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      supportsPauseResume: supportsPauseResume ?? this.supportsPauseResume,
      selectedRecordingMode:
          selectedRecordingMode ?? this.selectedRecordingMode,
      feedbackMessage: clearFeedbackMessage
          ? null
          : feedbackMessage ?? this.feedbackMessage,
    );
  }
}

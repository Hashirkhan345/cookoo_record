import 'package:flutter/foundation.dart';

import 'package:camera/camera.dart';

import '../../data/enums/video_recording_mode.dart';
import '../../data/enums/video_recording_option_kind.dart';
import '../../data/models/video_recording_flow_model.dart';
import '../../data/models/video_recording_option_model.dart';
import '../../provider/video_state.dart';

List<VideoRecordingOptionModel> resolveRecordingPanelOptions({
  required VideoRecordingFlowModel flow,
  required VideoState state,
}) {
  final bool inputsReady =
      state.cameraController?.value.isInitialized ?? state.activeCamera != null;
  final bool showDisplayOption = supportedRecordingModesForCurrentPlatform()
      .any((VideoRecordingMode mode) => mode.capturesDisplay);
  final bool isAndroidDisplayMode =
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      state.selectedRecordingMode.capturesDisplay;

  return flow.panelOptions
      .where(
        (VideoRecordingOptionModel option) =>
            option.kind != VideoRecordingOptionKind.display ||
            showDisplayOption,
      )
      .map((VideoRecordingOptionModel option) {
        switch (option.kind) {
          case VideoRecordingOptionKind.display:
            return VideoRecordingOptionModel(
              kind: option.kind,
              label: state.selectedRecordingMode.label,
              status: option.status,
              highlighted: option.highlighted,
              selectedRecordingMode: state.selectedRecordingMode,
            );
          case VideoRecordingOptionKind.camera:
            return VideoRecordingOptionModel(
              kind: option.kind,
              label: _resolveCameraLabel(
                state.activeCamera,
                fallback: option.label,
              ),
              status: inputsReady
                  ? 'On'
                  : (isAndroidDisplayMode ? 'Preview off' : option.status),
              highlighted: option.highlighted,
            );
          case VideoRecordingOptionKind.microphone:
            return VideoRecordingOptionModel(
              kind: option.kind,
              label: option.label,
              status: inputsReady ? 'On' : option.status,
              highlighted: option.highlighted,
            );
        }
      })
      .toList(growable: false);
}

String _resolveCameraLabel(
  CameraDescription? activeCamera, {
  required String fallback,
}) {
  final String cameraName = activeCamera?.name.trim() ?? '';
  if (cameraName.isNotEmpty) {
    return cameraName;
  }

  switch (activeCamera?.lensDirection) {
    case CameraLensDirection.front:
      return 'Front Camera';
    case CameraLensDirection.back:
      return 'Back Camera';
    case CameraLensDirection.external:
      return 'External Camera';
    case null:
      return fallback;
  }
}

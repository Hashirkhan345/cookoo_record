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
              isStatusInteractive: option.isStatusInteractive,
            );
          case VideoRecordingOptionKind.camera:
            return VideoRecordingOptionModel(
              kind: option.kind,
              label: _resolveCameraLabel(
                state.activeCamera,
                fallback: option.label,
              ),
              status: state.isCameraEnabled && inputsReady ? 'On' : 'Off',
              highlighted: option.highlighted,
              isStatusInteractive: true,
            );
          case VideoRecordingOptionKind.microphone:
            return VideoRecordingOptionModel(
              kind: option.kind,
              label: _resolveMicrophoneLabel(option.label),
              status: state.isMicrophoneEnabled ? 'On' : 'Off',
              highlighted: option.highlighted,
              isStatusInteractive: true,
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
    return _friendlyCameraLabel(cameraName);
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

String _friendlyCameraLabel(String cameraName) {
  final String normalized = cameraName.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.toLowerCase().contains('facetime')) {
    return 'FaceTime camera';
  }
  if (normalized.length > 24) {
    return 'Camera';
  }
  return normalized;
}

String _resolveMicrophoneLabel(String label) {
  final String normalized = label.replaceAll(RegExp(r'\s+'), ' ').trim();
  final String lower = normalized.toLowerCase();
  if (lower.contains('macbook')) {
    return 'MacBook microphone';
  }
  if (lower.startsWith('default - ')) {
    return normalized.substring('default - '.length);
  }
  if (normalized.length > 26) {
    return 'Microphone';
  }
  return normalized;
}

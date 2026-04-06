import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloop/features/video/data/enums/video_recording_mode.dart';
import 'package:bloop/features/video/data/enums/video_recording_option_kind.dart';
import 'package:bloop/features/video/data/models/video_recording_flow_model.dart';
import 'package:bloop/features/video/data/models/video_recording_option_model.dart';
import 'package:bloop/features/video/data/models/video_shortcut_model.dart';
import 'package:bloop/features/video/presentation/controller/recording_panel_options_resolver.dart';
import 'package:bloop/features/video/provider/video_state.dart';

void main() {
  test(
    'resolved panel options use the active camera label and keep inputs on',
    () {
      const VideoRecordingFlowModel flow = VideoRecordingFlowModel(
        brandLabel: 'bloop',
        heroTitle: 'Record your first video',
        heroDescription: 'Description',
        heroActionLabel: 'Record a Video',
        helperMessage: 'Helper',
        previewTitle: 'Preview',
        startRecordingLabel: 'Start recording',
        recordingLimitLabel: '5 minute recording limit',
        tutorialLabel: 'Start a 1 minute tutorial',
        successMessage: 'Opened',
        panelOptions: <VideoRecordingOptionModel>[
          VideoRecordingOptionModel(
            kind: VideoRecordingOptionKind.display,
            label: 'Full Screen',
          ),
          VideoRecordingOptionModel(
            kind: VideoRecordingOptionKind.camera,
            label: 'Camera',
            status: 'Off',
          ),
          VideoRecordingOptionModel(
            kind: VideoRecordingOptionKind.microphone,
            label: 'Default - MacBook Microphone',
            status: 'Off',
            highlighted: true,
          ),
        ],
        shortcuts: <VideoShortcutModel>[],
      );

      final VideoState state = VideoState(
        selectedRecordingMode: VideoRecordingMode.window,
        activeCamera: const CameraDescription(
          name: 'FaceTime HD Camera',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 0,
        ),
      );

      final List<VideoRecordingOptionModel> resolvedOptions =
          resolveRecordingPanelOptions(flow: flow, state: state);

      expect(resolvedOptions.first.label, 'Window');
      expect(resolvedOptions[1].label, 'FaceTime HD Camera');
      expect(resolvedOptions[1].status, 'On');
      expect(resolvedOptions[2].label, 'Default - MacBook Microphone');
      expect(resolvedOptions[2].status, 'On');
    },
  );
}

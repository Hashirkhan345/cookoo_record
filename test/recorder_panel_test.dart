import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloop/features/video/data/enums/video_recording_mode.dart';
import 'package:bloop/features/video/data/enums/video_recording_option_kind.dart';
import 'package:bloop/features/video/data/models/video_recording_option_model.dart';
import 'package:bloop/features/video/presentation/widgets/recorder_panel.dart';

void main() {
  testWidgets('display mode menu triggers its callback', (
    WidgetTester tester,
  ) async {
    VideoRecordingMode? selectedMode;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecorderPanel(
            brandLabel: 'bloop',
            options: const <VideoRecordingOptionModel>[
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
            statusLabel: 'Start recording',
            recordingLimitLabel: '5 minute recording limit',
            tutorialLabel: 'Start a 1 minute tutorial',
            onClose: () async {},
            selectedRecordingMode: VideoRecordingMode.fullScreen,
            onSelectRecordingMode: (VideoRecordingMode mode) async {
              selectedMode = mode;
            },
            onStartRecording: () async {},
            isRecordingActive: false,
            isBusy: false,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('panelOption_display')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Current Tab').last);
    await tester.pumpAndSettle();

    expect(selectedMode, VideoRecordingMode.currentTab);
  });

  testWidgets('start button triggers recording callback while idle', (
    WidgetTester tester,
  ) async {
    var didStartRecording = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecorderPanel(
            brandLabel: 'bloop',
            options: const <VideoRecordingOptionModel>[
              VideoRecordingOptionModel(
                kind: VideoRecordingOptionKind.display,
                label: 'Full Screen',
              ),
            ],
            statusLabel: 'Start recording',
            recordingLimitLabel: '5 minute recording limit',
            tutorialLabel: 'Start a 1 minute tutorial',
            onClose: () async {},
            selectedRecordingMode: VideoRecordingMode.fullScreen,
            onSelectRecordingMode: (_) async {},
            onStartRecording: () async {
              didStartRecording = true;
            },
            isRecordingActive: false,
            isBusy: false,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('startRecordingButton')));
    await tester.pump();

    expect(didStartRecording, isTrue);
  });
}

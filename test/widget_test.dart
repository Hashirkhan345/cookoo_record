import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloop/features/video/data/enums/video_recording_status.dart';
import 'package:bloop/features/video/data/enums/video_recording_storage_kind.dart';
import 'package:bloop/features/video/data/models/saved_video_recording_model.dart';
import 'package:bloop/features/video/data/repository/video_repository.dart';
import 'package:bloop/features/video/provider/video_provider.dart';
import 'package:bloop/main.dart';

void main() {
  testWidgets('record video flow opens from the home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          videoControllerProvider.overrideWith((ref) => FakeVideoController()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Record a Video'), findsOneWidget);
    expect(find.byKey(const Key('recordingPanel')), findsNothing);
    expect(find.text('Saved recordings'), findsOneWidget);
    expect(find.byKey(const Key('emptySavedRecordingsState')), findsOneWidget);
    expect(find.text('Ways to use bloop for education'), findsNothing);

    await tester.tap(find.byKey(const Key('recordVideoButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recordingPanel')), findsOneWidget);
    expect(find.byKey(const Key('userProfileBubble')), findsOneWidget);
    expect(find.text('Start recording'), findsOneWidget);

    await tester.tap(find.byKey(const Key('startRecordingButton')));
    await tester.pumpAndSettle();

    expect(find.text('Recording live'), findsOneWidget);

    await tester.tap(find.byKey(const Key('stopRecordingButton')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('savedRecordingCard_fake-recording')),
      findsOneWidget,
    );
    expect(find.text('recording_fake.webm'), findsOneWidget);
    expect(find.text('Ways to use bloop for education'), findsNothing);
  });

  testWidgets('home screen still loads when saved recordings fail to restore', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          videoRepositoryProvider.overrideWith(
            (ref) => FailingSavedRecordingsRepository(),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Record a Video'), findsOneWidget);
    expect(find.text('Saved recordings'), findsOneWidget);
    expect(find.byKey(const Key('emptySavedRecordingsState')), findsOneWidget);
    expect(find.text('Ways to use bloop for education'), findsNothing);
    expect(
      find.text(
        'Saved recordings could not be restored. You can keep recording.',
      ),
      findsOneWidget,
    );
  });
}

class FakeVideoController extends VideoController {
  FakeVideoController() : super(LocalVideoRepository()) {
    state = state.copyWith(
      isLoading: false,
      flow: LocalVideoRepository().loadVideoRecordingFlowSync(),
      savedRecordingsStorageLocationLabel: 'Browser local storage',
    );
  }

  @override
  Future<void> load() async {}

  @override
  void openRecordingFlow() {
    state = state.copyWith(
      isRecordingFlowVisible: true,
      clearFeedbackMessage: true,
    );
  }

  @override
  Future<void> startRecordingSession() async {
    state = state.copyWith(
      isRecordingFlowVisible: true,
      supportsPauseResume: true,
      recordingStatus: VideoRecordingStatus.recording,
    );
  }

  @override
  Future<void> togglePauseResumeRecording() async {
    state = state.copyWith(
      recordingStatus: state.isPaused
          ? VideoRecordingStatus.recording
          : VideoRecordingStatus.paused,
    );
  }

  @override
  Future<void> stopRecordingSession() async {
    state = state.copyWith(
      isRecordingFlowVisible: false,
      recordingStatus: VideoRecordingStatus.idle,
      savedRecordings: <SavedVideoRecordingModel>[fakeSavedRecording],
    );
  }

  @override
  Future<void> deleteRecordingSession() async {
    state = state.copyWith(
      isRecordingFlowVisible: false,
      recordingStatus: VideoRecordingStatus.idle,
    );
  }

  @override
  Future<void> closeRecordingFlow() async {
    state = state.copyWith(
      isRecordingFlowVisible: false,
      recordingStatus: VideoRecordingStatus.idle,
    );
  }

  static final SavedVideoRecordingModel fakeSavedRecording =
      SavedVideoRecordingModel(
        id: 'fake-recording',
        fileName: 'recording_fake.webm',
        savedAt: DateTime(2026, 3, 13, 10, 30),
        duration: Duration(seconds: 19),
        storageKind: VideoRecordingStorageKind.browserLocalStorage,
        storagePath: 'video_saved_recording_data_fake-recording',
        playbackPath: 'blob:fake-recording',
        mimeType: 'video/webm',
        sizeInBytes: 2048,
      );
}

class FailingSavedRecordingsRepository extends LocalVideoRepository {
  FailingSavedRecordingsRepository();

  @override
  Future<List<SavedVideoRecordingModel>> loadSavedRecordings() async {
    throw StateError('Corrupt browser storage');
  }

  @override
  Future<String> getSavedRecordingsStorageLocationLabel() async {
    return 'Browser local storage';
  }
}

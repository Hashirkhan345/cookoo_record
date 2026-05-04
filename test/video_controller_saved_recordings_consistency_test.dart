import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bloop/features/video/data/enums/video_recording_mode.dart';
import 'package:bloop/features/video/data/enums/video_recording_status.dart';
import 'package:bloop/features/video/data/enums/video_recording_storage_kind.dart';
import 'package:bloop/features/video/data/models/saved_video_recording_model.dart';
import 'package:bloop/features/video/data/models/video_recording_flow_model.dart';
import 'package:bloop/features/video/data/models/video_recording_option_model.dart';
import 'package:bloop/features/video/data/models/video_shortcut_model.dart';
import 'package:bloop/features/video/data/repository/video_repository.dart';
import 'package:bloop/features/video/provider/video_provider.dart';
import 'package:bloop/features/video/provider/video_state.dart';
import 'package:bloop/features/video/data/repository/user_video_upload_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  test(
    'stopRecordingSession keeps existing cloud videos visible after a new upload',
    () async {
      final SavedVideoRecordingModel olderCloudRecording = _recording(
        id: 'cloud-older',
        savedAt: DateTime(2026, 5, 1, 10, 0),
        playbackPath: 'https://cdn.example.com/cloud-older.webm',
        storagePath: 'users/test-user/videos/cloud-older.webm',
        storageKind: VideoRecordingStorageKind.firebaseStorage,
      );
      final SavedVideoRecordingModel newerCloudRecording = _recording(
        id: 'cloud-newer',
        savedAt: DateTime(2026, 5, 1, 12, 0),
        playbackPath: 'https://cdn.example.com/cloud-newer.webm',
        storagePath: 'users/test-user/videos/cloud-newer.webm',
        storageKind: VideoRecordingStorageKind.firebaseStorage,
      );
      final SavedVideoRecordingModel existingLocalRecording = _recording(
        id: 'local-existing',
        savedAt: DateTime(2026, 5, 2, 11, 58),
        playbackPath: 'blob:local-existing',
        storagePath: 'video_saved_recording_data_local-existing',
      );
      final SavedVideoRecordingModel freshlySavedRecording = _recording(
        id: 'local-new',
        savedAt: DateTime(2026, 5, 2, 12, 0),
        playbackPath: 'blob:local-new',
        storagePath: 'video_saved_recording_data_local-new',
      );
      final SavedVideoRecordingModel uploadedRecording = freshlySavedRecording
          .copyWith(
            publicShareUrl: 'https://app.example.com/share/videos/local-new',
            publicShareStoragePath: 'users/test-user/videos/local-new.webm',
            sharedAt: DateTime(2026, 5, 2, 12, 1),
          );

      final _TestVideoRepository repository = _TestVideoRepository(
        savedRecordingToReturn: freshlySavedRecording,
        localRecordings: <SavedVideoRecordingModel>[
          freshlySavedRecording,
          existingLocalRecording,
        ],
      );
      final _TestVideoController controller = _TestVideoController(
        repository,
        uploadResult: UserVideoUploadResult(
          videoUrl: 'https://cdn.example.com/local-new.webm',
          storagePath: 'users/test-user/videos/local-new.webm',
          shareUrl: 'https://app.example.com/share/videos/local-new',
          uploadedAt: DateTime(2026, 5, 2, 12, 1),
        ),
        cloudRecordings: <SavedVideoRecordingModel>[
          uploadedRecording,
          existingLocalRecording,
          newerCloudRecording,
          olderCloudRecording,
        ],
      );
      await controller.load();
      controller.seedState(
        controller.state.copyWith(
          recordingStatus: VideoRecordingStatus.recording,
          selectedRecordingMode: VideoRecordingMode.fullScreen,
          lifetimeRecordedCount: 3,
        ),
      );

      await controller.stopRecordingSession();

      expect(
        controller.state.savedRecordings.map((recording) => recording.id),
        containsAll(<String>[
          'local-new',
          'local-existing',
          'cloud-newer',
          'cloud-older',
        ]),
      );
      expect(controller.state.savedRecordings, hasLength(4));
      expect(controller.state.savedRecordings.first.id, 'local-new');
      expect(
        controller.state.feedbackMessage,
        'Recording saved and uploaded to your workspace.',
      );
    },
  );

  test('load stays in sync with cloud stream changes', () async {
    final StreamController<List<SavedVideoRecordingModel>> streamController =
        StreamController<List<SavedVideoRecordingModel>>.broadcast();
    addTearDown(streamController.close);

    final SavedVideoRecordingModel localRecording = _recording(
      id: 'local-existing',
      savedAt: DateTime(2026, 5, 2, 11, 58),
      playbackPath: 'blob:local-existing',
      storagePath: 'video_saved_recording_data_local-existing',
    );
    final SavedVideoRecordingModel olderCloudRecording = _recording(
      id: 'cloud-older',
      savedAt: DateTime(2026, 5, 1, 10, 0),
      playbackPath: 'https://cdn.example.com/cloud-older.webm',
      storagePath: 'users/test-user/videos/cloud-older.webm',
      storageKind: VideoRecordingStorageKind.firebaseStorage,
    );
    final SavedVideoRecordingModel newestCloudRecording = _recording(
      id: 'cloud-newest',
      savedAt: DateTime(2026, 5, 2, 12, 2),
      playbackPath: 'https://cdn.example.com/cloud-newest.webm',
      storagePath: 'users/test-user/videos/cloud-newest.webm',
      storageKind: VideoRecordingStorageKind.firebaseStorage,
    );

    final _TestVideoRepository repository = _TestVideoRepository(
      savedRecordingToReturn: localRecording,
      localRecordings: <SavedVideoRecordingModel>[localRecording],
    );
    final _TestVideoController controller = _TestVideoController(
      repository,
      cloudRecordings: <SavedVideoRecordingModel>[olderCloudRecording],
      watchCloudRecordingsForUser: (String userUid) => streamController.stream,
    );

    await controller.load();

    expect(
      controller.state.savedRecordings.map((recording) => recording.id),
      containsAll(<String>['local-existing', 'cloud-older']),
    );

    streamController.add(<SavedVideoRecordingModel>[
      newestCloudRecording,
      olderCloudRecording,
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(
      controller.state.savedRecordings.map((recording) => recording.id),
      containsAll(<String>['local-existing', 'cloud-older', 'cloud-newest']),
    );
    expect(controller.state.savedRecordings.first.id, 'cloud-newest');

    streamController.add(<SavedVideoRecordingModel>[newestCloudRecording]);
    await Future<void>.delayed(Duration.zero);

    expect(
      controller.state.savedRecordings.map((recording) => recording.id),
      containsAll(<String>['local-existing', 'cloud-newest']),
    );
    expect(
      controller.state.savedRecordings.map((recording) => recording.id),
      isNot(contains('cloud-older')),
    );
  });

  test('recording restriction follows current saved recordings count', () {
    final List<SavedVideoRecordingModel> recordings = List.generate(
      8,
      (int index) => _recording(
        id: 'recording-$index',
        savedAt: DateTime(2026, 5, 2, 12, index),
        playbackPath: 'blob:recording-$index',
        storagePath: 'video_saved_recording_data_recording-$index',
      ),
    );

    final VideoState state = VideoState(
      savedRecordings: recordings,
      lifetimeRecordedCount: 9,
    );

    expect(state.currentRecordedCount, 8);
    expect(state.hasReachedRecordingRestriction, isFalse);
  });

  test('renameSavedRecording updates only the visible title', () async {
    final SavedVideoRecordingModel recording = _recording(
      id: 'local-existing',
      savedAt: DateTime(2026, 5, 2, 11, 58),
      playbackPath: 'blob:local-existing',
      storagePath: 'video_saved_recording_data_local-existing',
    );

    final _TestVideoRepository repository = _TestVideoRepository(
      savedRecordingToReturn: recording,
      localRecordings: <SavedVideoRecordingModel>[recording],
    );
    final _TestVideoController controller = _TestVideoController(repository);

    await controller.load();
    await controller.renameSavedRecording(recording, title: 'Sprint demo.webm');

    expect(controller.state.savedRecordings, hasLength(1));
    expect(controller.state.savedRecordings.first.title, 'Sprint demo.webm');
    expect(
      controller.state.savedRecordings.first.fileName,
      'local-existing.webm',
    );
  });
}

SavedVideoRecordingModel _recording({
  required String id,
  required DateTime savedAt,
  required String playbackPath,
  required String storagePath,
  VideoRecordingStorageKind storageKind =
      VideoRecordingStorageKind.browserIndexedDb,
}) {
  return SavedVideoRecordingModel(
    id: id,
    fileName: '$id.webm',
    savedAt: savedAt,
    duration: const Duration(seconds: 5),
    storageKind: storageKind,
    storagePath: storagePath,
    playbackPath: playbackPath,
    mimeType: 'video/webm',
    sizeInBytes: 1024,
  );
}

class _TestVideoController extends VideoController {
  _TestVideoController(
    super.repository, {
    UserVideoUploadResult? uploadResult,
    List<SavedVideoRecordingModel> cloudRecordings =
        const <SavedVideoRecordingModel>[],
    Stream<List<SavedVideoRecordingModel>> Function(String userUid)?
    watchCloudRecordingsForUser,
  }) : super(
         currentUserUid: () => 'test-user',
         uploadRecordingForUser: uploadResult == null
             ? null
             : (String userUid, SavedVideoRecordingModel recording) async =>
                   uploadResult,
         loadCloudRecordingsForUser: (String userUid) async => cloudRecordings,
         watchCloudRecordingsForUser: watchCloudRecordingsForUser,
       );

  void seedState(VideoState nextState) {
    state = nextState;
  }
}

class _TestVideoRepository implements VideoRepository {
  _TestVideoRepository({
    required this.savedRecordingToReturn,
    required this.localRecordings,
    this.flow = _testFlow,
  });

  final SavedVideoRecordingModel savedRecordingToReturn;
  final List<SavedVideoRecordingModel> localRecordings;
  final VideoRecordingFlowModel flow;

  @override
  Future<void> cancelPreparedDisplayCapture() async {}

  @override
  Future<void> clearSavedRecordings() async {}

  @override
  Future<CameraController> createCameraController(
    CameraDescription camera, {
    required bool enableAudio,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteRecording(XFile recordedFile) async {}

  @override
  Future<void> deleteSavedRecording(SavedVideoRecordingModel recording) async {}

  @override
  Future<List<CameraDescription>> getAvailableCameras() async {
    return const <CameraDescription>[];
  }

  @override
  Future<String> getSavedRecordingsStorageLocationLabel() async {
    return 'Browser IndexedDB';
  }

  @override
  Future<void> initializeCameraController(CameraController controller) async {}

  @override
  Future<List<SavedVideoRecordingModel>> loadSavedRecordings() async {
    return localRecordings;
  }

  @override
  Future<int> loadLifetimeRecordingCount() async {
    return localRecordings.length;
  }

  @override
  Future<VideoRecordingFlowModel> loadVideoRecordingFlow() async {
    return flow;
  }

  @override
  Future<void> pauseRecording(CameraController? controller) async {}

  @override
  Future<void> prepareDisplayCapture({
    required VideoRecordingMode mode,
    bool isMicrophoneEnabled = true,
  }) async {}

  @override
  Future<void> resumeRecording(CameraController? controller) async {}

  @override
  Future<SavedVideoRecordingModel> saveRecording(
    XFile recordedFile, {
    required Duration duration,
  }) async {
    return savedRecordingToReturn;
  }

  @override
  void setExternalStopListener(void Function()? listener) {}

  @override
  Future<void> startPreparedDisplayCapture() async {}

  @override
  Future<void> startRecording(
    CameraController? controller, {
    required VideoRecordingMode mode,
    bool isMicrophoneEnabled = true,
  }) async {}

  @override
  Future<XFile> stopRecording(CameraController? controller) async {
    return XFile(
      savedRecordingToReturn.playbackPath,
      mimeType: savedRecordingToReturn.mimeType,
      name: savedRecordingToReturn.fileName,
    );
  }

  @override
  bool supportsPauseResume() {
    return true;
  }
}

const VideoRecordingFlowModel _testFlow = VideoRecordingFlowModel(
  brandLabel: 'Aks',
  heroTitle: 'Record',
  heroDescription: 'Record',
  heroActionLabel: 'Start',
  helperMessage: 'Help',
  previewTitle: 'Preview',
  startRecordingLabel: 'Start',
  recordingLimitLabel: 'Limit',
  tutorialLabel: 'Guide',
  successMessage: 'Ready',
  panelOptions: <VideoRecordingOptionModel>[],
  shortcuts: <VideoShortcutModel>[],
);

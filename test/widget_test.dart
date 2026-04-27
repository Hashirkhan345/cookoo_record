import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloop/features/auth/data/models/app_user.dart';
import 'package:bloop/features/auth/data/repository/auth_repository.dart';
import 'package:bloop/features/auth/provider/auth_provider.dart';
import 'package:bloop/features/video/data/enums/video_recording_status.dart';
import 'package:bloop/features/video/data/enums/video_recording_mode.dart';
import 'package:bloop/features/video/data/enums/video_recording_storage_kind.dart';
import 'package:bloop/features/video/data/models/saved_video_recording_model.dart';
import 'package:bloop/features/video/data/repository/video_repository.dart';
import 'package:bloop/features/video/provider/video_provider.dart';
import 'package:bloop/features/video/presentation/screens/record_video_flow_screen.dart';
import 'package:bloop/main.dart';

void main() {
  testWidgets('forgot password screen opens from the login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authRepositoryProvider.overrideWith(
            (ref) => FakeLoggedOutAuthRepository(),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Forgot password?'), findsOneWidget);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot password'), findsOneWidget);
    expect(find.text('Back to sign in'), findsOneWidget);
  });

  testWidgets('record video flow opens from the home screen', (
    WidgetTester tester,
  ) async {
    _setDesktopSurface(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authRepositoryProvider.overrideWith((ref) => FakeAuthRepository()),
          videoControllerProvider.overrideWith((ref) => FakeVideoController()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Record a Video'), findsOneWidget);
    expect(find.byKey(const Key('recordingPanel')), findsNothing);
    expect(find.text('Videos'), findsOneWidget);
    expect(find.byKey(const Key('emptySavedRecordingsState')), findsOneWidget);
    expect(find.text('Ways to use bloop for education'), findsNothing);

    await tester.tap(find.byKey(const Key('recordVideoButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recordingPanel')), findsOneWidget);
    expect(find.byKey(const Key('userProfileBubble')), findsOneWidget);
    expect(find.text('Start recording'), findsOneWidget);

    await tester.tap(find.byKey(const Key('startRecordingButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stopRecordingButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('stopRecordingButton')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('savedRecordingCard_fake-recording')),
      findsOneWidget,
    );
    expect(find.text('Ways to use bloop for education'), findsNothing);
  });

  testWidgets('home screen still loads when saved recordings fail to restore', (
    WidgetTester tester,
  ) async {
    _setDesktopSurface(tester);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authRepositoryProvider.overrideWith((ref) => FakeAuthRepository()),
          videoRepositoryProvider.overrideWith(
            (ref) => FailingSavedRecordingsRepository(),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Record a Video'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
    expect(find.byKey(const Key('emptySavedRecordingsState')), findsOneWidget);
    expect(find.text('Ways to use bloop for education'), findsNothing);
    expect(
      find.text(
        'Saved recordings could not be restored. You can keep recording.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('start recording shows the countdown before going live', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          videoControllerProvider.overrideWith(
            (ref) => CountdownVideoController(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: RecordVideoFlowScreen())),
      ),
    );
    await tester.pump();

    expect(find.text('Start recording'), findsOneWidget);

    await tester.tap(find.byKey(const Key('startRecordingButton')));
    await tester.pump();

    expect(find.byKey(const Key('recordingCountdownOverlay')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Go'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump();

    expect(find.byKey(const Key('recordingCountdownOverlay')), findsNothing);
    expect(find.byKey(const Key('stopRecordingButton')), findsOneWidget);
  });

  testWidgets('android screen capture hides setup panel after native start', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      _setDesktopSurface(tester);

      final AndroidDisplayCaptureRepository repository =
          AndroidDisplayCaptureRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            videoControllerProvider.overrideWith(
              (ref) => AndroidDisplayCaptureVideoController(repository),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RecordVideoFlowScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('recordingPanel')), findsOneWidget);

      await tester.tap(find.byKey(const Key('startRecordingButton')));
      await tester.pump();

      expect(repository.didPrepareDisplayCapture, isTrue);
      expect(repository.didStartPreparedDisplayCapture, isTrue);
      expect(find.byKey(const Key('recordingPanel')), findsNothing);
      expect(find.byKey(const Key('stopRecordingButton')), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void _setDesktopSurface(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1400);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
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
  Future<void> openRecordingFlow() async {
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

class CountdownVideoController extends VideoController {
  CountdownVideoController() : super(CountdownVideoRepository()) {
    state = state.copyWith(
      isLoading: false,
      flow: LocalVideoRepository().loadVideoRecordingFlowSync(),
      isRecordingFlowVisible: true,
      savedRecordingsStorageLocationLabel: 'Browser local storage',
    );
  }

  @override
  Future<void> load() async {}
}

class CountdownVideoRepository extends LocalVideoRepository {
  CountdownVideoRepository();

  @override
  Future<List<CameraDescription>> getAvailableCameras() async {
    return const <CameraDescription>[];
  }

  @override
  Future<void> startRecording(
    CameraController? controller, {
    required VideoRecordingMode mode,
  }) async {}
}

class AndroidDisplayCaptureVideoController extends VideoController {
  AndroidDisplayCaptureVideoController(this.repository) : super(repository) {
    state = state.copyWith(
      isLoading: false,
      flow: repository.loadVideoRecordingFlowSync(),
      isRecordingFlowVisible: true,
      selectedRecordingMode: VideoRecordingMode.fullScreen,
      savedRecordingsStorageLocationLabel: 'Device storage',
    );
  }

  final AndroidDisplayCaptureRepository repository;

  @override
  Future<void> load() async {}
}

class AndroidDisplayCaptureRepository extends LocalVideoRepository {
  AndroidDisplayCaptureRepository();

  bool didPrepareDisplayCapture = false;
  bool didStartPreparedDisplayCapture = false;

  @override
  Future<void> prepareDisplayCapture({required VideoRecordingMode mode}) async {
    didPrepareDisplayCapture = true;
  }

  @override
  Future<void> startPreparedDisplayCapture() async {
    didStartPreparedDisplayCapture = true;
  }
}

class FakeAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> authStateChanges() {
    return Stream<AppUser?>.value(_user);
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    return _user;
  }

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    return _user;
  }

  @override
  Future<void> deleteCurrentUser() async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _user;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    return _user;
  }

  @override
  Future<void> signOut() async {}

  static const AppUser _user = AppUser(
    uid: 'test-user',
    email: 'tester@example.com',
    name: 'Test User',
    emailVerified: true,
  );
}

class FakeLoggedOutAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> authStateChanges() {
    return Stream<AppUser?>.value(null);
  }

  @override
  Future<void> deleteCurrentUser() async {}

  @override
  Future<AppUser?> getCurrentUser() async {
    return null;
  }

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppUser> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

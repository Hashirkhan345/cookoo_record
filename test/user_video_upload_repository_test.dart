import 'package:flutter_test/flutter_test.dart';

import 'package:bloop/features/video/data/enums/video_recording_storage_kind.dart';
import 'package:bloop/features/video/data/models/saved_video_recording_model.dart';
import 'package:bloop/features/video/data/repository/user_video_upload_repository.dart';

void main() {
  test('buildUserVideoStoragePath scopes videos by user uid', () {
    final SavedVideoRecordingModel recording = SavedVideoRecordingModel(
      id: 'recording_123',
      fileName: 'session.webm',
      savedAt: DateTime(2026, 4, 29, 12),
      duration: const Duration(seconds: 8),
      storageKind: VideoRecordingStorageKind.browserIndexedDb,
      storagePath: 'local-recording',
      playbackPath: 'blob:local-recording',
      mimeType: 'video/webm',
      sizeInBytes: 12,
    );

    expect(
      UserVideoUploadRepository.buildUserVideoStoragePath(
        userUid: 'user_abc',
        recording: recording,
      ),
      'users/user_abc/videos/recording_123.webm',
    );
  });

  test('buildShareableLink creates an app share route', () {
    expect(
      UserVideoUploadRepository.buildShareableLink('recording 123'),
      contains('/share/videos/recording%20123'),
    );
    expect(
      UserVideoUploadRepository.buildShareableLink('recording 123'),
      isNot(contains('#/home')),
    );
  });

  test('buildShareableLink can include a playback fallback source', () {
    final String shareUrl = UserVideoUploadRepository.buildShareableLink(
      'recording_123',
      playbackUrl: 'https://firebasestorage.googleapis.com/video.webm?token=1',
    );

    final Uri uri = Uri.parse(shareUrl);
    expect(shareUrl, contains('/share/videos/recording_123'));
    expect(
      uri.queryParameters['source'],
      'https://firebasestorage.googleapis.com/video.webm?token=1',
    );
  });

  test('saved recording json keeps a single canonical share field', () {
    final SavedVideoRecordingModel recording = SavedVideoRecordingModel(
      id: 'recording_123',
      fileName: 'session.webm',
      savedAt: DateTime(2026, 4, 29, 12),
      duration: const Duration(seconds: 8),
      storageKind: VideoRecordingStorageKind.browserIndexedDb,
      storagePath: 'local-recording',
      playbackPath: 'blob:local-recording',
      mimeType: 'video/webm',
      sizeInBytes: 12,
      publicShareUrl: 'https://example.com/share/videos/recording_123',
    );

    final Map<String, dynamic> json = recording.toJson();

    expect(
      json['publicShareUrl'],
      'https://example.com/share/videos/recording_123',
    );
    expect(json.containsKey('shareUrl'), isFalse);
    expect(json.containsKey('shareableUrl'), isFalse);
    expect(json.containsKey('shareableLink'), isFalse);
  });

  test('saved recording json still reads legacy share fields', () {
    final SavedVideoRecordingModel recording =
        SavedVideoRecordingModel.fromJson(<String, dynamic>{
          'id': 'recording_123',
          'fileName': 'session.webm',
          'savedAt': DateTime(2026, 4, 29, 12).toIso8601String(),
          'durationMs': 8000,
          'storageKind': VideoRecordingStorageKind.browserIndexedDb.name,
          'storagePath': 'local-recording',
          'mimeType': 'video/webm',
          'sizeInBytes': 12,
          'shareableLink': 'https://example.com/share/videos/recording_123',
        });

    expect(
      recording.publicShareUrl,
      'https://example.com/share/videos/recording_123',
    );
  });
}

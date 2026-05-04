import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import '../models/saved_video_recording_model.dart';
import 'saved_recording_share_upload.dart';
import 'user_video_upload_repository.dart';
import 'video_recording_storage_support.dart';

class PublicVideoShareRepository {
  PublicVideoShareRepository({
    firebase_auth.FirebaseAuth? auth,
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  static final Map<String, Future<String>> _inflightShareUrls =
      <String, Future<String>>{};

  final firebase_auth.FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  Future<String> ensureShareUrl(SavedVideoRecordingModel recording) async {
    if (recording.publicShareUrl case final String existingUrl
        when existingUrl.isNotEmpty) {
      if (_isAppShareUrl(existingUrl)) {
        return _prepareUserShareUrl(recording);
      }

      return _publishExistingPlaybackUrl(
        recording: recording,
        playbackUrl: existingUrl,
      );
    }

    final String? storedShareUrl = await _loadStoredUserShareUrl(recording);
    if (storedShareUrl != null && storedShareUrl.isNotEmpty) {
      if (!_isAppShareUrl(storedShareUrl)) {
        return _publishExistingPlaybackUrl(
          recording: recording,
          playbackUrl: storedShareUrl,
        );
      }

      final SavedVideoRecordingModel updatedRecording = recording.copyWith(
        publicShareUrl: storedShareUrl,
      );
      await persistSavedRecordingMetadata(updatedRecording);
      return _prepareUserShareUrl(updatedRecording);
    }

    final Future<String>? inflight = _inflightShareUrls[recording.id];
    if (inflight != null) {
      return inflight;
    }

    final Future<String> creation = _createShareUrl(recording);
    _inflightShareUrls[recording.id] = creation;

    try {
      return await creation;
    } finally {
      if (identical(_inflightShareUrls[recording.id], creation)) {
        _inflightShareUrls.remove(recording.id);
      }
    }
  }

  Future<void> prewarmShareUrl(SavedVideoRecordingModel recording) async {
    if (recording.publicShareUrl case final String existingUrl
        when existingUrl.isNotEmpty) {
      return;
    }

    try {
      await ensureShareUrl(recording);
    } catch (_) {
      // Prewarming is opportunistic. Interactive share still surfaces errors.
    }
  }

  Future<String?> _loadStoredUserShareUrl(
    SavedVideoRecordingModel recording,
  ) async {
    final firebase_auth.User? user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('videos')
          .doc(recording.id)
          .get();
      final Map<String, dynamic>? data = snapshot.data();
      if (data == null) {
        return null;
      }

      for (final String field in <String>[
        'shareUrl',
        'publicShareUrl',
        'shareableUrl',
        'shareableLink',
      ]) {
        final String? value = (data[field] as String?)?.trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    } on FirebaseException {
      return null;
    }

    return null;
  }

  Future<String> _prepareUserShareUrl(
    SavedVideoRecordingModel recording,
  ) async {
    final String shareUrl = await _persistUserSharedMetadata(recording);
    if (shareUrl != recording.publicShareUrl) {
      await persistSavedRecordingMetadata(
        recording.copyWith(publicShareUrl: shareUrl, sharedAt: DateTime.now()),
      );
    }
    return shareUrl;
  }

  Future<String> _persistUserSharedMetadata(
    SavedVideoRecordingModel updatedRecording,
  ) async {
    final firebase_auth.User? user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in before creating a share link.');
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('videos')
          .doc(updatedRecording.id)
          .get();
      final Map<String, dynamic>? data = snapshot.data();
      if (data == null) {
        throw StateError(
          'This recording is not uploaded yet. Record again or wait for upload to finish.',
        );
      }

      final String? playbackUrl = _firstNonEmptyString(data, <String>[
        'videoUrl',
        'url',
        'downloadUrl',
      ]);
      if (playbackUrl == null || _isAppShareUrl(playbackUrl)) {
        throw StateError(
          'This recording is missing its playback URL. Upload it again before sharing.',
        );
      }

      final String shareUrl = UserVideoUploadRepository.buildShareableLink(
        updatedRecording.id,
        playbackUrl: playbackUrl,
      );
      final DateTime uploadedAt =
          _asDateTime(data['uploadedAt']) ?? DateTime.now();

      await _firestore
          .collection('sharedVideos')
          .doc(updatedRecording.id)
          .set(<String, Object?>{
            'id': updatedRecording.id,
            'videoId': updatedRecording.id,
            'ownerUid': user.uid,
            'fileName': updatedRecording.fileName,
            'url': playbackUrl,
            'videoUrl': playbackUrl,
            'storagePath': data['storagePath'],
            'createdAt': data['createdAt'] ?? updatedRecording.savedAt,
            'uploadedAt': Timestamp.fromDate(uploadedAt),
            'shareUrl': shareUrl,
            'shareableUrl': FieldValue.delete(),
            'shareableLink': FieldValue.delete(),
            'publicShareUrl': FieldValue.delete(),
            'mimeType': updatedRecording.mimeType,
            'durationMs': updatedRecording.duration.inMilliseconds,
            'sizeInBytes': updatedRecording.sizeInBytes,
          }, SetOptions(merge: true));
      return shareUrl;
    } on FirebaseException catch (error) {
      throw StateError(_describeFirestoreError(error));
    }
  }

  Future<String> _createShareUrl(SavedVideoRecordingModel recording) async {
    if (recording.publicShareUrl case final String existingUrl
        when existingUrl.isNotEmpty) {
      return existingUrl;
    }

    final String storagePath = _resolveStoragePath(recording);
    final Reference ref = _storage.ref(storagePath);

    String downloadUrl;
    try {
      downloadUrl = await ref.getDownloadURL();
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') {
        downloadUrl = await _uploadAndGetDownloadUrl(ref, recording);
      } else {
        throw StateError(_describeStorageError(error));
      }
    } catch (_) {
      downloadUrl = await _uploadAndGetDownloadUrl(ref, recording);
    }

    final String shareUrl = UserVideoUploadRepository.buildShareableLink(
      recording.id,
      playbackUrl: downloadUrl,
    );
    final SavedVideoRecordingModel updatedRecording = recording.copyWith(
      publicShareUrl: shareUrl,
      publicShareStoragePath: storagePath,
      sharedAt: DateTime.now(),
    );
    await persistSavedRecordingMetadata(updatedRecording);
    await _persistSharedMetadata(
      updatedRecording,
      playbackUrl: downloadUrl,
      shareUrl: shareUrl,
    );
    return shareUrl;
  }

  Future<String> _uploadAndGetDownloadUrl(
    Reference ref,
    SavedVideoRecordingModel recording,
  ) async {
    try {
      return await uploadSavedRecordingAndGetDownloadUrl(ref, recording);
    } on FirebaseException catch (error) {
      throw StateError(_describeStorageError(error));
    }
  }

  Future<void> _persistSharedMetadata(
    SavedVideoRecordingModel updatedRecording, {
    required String playbackUrl,
    required String shareUrl,
  }) async {
    try {
      await _firestore
          .collection('sharedVideos')
          .doc(updatedRecording.id)
          .set(<String, Object?>{
            'id': updatedRecording.id,
            'videoId': updatedRecording.id,
            'fileName': updatedRecording.fileName,
            'url': playbackUrl,
            'videoUrl': playbackUrl,
            'mimeType': updatedRecording.mimeType,
            'durationMs': updatedRecording.duration.inMilliseconds,
            'sizeInBytes': updatedRecording.sizeInBytes,
            'savedAt': updatedRecording.savedAt.toIso8601String(),
            'createdAt': Timestamp.fromDate(updatedRecording.savedAt),
            'uploadedAt': Timestamp.fromDate(
              updatedRecording.sharedAt ?? DateTime.now(),
            ),
            'shareUrl': shareUrl,
            'shareableUrl': FieldValue.delete(),
            'shareableLink': FieldValue.delete(),
            'publicShareUrl': FieldValue.delete(),
            'publicShareStoragePath': updatedRecording.publicShareStoragePath,
            'sharedAt': updatedRecording.sharedAt?.toIso8601String(),
          }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw StateError(_describeFirestoreError(error));
    }
  }

  Future<String> _publishExistingPlaybackUrl({
    required SavedVideoRecordingModel recording,
    required String playbackUrl,
  }) async {
    final String shareUrl = UserVideoUploadRepository.buildShareableLink(
      recording.id,
      playbackUrl: playbackUrl,
    );
    final SavedVideoRecordingModel updatedRecording = recording.copyWith(
      publicShareUrl: shareUrl,
      sharedAt: DateTime.now(),
    );
    await persistSavedRecordingMetadata(updatedRecording);
    await _persistSharedMetadata(
      updatedRecording,
      playbackUrl: playbackUrl,
      shareUrl: shareUrl,
    );
    return shareUrl;
  }

  String _resolveStoragePath(SavedVideoRecordingModel recording) {
    final String extension = path.extension(recording.fileName).isEmpty
        ? '.mp4'
        : path.extension(recording.fileName);
    return 'sharedVideos/${recording.id}$extension';
  }

  String _describeStorageError(FirebaseException error) {
    switch (error.code) {
      case 'unauthorized':
        return 'Sharing is not enabled yet. Firebase Storage rules must allow uploads for shared videos.';
      case 'unauthenticated':
        return 'Please sign in before creating a public share link.';
      case 'canceled':
        return 'Sharing was cancelled.';
      default:
        return error.message ??
            'Unable to create a public share link right now.';
    }
  }

  String _describeFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Sharing is blocked by Firestore rules. Allow authenticated writes to sharedVideos/{videoId}.';
      case 'unavailable':
        return 'Sharing is temporarily unavailable. Please try again.';
      default:
        return error.message ?? 'Unable to prepare this video share link.';
    }
  }

  String? _firstNonEmptyString(Map<String, dynamic> data, List<String> fields) {
    for (final String field in fields) {
      final String? value = (data[field] as String?)?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  DateTime? _asDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  bool _isAppShareUrl(String url) {
    return url.contains('/share/videos/') || url.startsWith('aks://share/');
  }
}

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_video_recording_model.dart';
import 'saved_recording_share_upload.dart';
import 'video_recording_storage_support.dart';

class PublicVideoShareRepository {
  PublicVideoShareRepository({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  static final Map<String, Future<String>> _inflightShareUrls =
      <String, Future<String>>{};

  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  Future<String> ensureShareUrl(SavedVideoRecordingModel recording) async {
    if (recording.publicShareUrl case final String existingUrl
        when existingUrl.isNotEmpty) {
      return existingUrl;
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

    final SavedVideoRecordingModel updatedRecording = recording.copyWith(
      publicShareUrl: downloadUrl,
      publicShareStoragePath: storagePath,
      sharedAt: DateTime.now(),
    );
    await _persistSharedRecording(updatedRecording);
    unawaited(_persistSharedMetadata(updatedRecording));
    return downloadUrl;
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
    SavedVideoRecordingModel updatedRecording,
  ) async {
    try {
      await _firestore
          .collection('sharedVideos')
          .doc(updatedRecording.id)
          .set(<String, Object?>{
            'id': updatedRecording.id,
            'fileName': updatedRecording.fileName,
            'mimeType': updatedRecording.mimeType,
            'durationMs': updatedRecording.duration.inMilliseconds,
            'sizeInBytes': updatedRecording.sizeInBytes,
            'savedAt': updatedRecording.savedAt.toIso8601String(),
            'publicShareUrl': updatedRecording.publicShareUrl,
            'publicShareStoragePath': updatedRecording.publicShareStoragePath,
            'sharedAt': updatedRecording.sharedAt?.toIso8601String(),
          }, SetOptions(merge: true));
    } on FirebaseException {
      // The public download URL is enough for sharing. Metadata persistence is optional.
    }
  }

  String _resolveStoragePath(SavedVideoRecordingModel recording) {
    final String extension = path.extension(recording.fileName).isEmpty
        ? '.mp4'
        : path.extension(recording.fileName);
    return 'sharedVideos/${recording.id}$extension';
  }

  Future<void> _persistSharedRecording(
    SavedVideoRecordingModel recording,
  ) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<SavedVideoRecordingModel> manifest =
        decodeSavedRecordingsManifest(
          preferences.getString(savedVideoRecordingsManifestKey),
        );
    final List<SavedVideoRecordingModel> updatedManifest = manifest
        .map((item) => item.id == recording.id ? recording : item)
        .toList(growable: false);
    await preferences.setString(
      savedVideoRecordingsManifestKey,
      encodeSavedRecordingsManifest(updatedManifest),
    );
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
}

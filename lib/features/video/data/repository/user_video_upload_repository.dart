import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import '../enums/video_recording_storage_kind.dart';
import '../models/saved_video_recording_model.dart';
import 'saved_recording_share_upload.dart';

class UserVideoUploadResult {
  const UserVideoUploadResult({
    required this.videoUrl,
    required this.storagePath,
    required this.shareUrl,
    required this.uploadedAt,
  });

  final String videoUrl;
  final String storagePath;
  final String shareUrl;
  final DateTime uploadedAt;
}

class UserVideoUploadRepository {
  UserVideoUploadRepository({
    firebase_auth.FirebaseAuth? auth,
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final firebase_auth.FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  Future<UserVideoUploadResult> uploadRecordingForUser({
    required String userUid,
    required SavedVideoRecordingModel recording,
  }) async {
    await _refreshUploadAuth(userUid);

    final String storagePath = buildUserVideoStoragePath(
      userUid: userUid,
      recording: recording,
    );
    final Reference ref = _storage.ref(storagePath);
    final String videoUrl = await uploadSavedRecordingAndGetDownloadUrl(
      ref,
      recording,
    );
    final DateTime uploadedAt = DateTime.now();
    final String shareUrl = buildShareableLink(
      recording.id,
      playbackUrl: videoUrl,
    );
    final DocumentReference<Map<String, dynamic>> userVideoRef = _firestore
        .collection('users')
        .doc(userUid)
        .collection('videos')
        .doc(recording.id);
    final DocumentReference<Map<String, dynamic>> userProfileRef = _firestore
        .collection('users')
        .doc(userUid);
    final Map<String, Object?> userVideoData = <String, Object?>{
      'url': videoUrl,
      'videoUrl': videoUrl,
      'storagePath': storagePath,
      'createdAt': Timestamp.fromDate(recording.savedAt),
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'shareUrl': shareUrl,
      // Remove legacy duplicate field names when the document is updated.
      'shareableUrl': FieldValue.delete(),
      'shareableLink': FieldValue.delete(),
      'publicShareUrl': FieldValue.delete(),
      'videoId': recording.id,
      'fileName': recording.fileName,
      'mimeType': recording.mimeType,
      'durationMs': recording.duration.inMilliseconds,
      'sizeInBytes': recording.sizeInBytes,
    };

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> userVideoSnapshot =
          await transaction.get(userVideoRef);
      final DocumentSnapshot<Map<String, dynamic>> userProfileSnapshot =
          await transaction.get(userProfileRef);
      final int currentCount =
          _asInt(userProfileSnapshot.data()?['recordedVideosCount']) ?? 0;

      transaction.set(userVideoRef, userVideoData, SetOptions(merge: true));
      if (!userVideoSnapshot.exists) {
        transaction.set(userProfileRef, <String, Object?>{
          'recordedVideosCount': currentCount + 1,
        }, SetOptions(merge: true));
      }
    });
    await _firestore
        .collection('sharedVideos')
        .doc(recording.id)
        .set(<String, Object?>{
          'id': recording.id,
          'videoId': recording.id,
          'ownerUid': userUid,
          'fileName': recording.fileName,
          'url': videoUrl,
          'videoUrl': videoUrl,
          'storagePath': storagePath,
          'createdAt': Timestamp.fromDate(recording.savedAt),
          'uploadedAt': Timestamp.fromDate(uploadedAt),
          'shareUrl': shareUrl,
          'shareableUrl': FieldValue.delete(),
          'shareableLink': FieldValue.delete(),
          'publicShareUrl': FieldValue.delete(),
          'mimeType': recording.mimeType,
          'durationMs': recording.duration.inMilliseconds,
          'sizeInBytes': recording.sizeInBytes,
        }, SetOptions(merge: true));

    return UserVideoUploadResult(
      videoUrl: videoUrl,
      storagePath: storagePath,
      shareUrl: shareUrl,
      uploadedAt: uploadedAt,
    );
  }

  Future<List<SavedVideoRecordingModel>> loadRecordingsForUser({
    required String userUid,
  }) async {
    _requireMatchingUser(userUid, actionLabel: 'loading recordings');

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .doc(userUid)
        .collection('videos')
        .get();

    final List<SavedVideoRecordingModel> recordings = snapshot.docs
        .map(_recordingFromUserVideoDocument)
        .whereType<SavedVideoRecordingModel>()
        .toList(growable: false);
    recordings.sort(
      (SavedVideoRecordingModel a, SavedVideoRecordingModel b) =>
          b.savedAt.compareTo(a.savedAt),
    );
    return recordings;
  }

  Stream<List<SavedVideoRecordingModel>> watchRecordingsForUser({
    required String userUid,
  }) {
    _requireMatchingUser(userUid, actionLabel: 'watching recordings');

    return _firestore
        .collection('users')
        .doc(userUid)
        .collection('videos')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<SavedVideoRecordingModel> recordings = snapshot.docs
              .map(_recordingFromUserVideoDocument)
              .whereType<SavedVideoRecordingModel>()
              .toList(growable: false);
          recordings.sort(
            (SavedVideoRecordingModel a, SavedVideoRecordingModel b) =>
                b.savedAt.compareTo(a.savedAt),
          );
          return recordings;
        });
  }

  Future<void> deleteRecordingForUser({
    required String userUid,
    required SavedVideoRecordingModel recording,
  }) async {
    _requireMatchingUser(userUid, actionLabel: 'deleting recordings');

    final String? remoteStoragePath =
        (recording.publicShareStoragePath?.trim().isNotEmpty ?? false)
        ? recording.publicShareStoragePath!.trim()
        : recording.storageKind == VideoRecordingStorageKind.firebaseStorage
        ? recording.storagePath
        : null;

    final DocumentReference<Map<String, dynamic>> userVideoRef = _firestore
        .collection('users')
        .doc(userUid)
        .collection('videos')
        .doc(recording.id);
    final DocumentReference<Map<String, dynamic>> userProfileRef = _firestore
        .collection('users')
        .doc(userUid);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> userVideoSnapshot =
          await transaction.get(userVideoRef);
      if (!userVideoSnapshot.exists) {
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> userProfileSnapshot =
          await transaction.get(userProfileRef);
      final int currentCount =
          _asInt(userProfileSnapshot.data()?['recordedVideosCount']) ?? 0;

      transaction.delete(userVideoRef);
      transaction.set(userProfileRef, <String, Object?>{
        'recordedVideosCount': currentCount > 0 ? currentCount - 1 : 0,
      }, SetOptions(merge: true));
    });
    await _firestore.collection('sharedVideos').doc(recording.id).delete();

    if (remoteStoragePath == null || remoteStoragePath.isEmpty) {
      return;
    }

    try {
      await _storage.ref(remoteStoragePath).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        rethrow;
      }
    }
  }

  Future<void> syncRecordedVideosCountForUser({
    required String userUid,
    required int count,
  }) async {
    _requireMatchingUser(userUid, actionLabel: 'syncing recordings usage');
    await _firestore.collection('users').doc(userUid).set(<String, Object?>{
      'recordedVideosCount': count < 0 ? 0 : count,
    }, SetOptions(merge: true));
  }

  Future<void> updateRecordingTitleForUser({
    required String userUid,
    required String recordingId,
    required String title,
  }) async {
    _requireMatchingUser(userUid, actionLabel: 'renaming recordings');

    final String trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw StateError('Recording name cannot be empty.');
    }

    final Map<String, Object?> data = <String, Object?>{'title': trimmedTitle};

    await _firestore
        .collection('users')
        .doc(userUid)
        .collection('videos')
        .doc(recordingId)
        .set(data, SetOptions(merge: true));
    await _firestore
        .collection('sharedVideos')
        .doc(recordingId)
        .set(data, SetOptions(merge: true));
  }

  Future<void> _refreshUploadAuth(String userUid) async {
    final firebase_auth.User user = _requireMatchingUser(
      userUid,
      actionLabel: 'uploading recordings',
    );
    await user.getIdToken(true);
  }

  firebase_auth.User _requireMatchingUser(
    String userUid, {
    required String actionLabel,
  }) {
    final firebase_auth.User? user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in before $actionLabel.');
    }
    if (user.uid != userUid) {
      throw StateError('The active account does not match these recordings.');
    }
    return user;
  }

  static String buildUserVideoStoragePath({
    required String userUid,
    required SavedVideoRecordingModel recording,
  }) {
    final String extension = path.extension(recording.fileName).isEmpty
        ? '.mp4'
        : path.extension(recording.fileName);
    return 'users/$userUid/videos/${recording.id}$extension';
  }

  static String buildShareableLink(String videoId, {String? playbackUrl}) {
    final Uri baseUri = Uri.base;
    final Map<String, String>? queryParameters =
        playbackUrl != null && playbackUrl.trim().isNotEmpty
        ? <String, String>{'source': playbackUrl.trim()}
        : null;
    if ((baseUri.scheme == 'https' || baseUri.scheme == 'http') &&
        baseUri.host.isNotEmpty) {
      return Uri(
        scheme: baseUri.scheme,
        userInfo: baseUri.userInfo,
        host: baseUri.host,
        port: baseUri.hasPort ? baseUri.port : null,
        pathSegments: <String>['share', 'videos', videoId],
        queryParameters: queryParameters,
      ).toString();
    }
    return Uri(
      scheme: 'aks',
      host: 'share',
      pathSegments: <String>['videos', videoId],
      queryParameters: queryParameters,
    ).toString();
  }

  static SavedVideoRecordingModel? _recordingFromUserVideoDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();
    final String id = (data['videoId'] as String?)?.trim().isNotEmpty == true
        ? data['videoId'] as String
        : document.id;
    final String? videoUrl = _firstNonEmptyString(data, <String>[
      'videoUrl',
      'url',
      'downloadUrl',
    ]);
    if (videoUrl == null) {
      return null;
    }

    final DateTime createdAt =
        _asDateTime(data['createdAt']) ??
        _asDateTime(data['uploadedAt']) ??
        DateTime.now();
    final int durationMs = data['durationMs'] is int
        ? data['durationMs'] as int
        : 0;
    final int sizeInBytes = data['sizeInBytes'] is int
        ? data['sizeInBytes'] as int
        : 0;

    return SavedVideoRecordingModel(
      id: id,
      fileName: _firstNonEmptyString(data, <String>['fileName']) ?? '$id.webm',
      title: _firstNonEmptyString(data, <String>['title']),
      savedAt: createdAt,
      duration: Duration(milliseconds: durationMs),
      storageKind: VideoRecordingStorageKind.firebaseStorage,
      storagePath:
          _firstNonEmptyString(data, <String>['storagePath']) ?? videoUrl,
      playbackPath: videoUrl,
      mimeType:
          _firstNonEmptyString(data, <String>['mimeType']) ?? 'video/webm',
      sizeInBytes: sizeInBytes,
      publicShareUrl: _firstNonEmptyString(data, <String>[
        'shareUrl',
        'publicShareUrl',
        'shareableUrl',
        'shareableLink',
      ]),
      publicShareStoragePath: _firstNonEmptyString(data, <String>[
        'storagePath',
      ]),
      sharedAt: _asDateTime(data['uploadedAt']),
    );
  }

  static String? _firstNonEmptyString(
    Map<String, dynamic> data,
    List<String> fields,
  ) {
    for (final String field in fields) {
      final String? value = (data[field] as String?)?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static DateTime? _asDateTime(Object? value) {
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

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

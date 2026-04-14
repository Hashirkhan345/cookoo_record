import 'package:flutter/foundation.dart';

import '../enums/video_recording_storage_kind.dart';

@immutable
class SavedVideoRecordingModel {
  const SavedVideoRecordingModel({
    required this.id,
    required this.fileName,
    required this.savedAt,
    required this.duration,
    required this.storageKind,
    required this.storagePath,
    required this.playbackPath,
    required this.mimeType,
    required this.sizeInBytes,
    this.publicShareUrl,
    this.publicShareStoragePath,
    this.sharedAt,
  });

  final String id;
  final String fileName;
  final DateTime savedAt;
  final Duration duration;
  final VideoRecordingStorageKind storageKind;
  final String storagePath;
  final String playbackPath;
  final String mimeType;
  final int sizeInBytes;
  final String? publicShareUrl;
  final String? publicShareStoragePath;
  final DateTime? sharedAt;

  String get storageSummary {
    switch (storageKind) {
      case VideoRecordingStorageKind.localFile:
        return storagePath;
      case VideoRecordingStorageKind.browserLocalStorage:
        return 'Browser local storage';
      case VideoRecordingStorageKind.browserIndexedDb:
        return 'Browser IndexedDB';
    }
  }

  SavedVideoRecordingModel copyWith({
    VideoRecordingStorageKind? storageKind,
    String? storagePath,
    String? playbackPath,
    int? sizeInBytes,
    String? publicShareUrl,
    String? publicShareStoragePath,
    DateTime? sharedAt,
  }) {
    return SavedVideoRecordingModel(
      id: id,
      fileName: fileName,
      savedAt: savedAt,
      duration: duration,
      storageKind: storageKind ?? this.storageKind,
      storagePath: storagePath ?? this.storagePath,
      playbackPath: playbackPath ?? this.playbackPath,
      mimeType: mimeType,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      publicShareUrl: publicShareUrl ?? this.publicShareUrl,
      publicShareStoragePath:
          publicShareStoragePath ?? this.publicShareStoragePath,
      sharedAt: sharedAt ?? this.sharedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'fileName': fileName,
      'savedAt': savedAt.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'storageKind': storageKind.name,
      'storagePath': storagePath,
      'mimeType': mimeType,
      'sizeInBytes': sizeInBytes,
      'publicShareUrl': publicShareUrl,
      'publicShareStoragePath': publicShareStoragePath,
      'sharedAt': sharedAt?.toIso8601String(),
    };
  }

  factory SavedVideoRecordingModel.fromJson(Map<String, dynamic> json) {
    return SavedVideoRecordingModel(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      duration: Duration(milliseconds: json['durationMs'] as int),
      storageKind: VideoRecordingStorageKind.values.byName(
        json['storageKind'] as String,
      ),
      storagePath: json['storagePath'] as String,
      playbackPath: json['storagePath'] as String,
      mimeType: json['mimeType'] as String? ?? 'video/mp4',
      sizeInBytes: json['sizeInBytes'] as int? ?? 0,
      publicShareUrl: json['publicShareUrl'] as String?,
      publicShareStoragePath: json['publicShareStoragePath'] as String?,
      sharedAt: (json['sharedAt'] as String?) != null
          ? DateTime.tryParse(json['sharedAt'] as String)
          : null,
    );
  }
}

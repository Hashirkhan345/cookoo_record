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
    );
  }
}

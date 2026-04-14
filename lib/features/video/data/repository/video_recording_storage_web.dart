import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../enums/video_recording_storage_kind.dart';
import '../models/saved_video_recording_model.dart';
import 'video_recording_indexed_db_web.dart';
import 'video_recording_storage_contract.dart';
import 'video_recording_storage_support.dart';

VideoRecordingStorage createVideoRecordingStorage() {
  return const WebVideoRecordingStorage();
}

class WebVideoRecordingStorage implements VideoRecordingStorage {
  const WebVideoRecordingStorage({
    VideoRecordingIndexedDbStore indexedDbStore =
        const VideoRecordingIndexedDbStore(),
  }) : _indexedDbStore = indexedDbStore;

  final VideoRecordingIndexedDbStore _indexedDbStore;

  @override
  Future<String> getStorageLocationLabel() async {
    return _indexedDbStore.isSupported
        ? 'Browser IndexedDB'
        : 'Browser local storage';
  }

  @override
  Future<List<SavedVideoRecordingModel>> loadSavedRecordings() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<SavedVideoRecordingModel> manifest = await _loadManifestSafely(
      preferences,
    );
    final List<SavedVideoRecordingModel> recordings =
        <SavedVideoRecordingModel>[];
    bool didPruneManifest = false;

    for (final SavedVideoRecordingModel recording in manifest) {
      Uint8List? bytes;
      try {
        bytes = await _loadRecordingBytes(preferences, recording);
      } catch (_) {
        bytes = null;
      }
      if (bytes == null || bytes.isEmpty) {
        try {
          await _removeRecordingBytes(preferences, recording);
        } catch (_) {
          // Ignore cleanup failures and keep pruning the manifest entry.
        }
        didPruneManifest = true;
        continue;
      }

      final XFile playbackFile = XFile.fromData(
        bytes,
        mimeType: recording.mimeType,
        name: recording.fileName,
        length: bytes.length,
        lastModified: recording.savedAt,
      );

      recordings.add(
        recording.copyWith(
          playbackPath: playbackFile.path,
          sizeInBytes: bytes.length,
        ),
      );
    }

    if (didPruneManifest) {
      await preferences.setString(
        savedVideoRecordingsManifestKey,
        encodeSavedRecordingsManifest(recordings),
      );
    }

    return recordings;
  }

  @override
  Future<int> loadLifetimeRecordingCount() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getInt(lifetimeRecordedVideosCountKey) ?? 0;
  }

  @override
  Future<SavedVideoRecordingModel> saveRecording(
    XFile recordedVideo, {
    required Duration duration,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<SavedVideoRecordingModel> manifest = await loadSavedRecordings();
    final DateTime savedAt = DateTime.now();
    final String id = buildSavedRecordingId(savedAt);
    final String mimeType = resolveRecordingMimeType(
      recordedVideo,
      defaultMimeType: 'video/webm',
    );
    final String extension = resolveRecordingExtension(
      recordedVideo,
      mimeType: mimeType,
      defaultExtension: '.webm',
    );
    final Uint8List bytes = await recordedVideo.readAsBytes();
    final String fileName = '$id$extension';
    final String storageKey = buildSavedRecordingDataKey(id);
    final bool storeInIndexedDb = _indexedDbStore.isSupported;

    try {
      if (storeInIndexedDb) {
        await _indexedDbStore.saveBytes(storageKey, bytes);
      } else {
        final bool didStoreBytes = await preferences.setString(
          storageKey,
          base64Encode(bytes),
        );
        if (!didStoreBytes) {
          throw StateError(
            'The recording could not be written to browser storage.',
          );
        }
      }
    } catch (_) {
      throw StateError(
        storeInIndexedDb
            ? 'The recording could not be written to browser IndexedDB.'
            : 'The recording is too large to store in this browser. Try a shorter clip.',
      );
    }

    final XFile playbackFile = XFile.fromData(
      bytes,
      mimeType: mimeType,
      name: fileName,
      length: bytes.length,
      lastModified: savedAt,
    );

    final SavedVideoRecordingModel savedRecording = SavedVideoRecordingModel(
      id: id,
      fileName: fileName,
      savedAt: savedAt,
      duration: duration,
      storageKind: storeInIndexedDb
          ? VideoRecordingStorageKind.browserIndexedDb
          : VideoRecordingStorageKind.browserLocalStorage,
      storagePath: storageKey,
      playbackPath: playbackFile.path,
      mimeType: mimeType,
      sizeInBytes: bytes.length,
    );

    await preferences.setString(
      savedVideoRecordingsManifestKey,
      encodeSavedRecordingsManifest(<SavedVideoRecordingModel>[
        savedRecording,
        ...manifest,
      ]),
    );
    await preferences.setInt(
      lifetimeRecordedVideosCountKey,
      (preferences.getInt(lifetimeRecordedVideosCountKey) ?? 0) + 1,
    );

    return savedRecording;
  }

  @override
  Future<void> deleteSavedRecording(SavedVideoRecordingModel recording) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<SavedVideoRecordingModel> manifest = await loadSavedRecordings();

    await _removeRecordingBytes(preferences, recording);
    await preferences.setString(
      savedVideoRecordingsManifestKey,
      encodeSavedRecordingsManifest(
        manifest
            .where((SavedVideoRecordingModel item) => item.id != recording.id)
            .toList(),
      ),
    );
  }

  @override
  Future<void> clearSavedRecordings() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<SavedVideoRecordingModel> manifest = await _loadManifestSafely(
      preferences,
    );

    for (final SavedVideoRecordingModel recording in manifest) {
      try {
        await _removeRecordingBytes(preferences, recording);
      } catch (_) {
        // Continue clearing remaining recordings even if one entry fails.
      }
    }

    await preferences.remove(savedVideoRecordingsManifestKey);
  }

  Future<List<SavedVideoRecordingModel>> _loadManifestSafely(
    SharedPreferences preferences,
  ) async {
    final String? rawManifest = preferences.getString(
      savedVideoRecordingsManifestKey,
    );
    if (rawManifest == null || rawManifest.isEmpty) {
      return const <SavedVideoRecordingModel>[];
    }

    try {
      return decodeSavedRecordingsManifest(rawManifest);
    } catch (_) {
      await preferences.remove(savedVideoRecordingsManifestKey);
      return const <SavedVideoRecordingModel>[];
    }
  }

  Future<Uint8List?> _loadRecordingBytes(
    SharedPreferences preferences,
    SavedVideoRecordingModel recording,
  ) async {
    switch (recording.storageKind) {
      case VideoRecordingStorageKind.browserIndexedDb:
        return _indexedDbStore.loadBytes(recording.storagePath);
      case VideoRecordingStorageKind.browserLocalStorage:
        final String? encodedBytes = preferences.getString(
          recording.storagePath,
        );
        if (encodedBytes == null || encodedBytes.isEmpty) {
          return null;
        }

        try {
          return base64Decode(encodedBytes);
        } catch (_) {
          return null;
        }
      case VideoRecordingStorageKind.localFile:
        return null;
    }
  }

  Future<void> _removeRecordingBytes(
    SharedPreferences preferences,
    SavedVideoRecordingModel recording,
  ) async {
    switch (recording.storageKind) {
      case VideoRecordingStorageKind.browserIndexedDb:
        await _indexedDbStore.deleteBytes(recording.storagePath);
        return;
      case VideoRecordingStorageKind.browserLocalStorage:
        await preferences.remove(recording.storagePath);
        return;
      case VideoRecordingStorageKind.localFile:
        return;
    }
  }
}

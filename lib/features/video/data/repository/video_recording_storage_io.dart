import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../enums/video_recording_storage_kind.dart';
import '../models/saved_video_recording_model.dart';
import 'video_file_disposer.dart';
import 'video_recording_storage_contract.dart';
import 'video_recording_storage_support.dart';

const String _recordingsFolderName = 'video_recordings';

VideoRecordingStorage createVideoRecordingStorage() {
  return const IoVideoRecordingStorage();
}

class IoVideoRecordingStorage implements VideoRecordingStorage {
  const IoVideoRecordingStorage();

  @override
  Future<String> getStorageLocationLabel() async {
    final Directory directory = await _ensureRecordingsDirectory();
    return directory.path;
  }

  @override
  Future<List<SavedVideoRecordingModel>> loadSavedRecordings() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<SavedVideoRecordingModel> manifest =
        decodeSavedRecordingsManifest(
          preferences.getString(savedVideoRecordingsManifestKey),
        );

    final List<SavedVideoRecordingModel> existingRecordings =
        <SavedVideoRecordingModel>[];
    bool didPruneManifest = false;

    for (final SavedVideoRecordingModel recording in manifest) {
      final File recordingFile = File(recording.storagePath);
      if (await recordingFile.exists()) {
        existingRecordings.add(
          recording.copyWith(playbackPath: recording.storagePath),
        );
      } else {
        didPruneManifest = true;
      }
    }

    if (didPruneManifest) {
      await preferences.setString(
        savedVideoRecordingsManifestKey,
        encodeSavedRecordingsManifest(existingRecordings),
      );
    }

    return existingRecordings;
  }

  @override
  Future<SavedVideoRecordingModel> saveRecording(
    XFile recordedVideo, {
    required Duration duration,
  }) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<SavedVideoRecordingModel> manifest = await loadSavedRecordings();
    final Directory directory = await _ensureRecordingsDirectory();
    final DateTime savedAt = DateTime.now();
    final String id = buildSavedRecordingId(savedAt);
    final String mimeType = resolveRecordingMimeType(
      recordedVideo,
      defaultMimeType: 'video/mp4',
    );
    final String extension = resolveRecordingExtension(
      recordedVideo,
      mimeType: mimeType,
      defaultExtension: '.mp4',
    );
    final String fileName = '$id$extension';
    final String filePath = path.join(directory.path, fileName);
    final List<int> bytes = await recordedVideo.readAsBytes();

    await File(filePath).writeAsBytes(bytes, flush: true);

    if (recordedVideo.path.isNotEmpty && recordedVideo.path != filePath) {
      await deleteRecordedFile(recordedVideo.path);
    }

    final SavedVideoRecordingModel savedRecording = SavedVideoRecordingModel(
      id: id,
      fileName: fileName,
      savedAt: savedAt,
      duration: duration,
      storageKind: VideoRecordingStorageKind.localFile,
      storagePath: filePath,
      playbackPath: filePath,
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

    return savedRecording;
  }

  @override
  Future<void> deleteSavedRecording(SavedVideoRecordingModel recording) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<SavedVideoRecordingModel> manifest = await loadSavedRecordings();
    final File recordingFile = File(recording.storagePath);
    if (await recordingFile.exists()) {
      await recordingFile.delete();
    }

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
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final Directory recordingsDirectory = Directory(
      path.join(documentsDirectory.path, _recordingsFolderName),
    );

    if (await recordingsDirectory.exists()) {
      await recordingsDirectory.delete(recursive: true);
    }

    await preferences.remove(savedVideoRecordingsManifestKey);
  }

  Future<Directory> _ensureRecordingsDirectory() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final Directory recordingsDirectory = Directory(
      path.join(documentsDirectory.path, _recordingsFolderName),
    );

    if (!await recordingsDirectory.exists()) {
      await recordingsDirectory.create(recursive: true);
    }

    return recordingsDirectory;
  }
}

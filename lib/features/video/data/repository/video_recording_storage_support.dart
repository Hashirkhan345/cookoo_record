import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/admin_config_model.dart';
import '../models/saved_video_recording_model.dart';

const String savedVideoRecordingsManifestKey =
    'video_saved_recordings_manifest';
const String savedVideoRecordingDataPrefix = 'video_saved_recording_data_';
const String lifetimeRecordedVideosCountKey =
    'video_lifetime_recorded_videos_count';
const int lifetimeRecordedVideosRestrictionLimit =
    AdminConfigModel.defaultFreeVideoLimit;

String buildSavedRecordingId(DateTime timestamp) {
  return 'recording_${timestamp.microsecondsSinceEpoch}';
}

String buildSavedRecordingDataKey(String recordingId) {
  return '$savedVideoRecordingDataPrefix$recordingId';
}

String resolveRecordingMimeType(
  XFile recordedVideo, {
  required String defaultMimeType,
}) {
  final String? mimeType = recordedVideo.mimeType;
  if (mimeType != null && mimeType.isNotEmpty) {
    return mimeType;
  }

  final String path = recordedVideo.path.toLowerCase();
  if (path.endsWith('.webm')) {
    return 'video/webm';
  }
  if (path.endsWith('.mov')) {
    return 'video/quicktime';
  }
  if (path.endsWith('.m4v')) {
    return 'video/x-m4v';
  }

  return defaultMimeType;
}

String resolveRecordingExtension(
  XFile recordedVideo, {
  required String mimeType,
  required String defaultExtension,
}) {
  final String path = recordedVideo.path;
  final int dotIndex = path.lastIndexOf('.');
  if (dotIndex != -1 && dotIndex < path.length - 1) {
    return path.substring(dotIndex);
  }

  switch (mimeType) {
    case 'video/webm':
      return '.webm';
    case 'video/quicktime':
      return '.mov';
    case 'video/x-m4v':
      return '.m4v';
    case 'video/mp4':
      return '.mp4';
    default:
      return defaultExtension;
  }
}

List<SavedVideoRecordingModel> decodeSavedRecordingsManifest(String? rawJson) {
  if (rawJson == null || rawJson.isEmpty) {
    return const <SavedVideoRecordingModel>[];
  }

  final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
  final List<SavedVideoRecordingModel> recordings = decoded
      .map(
        (dynamic item) => SavedVideoRecordingModel.fromJson(
          Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
        ),
      )
      .toList();

  recordings.sort(
    (SavedVideoRecordingModel a, SavedVideoRecordingModel b) =>
        b.savedAt.compareTo(a.savedAt),
  );
  return recordings;
}

String encodeSavedRecordingsManifest(
  List<SavedVideoRecordingModel> recordings,
) {
  return jsonEncode(
    recordings.map((SavedVideoRecordingModel recording) {
      return recording.toJson();
    }).toList(),
  );
}

Future<void> persistSavedRecordingMetadata(
  SavedVideoRecordingModel recording,
) async {
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final List<SavedVideoRecordingModel> manifest = decodeSavedRecordingsManifest(
    preferences.getString(savedVideoRecordingsManifestKey),
  );
  bool didUpdate = false;
  final List<SavedVideoRecordingModel> updatedManifest = manifest
      .map((SavedVideoRecordingModel item) {
        if (item.id != recording.id) {
          return item;
        }
        didUpdate = true;
        return recording;
      })
      .toList(growable: false);

  if (!didUpdate) {
    return;
  }

  await preferences.setString(
    savedVideoRecordingsManifestKey,
    encodeSavedRecordingsManifest(updatedManifest),
  );
}

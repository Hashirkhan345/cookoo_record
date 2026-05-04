import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/enums/video_recording_storage_kind.dart';
import '../../data/models/saved_video_recording_model.dart';
import '../controller/video_feature_theme.dart';
import '../widgets/saved_recording_player.dart';

class SharedVideoScreen extends StatelessWidget {
  const SharedVideoScreen({super.key, required this.videoId, this.sourceUrl});

  final String videoId;
  final String? sourceUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: VideoFeatureTheme.screenBackgroundFor(context),
        ),
        child: SafeArea(
          child: FutureBuilder<_SharedVideoData>(
            future: _loadSharedVideo(videoId, sourceUrl: sourceUrl),
            builder: (BuildContext context, AsyncSnapshot<_SharedVideoData> snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return _SharedVideoMessage(
                  icon: Icons.link_off_rounded,
                  title: 'Video link unavailable',
                  message:
                      'This shared video could not be found or is no longer available.',
                );
              }

              final _SharedVideoData sharedVideo = snapshot.data!;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: VideoFeatureTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.play_circle_outline_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Shared recording',
                                    style: TextStyle(
                                      color: VideoFeatureTheme.mutedFor(
                                        context,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    sharedVideo.recording.title
                                                ?.trim()
                                                .isNotEmpty ==
                                            true
                                        ? sharedVideo.recording.title!
                                        : sharedVideo.recording.fileName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: VideoFeatureTheme.inkFor(context),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      _SharedVideoMetaChip(
                                        icon: Icons.calendar_today_rounded,
                                        label:
                                            'Uploaded ${_formatDate(sharedVideo.uploadedAt)}',
                                      ),
                                      if (sharedVideo
                                              .recording
                                              .duration
                                              .inMilliseconds >
                                          0)
                                        _SharedVideoMetaChip(
                                          icon: Icons.schedule_rounded,
                                          label: _formatDuration(
                                            sharedVideo.recording.duration,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: VideoFeatureTheme.panelFor(context),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: VideoFeatureTheme.lineFor(context),
                            ),
                            boxShadow: VideoFeatureTheme.panelShadow,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: SavedRecordingPlayer(
                              recording: sharedVideo.recording,
                              autoplayMuted: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<_SharedVideoData> _loadSharedVideo(
    String videoId, {
    String? sourceUrl,
  }) async {
    Map<String, dynamic>? data;
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('sharedVideos')
              .doc(videoId)
              .get();
      data = snapshot.data();
    } on FirebaseException {
      data = null;
    }

    final String? playbackUrl =
        _firstValidPlaybackUrl(data) ?? _cleanSourceUrl(sourceUrl);
    if (playbackUrl == null) {
      throw StateError('Shared video playback URL is missing.');
    }

    final String fileName = data == null
        ? '$videoId.mp4'
        : _firstNonEmptyString(data, <String>['fileName']) ?? '$videoId.mp4';
    final DateTime createdAt = data == null
        ? DateTime.now()
        : _asDateTime(data['createdAt']) ??
              _asDateTime(data['savedAt']) ??
              DateTime.now();
    final DateTime uploadedAt = data == null
        ? createdAt
        : _asDateTime(data['uploadedAt']) ??
              _asDateTime(data['sharedAt']) ??
              createdAt;
    final int durationMs = data != null && data['durationMs'] is int
        ? data['durationMs'] as int
        : 0;
    final int sizeInBytes = data != null && data['sizeInBytes'] is int
        ? data['sizeInBytes'] as int
        : 0;

    return _SharedVideoData(
      uploadedAt: uploadedAt,
      recording: SavedVideoRecordingModel(
        id: videoId,
        fileName: fileName,
        title: data == null
            ? null
            : _firstNonEmptyString(data, <String>['title']),
        savedAt: createdAt,
        duration: Duration(milliseconds: durationMs),
        storageKind: VideoRecordingStorageKind.browserIndexedDb,
        storagePath: playbackUrl,
        playbackPath: playbackUrl,
        mimeType: data == null
            ? 'video/mp4'
            : _firstNonEmptyString(data, <String>['mimeType']) ?? 'video/mp4',
        sizeInBytes: sizeInBytes,
        publicShareUrl: data == null
            ? null
            : _firstNonEmptyString(data, <String>[
                'shareUrl',
                'publicShareUrl',
                'shareableUrl',
                'shareableLink',
              ]),
      ),
    );
  }

  String? _firstValidPlaybackUrl(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    final String? playbackUrl = _firstNonEmptyString(data, <String>[
      'videoUrl',
      'url',
      'downloadUrl',
      'publicShareUrl',
    ]);
    return _cleanSourceUrl(playbackUrl);
  }

  String? _cleanSourceUrl(String? sourceUrl) {
    final String? value = sourceUrl?.trim();
    if (value == null || value.isEmpty || value.contains('/share/videos/')) {
      return null;
    }
    final Uri? uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      return null;
    }
    return value;
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

  String _formatDate(DateTime value) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds.remainder(60);
    if (minutes <= 0) {
      return '${seconds}s';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _SharedVideoData {
  const _SharedVideoData({required this.recording, required this.uploadedAt});

  final SavedVideoRecordingModel recording;
  final DateTime uploadedAt;
}

class _SharedVideoMetaChip extends StatelessWidget {
  const _SharedVideoMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: VideoFeatureTheme.panelMutedFor(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VideoFeatureTheme.lineFor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: VideoFeatureTheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: VideoFeatureTheme.mutedFor(context),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedVideoMessage extends StatelessWidget {
  const _SharedVideoMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: VideoFeatureTheme.panelFor(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: VideoFeatureTheme.lineFor(context)),
            boxShadow: VideoFeatureTheme.panelShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: VideoFeatureTheme.primary, size: 38),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: VideoFeatureTheme.inkFor(context),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: VideoFeatureTheme.mutedFor(context),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

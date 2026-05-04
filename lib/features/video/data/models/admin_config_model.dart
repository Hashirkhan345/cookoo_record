import 'package:flutter/foundation.dart';

import '../enums/video_recording_storage_kind.dart';
import 'saved_video_recording_model.dart';

@immutable
class AdminConfigModel {
  const AdminConfigModel({
    required this.title,
    required this.subtitle,
    required this.primaryActionLabel,
    required this.secondaryActionLabel,
    required this.featurePoints,
    required this.freeVideoLimit,
    this.demoVideoUrl,
    this.demoVideoUrlWeb,
    this.demoVideoUrlMobile,
    this.demoVideoTitle,
    this.demoVideoSubtitle,
  });

  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final String secondaryActionLabel;
  final List<String> featurePoints;
  final int freeVideoLimit;
  final String? demoVideoUrl;
  final String? demoVideoUrlWeb;
  final String? demoVideoUrlMobile;
  final String? demoVideoTitle;
  final String? demoVideoSubtitle;

  String? get resolvedDemoVideoUrl {
    final String? trimmedWebUrl = _cleanUrl(demoVideoUrlWeb);
    final String? trimmedMobileUrl = _cleanUrl(demoVideoUrlMobile);
    final String? trimmedDefaultUrl = _cleanUrl(demoVideoUrl);

    if (kIsWeb && trimmedWebUrl != null) {
      return trimmedWebUrl;
    }

    if (!kIsWeb && trimmedMobileUrl != null) {
      return trimmedMobileUrl;
    }

    if (!kIsWeb) {
      if (trimmedDefaultUrl != null &&
          !_isClearlyWebmVideo(trimmedDefaultUrl)) {
        return trimmedDefaultUrl;
      }

      return null;
    }

    if (trimmedDefaultUrl != null) {
      return trimmedDefaultUrl;
    }

    return null;
  }

  bool get hasDemoVideo => resolvedDemoVideoUrl != null;

  SavedVideoRecordingModel toDemoRecording() {
    final String playbackUrl = resolvedDemoVideoUrl ?? '';
    final String extension = _fileExtension(playbackUrl);

    return SavedVideoRecordingModel(
      id: 'admin-demo-video',
      fileName: demoVideoTitle?.trim().isNotEmpty == true
          ? '${demoVideoTitle!.trim()}$extension'
          : 'Aks-demo-video$extension',
      savedAt: DateTime.fromMillisecondsSinceEpoch(0),
      duration: Duration.zero,
      storageKind: VideoRecordingStorageKind.localFile,
      storagePath: playbackUrl,
      playbackPath: playbackUrl,
      mimeType: _mimeTypeForUrl(playbackUrl),
      sizeInBytes: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'subtitle': subtitle,
      'primaryActionLabel': primaryActionLabel,
      'secondaryActionLabel': secondaryActionLabel,
      'featurePoints': featurePoints,
      'freeVideoLimit': freeVideoLimit,
      'demoVideoUrl': demoVideoUrl,
      'demoVideoUrlWeb': demoVideoUrlWeb,
      'demoVideoUrlMobile': demoVideoUrlMobile,
      'demoVideoTitle': demoVideoTitle,
      'demoVideoSubtitle': demoVideoSubtitle,
    };
  }

  factory AdminConfigModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPoints =
        json['featurePoints'] as List<dynamic>? ?? const <dynamic>[];

    return AdminConfigModel(
      title: _readFirstNonEmptyString(json, const <String>['title']) != null
          ? _readFirstNonEmptyString(json, const <String>['title'])!
          : defaults.title,
      subtitle:
          _readFirstNonEmptyString(json, const <String>['subtitle']) != null
          ? _readFirstNonEmptyString(json, const <String>['subtitle'])!
          : defaults.subtitle,
      primaryActionLabel:
          _readFirstNonEmptyString(json, const <String>[
                'primaryActionLabel',
              ]) !=
              null
          ? _readFirstNonEmptyString(json, const <String>[
              'primaryActionLabel',
            ])!
          : defaults.primaryActionLabel,
      secondaryActionLabel:
          _readFirstNonEmptyString(json, const <String>[
                'secondaryActionLabel',
              ]) !=
              null
          ? _readFirstNonEmptyString(json, const <String>[
              'secondaryActionLabel',
            ])!
          : defaults.secondaryActionLabel,
      freeVideoLimit:
          _readFirstPositiveInt(json, const <String>[
            'freeVideoLimit',
            'free_video_limit',
          ]) ??
          defaults.freeVideoLimit,
      featurePoints: rawPoints
          .whereType<String>()
          .map((String value) => value.trim())
          .where((String value) => value.isNotEmpty)
          .toList(growable: false),
      demoVideoUrl: _readFirstNonEmptyString(json, const <String>[
        'demoVideoUrl',
        'videoUrl',
        'demo_url',
      ]),
      demoVideoUrlWeb: _readFirstNonEmptyString(json, const <String>[
        'demoVideoUrlWeb',
        'demoVideoWebUrl',
        'webDemoVideoUrl',
        'demoVideoWebmUrl',
        'demoWebmUrl',
        'webVideoUrl',
      ]),
      demoVideoUrlMobile: _readFirstNonEmptyString(json, const <String>[
        'demoVideoUrlMobile',
        'demoVideoMobileUrl',
        'mobileDemoVideoUrl',
        'demoVideoMp4Url',
        'demoMp4Url',
        'mobileVideoUrl',
      ]),
      demoVideoTitle: _readFirstNonEmptyString(json, const <String>[
        'demoVideoTitle',
        'videoTitle',
      ]),
      demoVideoSubtitle: _readFirstNonEmptyString(json, const <String>[
        'demoVideoSubtitle',
        'videoSubtitle',
      ]),
    )._withDefaultFeaturePoints();
  }

  AdminConfigModel _withDefaultFeaturePoints() {
    if (featurePoints.isNotEmpty) {
      return this;
    }

    return copyWith(featurePoints: defaults.featurePoints);
  }

  AdminConfigModel copyWith({
    String? title,
    String? subtitle,
    String? primaryActionLabel,
    String? secondaryActionLabel,
    List<String>? featurePoints,
    int? freeVideoLimit,
    String? demoVideoUrl,
    String? demoVideoUrlWeb,
    String? demoVideoUrlMobile,
    String? demoVideoTitle,
    String? demoVideoSubtitle,
  }) {
    return AdminConfigModel(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      primaryActionLabel: primaryActionLabel ?? this.primaryActionLabel,
      secondaryActionLabel: secondaryActionLabel ?? this.secondaryActionLabel,
      featurePoints: featurePoints ?? this.featurePoints,
      freeVideoLimit: freeVideoLimit ?? this.freeVideoLimit,
      demoVideoUrl: demoVideoUrl ?? this.demoVideoUrl,
      demoVideoUrlWeb: demoVideoUrlWeb ?? this.demoVideoUrlWeb,
      demoVideoUrlMobile: demoVideoUrlMobile ?? this.demoVideoUrlMobile,
      demoVideoTitle: demoVideoTitle ?? this.demoVideoTitle,
      demoVideoSubtitle: demoVideoSubtitle ?? this.demoVideoSubtitle,
    );
  }

  static const int defaultFreeVideoLimit = 20;

  static const AdminConfigModel defaults = AdminConfigModel(
    title: 'Create clear recordings without setup friction',
    subtitle:
        'Launch a polished recording flow, keep your workspace organized, and let every saved video stay ready for playback or export.',
    primaryActionLabel: 'Start recording',
    secondaryActionLabel: 'Watch demo',
    featurePoints: <String>['Guided setup', 'Saved library', 'Fast export'],
    freeVideoLimit: defaultFreeVideoLimit,
    demoVideoTitle: 'Demo video',
    demoVideoSubtitle: 'Demo video is not configured yet.',
  );

  static String _mimeTypeForUrl(String url) {
    final String lower = url.toLowerCase();
    if (lower.contains('.mp4')) {
      return 'video/mp4';
    }
    if (lower.contains('.webm')) {
      return 'video/webm';
    }

    return 'video/mp4';
  }

  static String _fileExtension(String url) {
    final String lower = url.toLowerCase();
    if (lower.contains('.mp4')) {
      return '.mp4';
    }
    if (lower.contains('.webm')) {
      return '.webm';
    }

    return '.mp4';
  }

  static String? _readFirstNonEmptyString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = json[key];
      if (value is String) {
        final String trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }

    return null;
  }

  static int? _readFirstPositiveInt(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = json[key];
      if (value is int && value > 0) {
        return value;
      }
      if (value is String) {
        final int? parsed = int.tryParse(value.trim());
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    }

    return null;
  }

  static String? _cleanUrl(String? value) {
    if (value == null) {
      return null;
    }

    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool _isClearlyWebmVideo(String value) {
    final String lower = value.toLowerCase();
    return lower.contains('.webm') || lower.contains('video/webm');
  }
}

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
    this.demoVideoUrl,
    this.demoVideoUrlMobile,
    this.demoVideoTitle,
    this.demoVideoSubtitle,
  });

  final String title;
  final String subtitle;
  final String primaryActionLabel;
  final String secondaryActionLabel;
  final List<String> featurePoints;
  final String? demoVideoUrl;
  final String? demoVideoUrlMobile;
  final String? demoVideoTitle;
  final String? demoVideoSubtitle;

  String? get resolvedDemoVideoUrl {
    if (!kIsWeb &&
        demoVideoUrlMobile != null &&
        demoVideoUrlMobile!.trim().isNotEmpty) {
      return demoVideoUrlMobile!.trim();
    }

    if (!kIsWeb) {
      if (demoVideoUrl != null &&
          demoVideoUrl!.trim().isNotEmpty &&
          _mimeTypeForUrl(demoVideoUrl!) == 'video/mp4') {
        return demoVideoUrl!.trim();
      }

      return null;
    }

    if (demoVideoUrl != null && demoVideoUrl!.trim().isNotEmpty) {
      return demoVideoUrl!.trim();
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
          : 'bloop-demo-video$extension',
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
      'demoVideoUrl': demoVideoUrl,
      'demoVideoUrlMobile': demoVideoUrlMobile,
      'demoVideoTitle': demoVideoTitle,
      'demoVideoSubtitle': demoVideoSubtitle,
    };
  }

  factory AdminConfigModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPoints =
        json['featurePoints'] as List<dynamic>? ?? const <dynamic>[];

    return AdminConfigModel(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : defaults.title,
      subtitle: (json['subtitle'] as String?)?.trim().isNotEmpty == true
          ? (json['subtitle'] as String).trim()
          : defaults.subtitle,
      primaryActionLabel:
          (json['primaryActionLabel'] as String?)?.trim().isNotEmpty == true
          ? (json['primaryActionLabel'] as String).trim()
          : defaults.primaryActionLabel,
      secondaryActionLabel:
          (json['secondaryActionLabel'] as String?)?.trim().isNotEmpty == true
          ? (json['secondaryActionLabel'] as String).trim()
          : defaults.secondaryActionLabel,
      featurePoints: rawPoints
          .whereType<String>()
          .map((String value) => value.trim())
          .where((String value) => value.isNotEmpty)
          .toList(growable: false),
      demoVideoUrl: (json['demoVideoUrl'] as String?)?.trim(),
      demoVideoUrlMobile: (json['demoVideoUrlMobile'] as String?)?.trim(),
      demoVideoTitle: (json['demoVideoTitle'] as String?)?.trim(),
      demoVideoSubtitle: (json['demoVideoSubtitle'] as String?)?.trim(),
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
    String? demoVideoUrl,
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
      demoVideoUrl: demoVideoUrl ?? this.demoVideoUrl,
      demoVideoUrlMobile: demoVideoUrlMobile ?? this.demoVideoUrlMobile,
      demoVideoTitle: demoVideoTitle ?? this.demoVideoTitle,
      demoVideoSubtitle: demoVideoSubtitle ?? this.demoVideoSubtitle,
    );
  }

  static const AdminConfigModel defaults = AdminConfigModel(
    title: 'Hassle-free video communication,\nno need to install',
    subtitle:
        'Start recording instantly, keep your workspace clean, and let Firebase videos appear below when your library begins to fill.',
    primaryActionLabel: 'Get Started',
    secondaryActionLabel: 'Watch Intro',
    featurePoints: <String>[
      'Auto video encoding',
      'Easy to use',
      'Complete controls',
    ],
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
}

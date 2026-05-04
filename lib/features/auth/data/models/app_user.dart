import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.emailVerified,
    this.createdAt,
    this.lastSignInAt,
    this.recordedVideosCount = 0,
  });

  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final bool emailVerified;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;
  final int recordedVideosCount;

  String get initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return email.isEmpty ? 'U' : email.substring(0, 1).toUpperCase();
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      'createdAt': createdAt,
      'lastSignInAt': lastSignInAt,
      'recordedVideosCount': recordedVideosCount,
    };
  }

  factory AppUser.fromFirebaseUser(
    firebase_auth.User user, {
    String? nameOverride,
    DateTime? createdAt,
    DateTime? lastSignInAt,
  }) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      name: _resolveName(user, nameOverride: nameOverride),
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      createdAt: createdAt ?? user.metadata.creationTime,
      lastSignInAt: lastSignInAt ?? user.metadata.lastSignInTime,
      recordedVideosCount: 0,
    );
  }

  factory AppUser.fromFirestore(
    Map<String, dynamic> json, {
    required firebase_auth.User fallbackUser,
  }) {
    return AppUser(
      uid: json['uid'] as String? ?? fallbackUser.uid,
      email: json['email'] as String? ?? fallbackUser.email ?? '',
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : _resolveName(fallbackUser),
      photoUrl: json['photoUrl'] as String? ?? fallbackUser.photoURL,
      emailVerified:
          json['emailVerified'] as bool? ?? fallbackUser.emailVerified,
      createdAt:
          _asDateTime(json['createdAt']) ?? fallbackUser.metadata.creationTime,
      lastSignInAt:
          _asDateTime(json['lastSignInAt']) ??
          fallbackUser.metadata.lastSignInTime,
      recordedVideosCount: _asInt(json['recordedVideosCount']) ?? 0,
    );
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

  static String _resolveName(firebase_auth.User user, {String? nameOverride}) {
    final String? preferredName = nameOverride?.trim();
    if (preferredName != null && preferredName.isNotEmpty) {
      return preferredName;
    }

    final String? displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final String? email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'User';
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
}

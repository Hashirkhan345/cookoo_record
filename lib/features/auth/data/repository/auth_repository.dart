import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<AppUser?> getCurrentUser();

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String name,
  });

  Future<AppUser> signInWithGoogle();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> deleteCurrentUser();

  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  Future<void>? _googleSignInInitialization;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncExpand((User? user) {
      if (user == null) {
        return Stream<AppUser?>.value(null);
      }

      unawaited(_syncUserProfile(user));
      return _usersCollection.doc(user.uid).snapshots().map((
        DocumentSnapshot<Map<String, dynamic>> snapshot,
      ) {
        final Map<String, dynamic>? data = snapshot.data();
        if (data == null) {
          return AppUser.fromFirebaseUser(user);
        }
        return AppUser.fromFirestore(data, fallbackUser: user);
      });
    });
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }

    unawaited(_syncUserProfile(user));
    return _readUserProfile(user);
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _firebaseAuth
        .signInWithEmailAndPassword(email: email.trim(), password: password);
    final User user = credential.user ?? _requireCurrentUser();
    unawaited(_syncUserProfile(user));
    return _readUserProfile(user);
  }

  @override
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    User? createdUser;
    try {
      final UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      createdUser = credential.user ?? _requireCurrentUser();
      final String trimmedName = name.trim();
      if (trimmedName.isNotEmpty) {
        await createdUser.updateDisplayName(trimmedName);
        await createdUser.reload();
      }

      final User refreshedUser = _requireCurrentUser();
      final AppUser appUser = AppUser.fromFirebaseUser(
        refreshedUser,
        nameOverride: trimmedName,
      );
      await _writeUserDocument(appUser);
      return _readUserProfile(refreshedUser);
    } catch (error) {
      if (createdUser != null) {
        await _rollbackIncompleteRegistration(createdUser);
      }
      rethrow;
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final UserCredential credential;
    if (kIsWeb) {
      final GoogleAuthProvider provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.setCustomParameters(<String, String>{
        'prompt': 'select_account',
      });
      credential = await _firebaseAuth.signInWithPopup(provider);
    } else {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();
      final String? idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google Sign-In did not return an ID token.');
      }
      credential = await _firebaseAuth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    }

    final User user = credential.user ?? _requireCurrentUser();
    if (credential.additionalUserInfo?.isNewUser ?? false) {
      await _writeUserDocument(AppUser.fromFirebaseUser(user));
    } else {
      unawaited(_syncUserProfile(user));
    }
    return _readUserProfile(user);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> deleteCurrentUser() async {
    final User user = _requireCurrentUser();
    final String uid = user.uid;
    Map<String, dynamic>? existingUserData;
    bool profileDeleted = false;

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _usersCollection.doc(uid).get();
      existingUserData = snapshot.data();
    } catch (error, stackTrace) {
      debugPrint('[auth] Failed to read user profile before deletion: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      await _usersCollection.doc(uid).delete();
      profileDeleted = true;
    } catch (error, stackTrace) {
      debugPrint('[auth] Failed to delete Firestore user profile: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      await user.delete();
    } catch (error, stackTrace) {
      if (profileDeleted && existingUserData != null) {
        try {
          await _usersCollection
              .doc(uid)
              .set(existingUserData, SetOptions(merge: true));
        } catch (restoreError, restoreStackTrace) {
          debugPrint(
            '[auth] Failed to restore user profile after account deletion error: '
            '$restoreError',
          );
          debugPrintStack(stackTrace: restoreStackTrace);
        }
      }

      debugPrint('[auth] Failed to delete Firebase user: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }

    if (!kIsWeb) {
      try {
        await _ensureGoogleSignInInitialized();
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Firebase deletion already succeeded.
      }
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (!kIsWeb) {
      try {
        await _ensureGoogleSignInInitialized();
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Keep Firebase sign-out successful even if GoogleSignIn has no session.
      }
    }
  }

  Future<void> _syncUserProfile(User user, {String? nameOverride}) async {
    final AppUser appUser = AppUser.fromFirebaseUser(
      user,
      nameOverride: nameOverride,
    );
    try {
      await _writeUserDocument(appUser);
    } catch (error, stackTrace) {
      debugPrint('[auth] Failed to persist user profile: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _writeUserDocument(AppUser appUser) {
    final Map<String, Object?> data = <String, Object?>{
      'uid': appUser.uid,
      'email': appUser.email,
      'name': appUser.name,
      'photoUrl': appUser.photoUrl,
      'emailVerified': appUser.emailVerified,
      'createdAt': appUser.createdAt ?? DateTime.now(),
      'lastSignInAt': appUser.lastSignInAt ?? DateTime.now(),
    }..removeWhere((String key, Object? value) => value == null);

    return _usersCollection.doc(appUser.uid).set(data, SetOptions(merge: true));
  }

  Future<AppUser> _readUserProfile(User user) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _usersCollection.doc(user.uid).get();
      final Map<String, dynamic>? data = snapshot.data();
      if (data != null) {
        return AppUser.fromFirestore(data, fallbackUser: user);
      }
    } catch (_) {
      // Fall back to the FirebaseAuth user when the profile document is missing.
    }

    return AppUser.fromFirebaseUser(user);
  }

  Future<void> _rollbackIncompleteRegistration(User user) async {
    try {
      await user.delete();
    } catch (_) {
      await _firebaseAuth.signOut();
    }
  }

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInitialization ??= GoogleSignIn.instance.initialize();
  }

  User _requireCurrentUser() {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user is available.');
    }
    return user;
  }
}

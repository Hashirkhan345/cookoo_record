import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository/auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (Ref ref) => FirebaseAuthRepository(),
);

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (Ref ref) => AuthController(ref.read(authRepositoryProvider)),
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthState()) {
    _authSubscription = _repository.authStateChanges().listen(
      (user) {
        if (user != null && state.isSubmitting) {
          return;
        }

        state = state.copyWith(
          isLoading: false,
          isSubmitting: false,
          user: user,
          clearUser: user == null,
          clearFeedbackMessage: true,
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        state = state.copyWith(
          isLoading: false,
          isSubmitting: false,
          feedbackMessage: _describeAuthError(error),
        );
      },
    );
  }

  final AuthRepository _repository;
  StreamSubscription<Object?>? _authSubscription;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    state = state.copyWith(isSubmitting: true, clearFeedbackMessage: true);

    try {
      final user = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      state = state.copyWith(
        isSubmitting: false,
        user: user,
        clearFeedbackMessage: true,
      );
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        feedbackMessage: _describeAuthError(error),
      );
    }
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    state = state.copyWith(isSubmitting: true, clearFeedbackMessage: true);

    try {
      final user = await _repository.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(
        isSubmitting: false,
        user: user,
        clearFeedbackMessage: true,
      );
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        feedbackMessage: _describeAuthError(error),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    if (state.isSubmitting) {
      return;
    }

    state = state.copyWith(isSubmitting: true, clearFeedbackMessage: true);

    try {
      final user = await _repository.signInWithGoogle();
      state = state.copyWith(
        isSubmitting: false,
        user: user,
        clearFeedbackMessage: true,
      );
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        feedbackMessage: _describeAuthError(error),
      );
    }
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    if (state.isSubmitting) {
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearFeedbackMessage: true);

    try {
      await _repository.sendPasswordResetEmail(email: email);
      state = state.copyWith(isSubmitting: false, clearFeedbackMessage: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        feedbackMessage: _describeAuthError(error),
      );
      return false;
    }
  }

  Future<void> deleteAccount() async {
    if (state.isSubmitting) {
      return;
    }

    state = state.copyWith(isSubmitting: true, clearFeedbackMessage: true);

    try {
      await _repository.deleteCurrentUser();
      state = state.copyWith(
        isSubmitting: false,
        clearUser: true,
        clearFeedbackMessage: true,
      );
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        feedbackMessage: _describeAuthError(error),
      );
    }
  }

  Future<void> signOut() async {
    if (state.isSubmitting) {
      return;
    }

    state = state.copyWith(isSubmitting: true, clearFeedbackMessage: true);
    try {
      await _repository.signOut();
      state = state.copyWith(
        isSubmitting: false,
        clearUser: true,
        clearFeedbackMessage: true,
      );
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        feedbackMessage: _describeAuthError(error),
      );
    }
  }

  void clearFeedbackMessage() {
    state = state.copyWith(clearFeedbackMessage: true);
  }

  String _describeAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'invalid-credential':
          return 'Email or password is incorrect.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
          return 'No account exists for this email.';
        case 'wrong-password':
          return 'Email or password is incorrect.';
        case 'email-already-in-use':
          return 'An account already exists for this email.';
        case 'weak-password':
          return 'Use a stronger password with at least 6 characters.';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        case 'popup-closed-by-user':
          return 'Google Sign-In was cancelled.';
        case 'popup-blocked':
          return 'Allow popups in the browser to continue with Google Sign-In.';
        case 'operation-not-allowed':
          return 'Enable this sign-in method in Firebase Authentication.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'requires-recent-login':
        case 'credential-too-old-login-again':
          return 'For security, sign in again before deleting your account.';
        default:
          return error.message ?? error.code;
      }
    }

    if (error is StateError) {
      final String message = error.message.toString();
      if (message.isNotEmpty) {
        return message;
      }
    }

    final String rawMessage = error.toString();
    if (rawMessage.contains('Google Sign-In was cancelled')) {
      return 'Google Sign-In was cancelled.';
    }
    return rawMessage;
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}

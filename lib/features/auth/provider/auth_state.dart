import 'package:flutter/foundation.dart';

import '../data/models/app_user.dart';

@immutable
class AuthState {
  const AuthState({
    this.isLoading = true,
    this.isSubmitting = false,
    this.user,
    this.feedbackMessage,
  });

  final bool isLoading;
  final bool isSubmitting;
  final AppUser? user;
  final String? feedbackMessage;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    AppUser? user,
    String? feedbackMessage,
    bool clearUser = false,
    bool clearFeedbackMessage = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      user: clearUser ? null : user ?? this.user,
      feedbackMessage: clearFeedbackMessage
          ? null
          : feedbackMessage ?? this.feedbackMessage,
    );
  }
}

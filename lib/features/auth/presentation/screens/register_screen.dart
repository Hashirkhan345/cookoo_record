import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../provider/auth_provider.dart';
import '../../provider/auth_state.dart';
import '../../../video/presentation/controller/video_feature_theme.dart';
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
        return;
      }

      if (next.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
        Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
        return;
      }

      final String? feedbackMessage = next.feedbackMessage;
      if (feedbackMessage != null &&
          feedbackMessage != previous?.feedbackMessage) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(feedbackMessage)));
        ref.read(authControllerProvider.notifier).clearFeedbackMessage();
      }
    });

    final AuthState authState = ref.watch(authControllerProvider);

    return AuthScreenScaffold(
      title: 'Create account',
      subtitle: 'Register with email/password or continue with Google.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Already have an account?',
            style: TextStyle(color: VideoFeatureTheme.muted),
          ),
          TextButton(
            onPressed: authState.isSubmitting
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Sign in'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AuthTextField(
              controller: _nameController,
              label: 'Full name',
              autofillHints: const <String>[AutofillHints.name],
              validator: (String? value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Enter your name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _emailController,
              label: 'Email',
              autofillHints: const <String>[AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              validator: (String? value) {
                final String email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return 'Enter your email.';
                }
                if (!email.contains('@')) {
                  return 'Enter a valid email.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              label: 'Password',
              autofillHints: const <String>[AutofillHints.newPassword],
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              validator: (String? value) {
                if ((value ?? '').length < 6) {
                  return 'Use at least 6 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              autofillHints: const <String>[],
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              validator: (String? value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: authState.isSubmitting ? null : _submitRegistration,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                backgroundColor: VideoFeatureTheme.primary,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: authState.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create account'),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: authState.isSubmitting
                  ? null
                  : ref.read(authControllerProvider.notifier).signInWithGoogle,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                foregroundColor: VideoFeatureTheme.ink,
                side: const BorderSide(color: VideoFeatureTheme.line),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Continue with Google'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRegistration() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .registerWithEmail(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }
}

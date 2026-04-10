import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/widgets/google_brand_icon.dart';
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
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoute.home, (Route<dynamic> _) => false);
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
      subtitle:
          'Set up your bloop workspace to keep recordings, drafts, and account access in one place.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: <Widget>[
          const Text(
            'Already have an account?',
            style: TextStyle(color: VideoFeatureTheme.muted),
          ),
          TextButton(
            onPressed: authState.isSubmitting ? null : _backToSignIn,
            child: const Text('Sign in'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VideoFeatureTheme.panelMuted.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: VideoFeatureTheme.line),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.verified_user_outlined,
                    color: VideoFeatureTheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Create your main account',
                          style: TextStyle(
                            color: VideoFeatureTheme.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Use the email you want connected to saved recordings and account recovery.',
                          style: TextStyle(
                            color: VideoFeatureTheme.muted,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 10),
            const Text(
              'Use at least 6 characters. A longer password is safer.',
              style: TextStyle(
                color: VideoFeatureTheme.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: authState.isSubmitting ? null : _submitRegistration,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: VideoFeatureTheme.accent,
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
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(height: 1, color: VideoFeatureTheme.line),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: TextStyle(
                      color: VideoFeatureTheme.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: VideoFeatureTheme.line),
                ),
              ],
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: authState.isSubmitting
                  ? null
                  : ref.read(authControllerProvider.notifier).signInWithGoogle,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                backgroundColor: VideoFeatureTheme.panelMuted.withValues(
                  alpha: 0.4,
                ),
                foregroundColor: VideoFeatureTheme.ink,
                side: const BorderSide(color: VideoFeatureTheme.line),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const GoogleBrandIcon(size: 20),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 14),
            const Text(
              'By continuing, you are creating a bloop account for this workspace.',
              style: TextStyle(
                color: VideoFeatureTheme.muted,
                fontSize: 12,
                height: 1.45,
              ),
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

  Future<void> _backToSignIn() async {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    await navigator.pushReplacementNamed(AppRoute.login);
  }
}

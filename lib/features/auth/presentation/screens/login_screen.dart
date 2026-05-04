import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/widgets/google_brand_icon.dart';
import '../../provider/auth_provider.dart';
import '../../provider/auth_state.dart';
import '../../../video/presentation/controller/video_feature_theme.dart';
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
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
      title: 'Sign in',
      subtitle: 'Email or Google access.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: <Widget>[
          Text(
            'No account?',
            style: TextStyle(color: VideoFeatureTheme.mutedFor(context)),
          ),
          TextButton(
            onPressed: authState.isSubmitting
                ? null
                : () => Navigator.of(context).pushNamed(AppRoute.register),
            child: const Text('Create account'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
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
              autofillHints: const <String>[],
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              validator: (String? value) {
                if ((value ?? '').isEmpty) {
                  return 'Enter your password.';
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: authState.isSubmitting ? null : _openForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: authState.isSubmitting ? null : _submitLogin,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
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
                  : const Text('Sign in'),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    height: 1,
                    color: VideoFeatureTheme.lineFor(context),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: TextStyle(
                      color: VideoFeatureTheme.mutedFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: VideoFeatureTheme.lineFor(context),
                  ),
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
                backgroundColor: VideoFeatureTheme.panelMutedFor(
                  context,
                ).withValues(alpha: 0.4),
                foregroundColor: VideoFeatureTheme.inkFor(context),
                side: BorderSide(color: VideoFeatureTheme.lineFor(context)),
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
              label: const Text('Use Google'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  Future<void> _openForgotPassword() async {
    final String? result = await Navigator.of(context).pushNamed<String>(
      AppRoute.forgotPassword,
      arguments: _emailController.text.trim(),
    );

    if (!mounted || result == null) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(result)));
  }
}

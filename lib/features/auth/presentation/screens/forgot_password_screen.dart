import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../provider/auth_provider.dart';
import '../../provider/auth_state.dart';
import '../../../video/presentation/controller/video_feature_theme.dart';
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail,
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
        return;
      }

      final String? feedbackMessage = next.feedbackMessage;
      if (feedbackMessage == null ||
          feedbackMessage == previous?.feedbackMessage) {
        return;
      }

      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(feedbackMessage)));
      ref.read(authControllerProvider.notifier).clearFeedbackMessage();
    });

    final AuthState authState = ref.watch(authControllerProvider);

    return AuthScreenScaffold(
      title: 'Forgot password',
      subtitle:
          'Enter the email linked to your Aks account and we will send you a reset link.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: <Widget>[
          Text(
            'Remembered your password?',
            style: TextStyle(color: VideoFeatureTheme.mutedFor(context)),
          ),
          TextButton(
            onPressed: authState.isSubmitting ? null : _backToSignIn,
            child: const Text('Back to sign in'),
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
                color: VideoFeatureTheme.panelMutedFor(
                  context,
                ).withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: VideoFeatureTheme.lineFor(context)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.mark_email_unread_outlined,
                    color: VideoFeatureTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'We will email a secure link',
                          style: TextStyle(
                            color: VideoFeatureTheme.inkFor(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reset emails usually arrive within a minute. If you do not see it, check spam or promotions.',
                          style: TextStyle(
                            color: VideoFeatureTheme.mutedFor(context),
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
            const SizedBox(height: 24),
            FilledButton(
              onPressed: authState.isSubmitting ? null : _submitResetRequest,
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
                  : const Text('Send reset link'),
            ),
            const SizedBox(height: 12),
            Text(
              'Use the same email you use to sign in to Aks.',
              style: TextStyle(
                color: VideoFeatureTheme.mutedFor(context),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitResetRequest() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final bool didSendResetEmail = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(email: _emailController.text.trim());

    if (!didSendResetEmail || !mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pop('Password reset email sent. Check your inbox for the reset link.');
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

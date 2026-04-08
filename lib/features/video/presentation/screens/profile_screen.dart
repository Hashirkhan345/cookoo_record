import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../auth/provider/auth_state.dart';
import '../controller/video_feature_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _confirmDeleteAccount() async {
    if (ref.read(authControllerProvider).isSubmitting) {
      return;
    }

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: VideoFeatureTheme.line),
          ),
          title: const Text(
            'Delete account?',
            style: TextStyle(
              color: VideoFeatureTheme.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'This permanently removes your bloop account. If your session is old, Firebase may ask you to sign in again before deletion can finish.',
            style: TextStyle(
              color: VideoFeatureTheme.muted,
              fontSize: 15,
              height: 1.55,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFAF2D2D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await ref.read(authControllerProvider.notifier).deleteAccount();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }

      if ((previous?.isAuthenticated ?? false) && !next.isAuthenticated) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoute.login, (Route<dynamic> _) => false);
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
    final AppUser user = authState.user ?? widget.user;
    final bool isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: VideoFeatureTheme.screenBackground,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1380),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: authState.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: VideoFeatureTheme.ink,
                        side: const BorderSide(color: VideoFeatureTheme.line),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(color: VideoFeatureTheme.line),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x140B1326),
                            blurRadius: 32,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isWide ? 42 : 24,
                          isWide ? 34 : 24,
                          isWide ? 42 : 24,
                          isWide ? 36 : 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    color: VideoFeatureTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.manage_accounts_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Text(
                                    'Manage your profile',
                                    style: TextStyle(
                                      color: VideoFeatureTheme.ink,
                                      fontSize: isWide ? 28 : 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            const Divider(
                              height: 1,
                              color: VideoFeatureTheme.line,
                            ),
                            const SizedBox(height: 34),
                            const Text(
                              'Name and photo',
                              style: TextStyle(
                                color: VideoFeatureTheme.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Your public profile information is shown below.',
                              style: TextStyle(
                                color: VideoFeatureTheme.muted,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),
                            isWide
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      _ProfileAvatar(user: user, size: 220),
                                      const SizedBox(width: 38),
                                      Expanded(
                                        child: _ProfileValueColumn(
                                          label: 'Full name',
                                          value: user.name,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: _ProfileAvatar(
                                          user: user,
                                          size: 160,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      _ProfileValueColumn(
                                        label: 'Full name',
                                        value: user.name,
                                      ),
                                    ],
                                  ),
                            const SizedBox(height: 36),
                            const Divider(
                              height: 1,
                              color: VideoFeatureTheme.line,
                            ),
                            const SizedBox(height: 34),
                            const Text(
                              'Contact info',
                              style: TextStyle(
                                color: VideoFeatureTheme.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _ProfileValueColumn(
                              label: 'Email address',
                              value: user.email,
                            ),
                            const SizedBox(height: 18),
                            _ProfileValueColumn(
                              label: 'Email status',
                              value: user.emailVerified
                                  ? 'Verified'
                                  : 'Not verified yet',
                            ),
                            const SizedBox(height: 36),
                            const Divider(
                              height: 1,
                              color: VideoFeatureTheme.line,
                            ),
                            const SizedBox(height: 34),
                            const Text(
                              'Delete account',
                              style: TextStyle(
                                color: VideoFeatureTheme.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Deleting your account permanently removes your access to bloop on this workspace.',
                              style: TextStyle(
                                color: VideoFeatureTheme.muted,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: authState.isSubmitting
                                  ? null
                                  : _confirmDeleteAccount,
                              icon: authState.isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline_rounded),
                              label: Text(
                                authState.isSubmitting
                                    ? 'Deleting account...'
                                    : 'Delete Account',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFAF2D2D),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xFFDBB3B3,
                                ),
                                disabledForegroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 34),
                            const Divider(
                              height: 1,
                              color: VideoFeatureTheme.line,
                            ),
                            const SizedBox(height: 30),
                            Wrap(
                              spacing: 18,
                              runSpacing: 18,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: <Widget>[
                                const SizedBox(
                                  width: 680,
                                  child: Text(
                                    'Review your profile details here, then return to the workspace when you are done.',
                                    style: TextStyle(
                                      color: VideoFeatureTheme.muted,
                                      fontSize: 16,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: authState.isSubmitting
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  label: const Text('Back to workspace'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: VideoFeatureTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user, required this.size});

  final AppUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final String? photoUrl = user.photoUrl?.trim();
    final bool hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF18A7C5),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return _InitialsAvatar(
                      initials: user.initials,
                      fontSize: size * 0.34,
                    );
                  },
            )
          : _InitialsAvatar(initials: user.initials, fontSize: size * 0.34),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials, required this.fontSize});

  final String initials;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: const Color(0xFF11335B),
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
    );
  }
}

class _ProfileValueColumn extends StatelessWidget {
  const _ProfileValueColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: VideoFeatureTheme.muted,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          value,
          style: const TextStyle(
            color: VideoFeatureTheme.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../auth/provider/auth_state.dart';
import '../../provider/video_provider.dart';
import '../controller/video_feature_theme.dart';
import '../widgets/studio_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isDeletingAccount = false;
  bool _didHandleDeletionSuccess = false;

  Future<void> _confirmDeleteAccount() async {
    if (ref.read(authControllerProvider).isSubmitting) {
      return;
    }

    final bool? shouldDelete = await showStudioDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StudioDialogShell(
          badge: 'Account',
          icon: Icons.delete_outline_rounded,
          title: 'Delete account?',
          message:
              'This permanently removes your bloop account. If your session is old, Firebase may ask you to sign in again before deletion can finish.',
          maxWidth: 640,
          actions: Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                ),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFAF2D2D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    _isDeletingAccount = true;
    await ref.read(authControllerProvider.notifier).deleteAccount();

    if (!mounted) {
      return;
    }

    if (ref.read(authControllerProvider).isAuthenticated) {
      _isDeletingAccount = false;
    }
  }

  Future<void> _handleDeletedAccountRedirect() async {
    if (_didHandleDeletionSuccess) {
      return;
    }

    _didHandleDeletionSuccess = true;
    await ref
        .read(videoControllerProvider.notifier)
        .clearSavedRecordings(feedbackMessage: null);

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoute.login, (Route<dynamic> _) => false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }

      if ((previous?.isAuthenticated ?? false) && !next.isAuthenticated) {
        if (_isDeletingAccount) {
          unawaited(_handleDeletedAccountRedirect());
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoute.login,
            (Route<dynamic> _) => false,
          );
        }
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
    final bool isWide = MediaQuery.sizeOf(context).width >= 980;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: VideoFeatureTheme.screenBackground,
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -50,
            child: _BackdropGlow(
              size: MediaQuery.sizeOf(context).width * 0.34,
              color: const Color(0x26E8BC67),
            ),
          ),
          Positioned(
            right: -90,
            top: 70,
            child: _BackdropGlow(
              size: MediaQuery.sizeOf(context).width * 0.32,
              color: const Color(0x24147A73),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: authState.isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Back'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: VideoFeatureTheme.ink,
                              side: const BorderSide(
                                color: VideoFeatureTheme.line,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                          const Spacer(),
                          FilledButton.tonalIcon(
                            onPressed: authState.isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.grid_view_rounded),
                            label: const Text('Workspace'),
                            style: FilledButton.styleFrom(
                              foregroundColor: VideoFeatureTheme.primaryDeep,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.78,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _ProfileHeroCard(
                        user: user,
                        isWide: isWide,
                        memberSince: _formatDate(context, user.createdAt),
                      ),
                      const SizedBox(height: 22),
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                              final bool useSplit = constraints.maxWidth >= 980;
                              final Widget detailsCard = _ProfileSectionCard(
                                title: 'Details',
                                child: Column(
                                  children: <Widget>[
                                    _InfoRow(
                                      label: 'Full name',
                                      value: user.name,
                                    ),
                                    const SizedBox(height: 18),
                                    const Divider(
                                      color: VideoFeatureTheme.line,
                                      height: 1,
                                    ),
                                    const SizedBox(height: 18),
                                    _InfoRow(label: 'Email', value: user.email),
                                    const SizedBox(height: 18),
                                    const Divider(
                                      color: VideoFeatureTheme.line,
                                      height: 1,
                                    ),
                                    const SizedBox(height: 18),
                                    _InfoRow(
                                      label: 'User ID',
                                      value: _shortUid(user.uid),
                                    ),
                                  ],
                                ),
                              );
                              final Widget statusCard = _ProfileSectionCard(
                                title: 'Account',
                                child: Wrap(
                                  spacing: 14,
                                  runSpacing: 14,
                                  children: <Widget>[
                                    _StatusTile(
                                      label: 'Email',
                                      value: user.emailVerified
                                          ? 'Verified'
                                          : 'Pending',
                                    ),
                                    _StatusTile(
                                      label: 'Joined',
                                      value: _formatDate(
                                        context,
                                        user.createdAt,
                                      ),
                                    ),
                                    _StatusTile(
                                      label: 'Last sign in',
                                      value: _formatDate(
                                        context,
                                        user.lastSignInAt,
                                      ),
                                    ),
                                    _StatusTile(
                                      label: 'Avatar',
                                      value:
                                          (user.photoUrl?.trim().isNotEmpty ??
                                              false)
                                          ? 'Photo'
                                          : 'Initials',
                                    ),
                                  ],
                                ),
                              );
                              final Widget deleteCard = _DangerZoneCard(
                                isBusy: authState.isSubmitting,
                                onDelete: _confirmDeleteAccount,
                              );

                              if (!useSplit) {
                                return Column(
                                  children: <Widget>[
                                    detailsCard,
                                    const SizedBox(height: 18),
                                    statusCard,
                                    const SizedBox(height: 18),
                                    deleteCard,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(flex: 6, child: detailsCard),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      children: <Widget>[
                                        statusCard,
                                        const SizedBox(height: 18),
                                        deleteCard,
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime? value) {
    if (value == null) {
      return 'Unavailable';
    }

    return MaterialLocalizations.of(context).formatShortDate(value.toLocal());
  }

  String _shortUid(String uid) {
    if (uid.length <= 12) {
      return uid;
    }

    return '${uid.substring(0, 6)}...${uid.substring(uid.length - 4)}';
  }
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.user,
    required this.isWide,
    required this.memberSince,
  });

  final AppUser user;
  final bool isWide;
  final String memberSince;

  @override
  Widget build(BuildContext context) {
    final Widget summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: VideoFeatureTheme.accentSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Profile',
            style: TextStyle(
              color: VideoFeatureTheme.accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          user.name,
          style: TextStyle(
            color: VideoFeatureTheme.ink,
            fontSize: isWide ? 38 : 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          user.email,
          style: const TextStyle(
            color: VideoFeatureTheme.muted,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _FactChip(
              icon: user.emailVerified
                  ? Icons.verified_rounded
                  : Icons.mark_email_unread_outlined,
              label: user.emailVerified ? 'Verified' : 'Pending',
            ),
            _FactChip(
              icon: Icons.calendar_month_rounded,
              label: 'Since $memberSince',
            ),
          ],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: VideoFeatureTheme.line),
        boxShadow: VideoFeatureTheme.panelShadow,
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -20,
            right: -24,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VideoFeatureTheme.primary.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isWide ? 30 : 22,
              isWide ? 28 : 22,
              isWide ? 30 : 22,
              isWide ? 28 : 22,
            ),
            child: isWide
                ? Row(
                    children: <Widget>[
                      Expanded(child: summary),
                      const SizedBox(width: 24),
                      _ProfileAvatarDisplay(user: user, size: 168),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      summary,
                      const SizedBox(height: 20),
                      _ProfileAvatarDisplay(user: user, size: 136),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VideoFeatureTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: VideoFeatureTheme.primary, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: VideoFeatureTheme.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatarDisplay extends StatelessWidget {
  const _ProfileAvatarDisplay({required this.user, required this.size});

  final AppUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        _ProfileAvatar(user: user, size: size),
        Positioned(
          right: 6,
          bottom: 10,
          child: Container(
            width: size * 0.2,
            height: size * 0.2,
            decoration: BoxDecoration(
              color: user.emailVerified
                  ? VideoFeatureTheme.success
                  : VideoFeatureTheme.focus,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: VideoFeatureTheme.line),
        boxShadow: VideoFeatureTheme.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: VideoFeatureTheme.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(
              color: VideoFeatureTheme.muted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: VideoFeatureTheme.ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VideoFeatureTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VideoFeatureTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: VideoFeatureTheme.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: VideoFeatureTheme.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerZoneCard extends StatelessWidget {
  const _DangerZoneCard({required this.isBusy, required this.onDelete});

  final bool isBusy;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0x1FB24B37)),
        boxShadow: VideoFeatureTheme.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Danger zone',
            style: TextStyle(
              color: VideoFeatureTheme.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Delete this account and clear access for this workspace.',
            style: TextStyle(
              color: VideoFeatureTheme.muted,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: isBusy ? null : () => onDelete(),
            icon: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_outline_rounded),
            label: Text(isBusy ? 'Deleting account...' : 'Delete account'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFAF2D2D),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFDBB3B3),
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF7FD7C2), Color(0xFF1A8D7C)],
        ),
        boxShadow: VideoFeatureTheme.panelShadow,
      ),
      padding: const EdgeInsets.all(6),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return _InitialsAvatar(
                        initials: user.initials,
                        fontSize: size * 0.28,
                      );
                    },
              )
            : _InitialsAvatar(initials: user.initials, fontSize: size * 0.28),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials, required this.fontSize});

  final String initials;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF7F3EC), Color(0xFFE8F0EC)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: VideoFeatureTheme.primaryDeep,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}

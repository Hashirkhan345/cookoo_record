import 'package:flutter/material.dart';

import '../../../auth/data/models/app_user.dart';
import '../controller/video_feature_theme.dart';

enum HomeAccountMenuAction {
  profile,
  // integrations,
  settings,
  guide,
  helpCenter,
  privacyPolicy,
  termsAndConditions,
  signOut,
}

class HomeAccountMenu extends StatelessWidget {
  const HomeAccountMenu({
    super.key,
    required this.user,
    required this.isBusy,
    required this.onSelected,
  });

  final AppUser user;
  final bool isBusy;
  final ValueChanged<HomeAccountMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isBusy ? 0.68 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy ? null : () => _showAccountPanel(context),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: VideoFeatureTheme.line),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x0E0B1326),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user.initials,
                style: const TextStyle(
                  color: VideoFeatureTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAccountPanel(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final bool isDesktop = screenSize.width >= 720;

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Account panel',
      barrierColor: Colors.black.withValues(alpha: 0.12),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder:
          (
            BuildContext dialogContext,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, isDesktop ? 16 : 24, 16, 16),
                child: Align(
                  alignment: isDesktop ? Alignment.topRight : Alignment.center,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 420,
                      maxHeight: screenSize.height - (isDesktop ? 32 : 40),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: _AccountPanel(
                        user: user,
                        onClose: () => Navigator.of(dialogContext).pop(),
                        onActionSelected: (HomeAccountMenuAction action) {
                          Navigator.of(dialogContext).pop();
                          onSelected(action);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final CurvedAnimation curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
    );
  }
}

class _AccountPanel extends StatelessWidget {
  const _AccountPanel({
    required this.user,
    required this.onClose,
    required this.onActionSelected,
  });

  final AppUser user;
  final VoidCallback onClose;
  final ValueChanged<HomeAccountMenuAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: VideoFeatureTheme.line),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x180B1326),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 18, 28),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 96,
                              height: 96,
                              decoration: const BoxDecoration(
                                color: Color(0xFF18A7C5),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  user.initials,
                                  style: const TextStyle(
                                    color: Color(0xFF11335B),
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: VideoFeatureTheme.ink,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.7,
                              ),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () =>
                                  onActionSelected(HomeAccountMenuAction.profile),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: VideoFeatureTheme.ink,
                                minimumSize: const Size(0, 52),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 14,
                                ),
                                side: const BorderSide(
                                  color: VideoFeatureTheme.line,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Edit profile'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: onClose,
                      tooltip: 'Close account panel',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: VideoFeatureTheme.ink,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: VideoFeatureTheme.line),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                child: Column(
                  children: <Widget>[
                    _AccountActionTile(
                      label: 'View profile',
                      onTap: () =>
                          onActionSelected(HomeAccountMenuAction.profile),
                    ),
                    _AccountActionTile(
                      label: 'Settings',
                      onTap: () =>
                          onActionSelected(HomeAccountMenuAction.settings),
                    ),
                    _AccountActionTile(
                      label: 'Guide',
                      onTap: () =>
                          onActionSelected(HomeAccountMenuAction.guide),
                    ),
                    _AccountActionTile(
                      label: 'Help Center',
                      onTap: () =>
                          onActionSelected(HomeAccountMenuAction.helpCenter),
                    ),
                    _AccountActionTile(
                      label: 'Privacy Policy',
                      onTap: () =>
                          onActionSelected(HomeAccountMenuAction.privacyPolicy),
                    ),
                    _AccountActionTile(
                      label: 'Terms & Conditions',
                      onTap: () => onActionSelected(
                        HomeAccountMenuAction.termsAndConditions,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: VideoFeatureTheme.line),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: _AccountActionTile(
                  label: 'Sign Out',
                  onTap: () => onActionSelected(HomeAccountMenuAction.signOut),
                  isDestructive: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDestructive
                        ? const Color(0xFFAF2D2D)
                        : VideoFeatureTheme.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isDestructive)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: VideoFeatureTheme.muted,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

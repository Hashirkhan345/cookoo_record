import 'package:flutter/material.dart';

import '../../../auth/data/models/app_user.dart';
import '../controller/video_feature_theme.dart';

enum HomeAccountMenuAction {
  profile,
  // integrations,
  settings,
  login,
  guide,
  helpCenter,
  privacyPolicy,
  termsAndConditions,
  signOut,
}

class HomeAccountMenu extends StatelessWidget {
  const HomeAccountMenu({
    super.key,
    required this.isBusy,
    required this.onSelected,
    this.user,
    this.guestLabel = 'Guest user',
  });

  final AppUser? user;
  final bool isBusy;
  final ValueChanged<HomeAccountMenuAction> onSelected;
  final String guestLabel;

  bool get isGuest => user == null;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.sizeOf(context).width < 600;
    return Opacity(
      opacity: isBusy ? 0.68 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy ? null : () => _showAccountPanel(context),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: isPhone ? 48 : 56,
            height: isPhone ? 48 : 56,
            decoration: BoxDecoration(
              gradient: VideoFeatureTheme.primaryGradient,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
              boxShadow: VideoFeatureTheme.floatingShadow,
            ),
            child: Center(
              child: isGuest
                  ? const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    )
                  : Text(
                      user!.initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: isPhone ? 18 : 22,
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
    final bool isPhone = screenSize.width < 600;

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
                padding: EdgeInsets.fromLTRB(
                  isPhone ? 10 : 16,
                  isDesktop ? 16 : (isPhone ? 12 : 24),
                  isPhone ? 10 : 16,
                  isPhone ? 10 : 16,
                ),
                child: Align(
                  alignment: isDesktop ? Alignment.topRight : Alignment.center,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isPhone ? screenSize.width - 20 : 420,
                      maxHeight:
                          screenSize.height -
                          (isDesktop ? 32 : (isPhone ? 20 : 40)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: _AccountPanel(
                        user: user,
                        guestLabel: guestLabel,
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
    required this.guestLabel,
    required this.onClose,
    required this.onActionSelected,
  });

  final AppUser? user;
  final String guestLabel;
  final VoidCallback onClose;
  final ValueChanged<HomeAccountMenuAction> onActionSelected;

  bool get isGuest => user == null;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.sizeOf(context).width < 600;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(isPhone ? 26 : 36),
        border: Border.all(color: VideoFeatureTheme.line),
        boxShadow: VideoFeatureTheme.panelShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isPhone ? 26 : 36),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isPhone ? 16 : 24,
                  isPhone ? 16 : 24,
                  isPhone ? 12 : 18,
                  isPhone ? 16 : 24,
                ),
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
                              width: double.infinity,
                              padding: EdgeInsets.all(isPhone ? 14 : 20),
                              decoration: BoxDecoration(
                                gradient: VideoFeatureTheme.heroGradient,
                                borderRadius: BorderRadius.circular(
                                  isPhone ? 22 : 28,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: isPhone ? 58 : 74,
                                    height: isPhone ? 58 : 74,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.16,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: isGuest
                                          ? const Icon(
                                              Icons.person_outline_rounded,
                                              color: Colors.white,
                                              size: 28,
                                            )
                                          : Text(
                                              user!.initials,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: isPhone ? 22 : 26,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.7,
                                              ),
                                            ),
                                    ),
                                  ),
                                  SizedBox(width: isPhone ? 12 : 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          user?.name ?? guestLabel,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isPhone ? 18 : 22,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.6,
                                          ),
                                        ),
                                        SizedBox(height: isPhone ? 4 : 8),
                                        Text(
                                          isGuest ? 'Browse first' : 'Owner',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.76,
                                            ),
                                            fontSize: isPhone ? 12 : 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isPhone ? 12 : 16),
                            OutlinedButton(
                              onPressed: () => onActionSelected(
                                isGuest
                                    ? HomeAccountMenuAction.login
                                    : HomeAccountMenuAction.profile,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: VideoFeatureTheme.ink,
                                backgroundColor: VideoFeatureTheme.panelMuted
                                    .withValues(alpha: 0.45),
                                minimumSize: Size(0, isPhone ? 46 : 54),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isPhone ? 16 : 22,
                                  vertical: isPhone ? 12 : 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                textStyle: TextStyle(
                                  fontSize: isPhone ? 13 : 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: Text(isGuest ? 'Login' : 'Edit profile'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: isPhone ? 6 : 12),
                    IconButton(
                      onPressed: onClose,
                      tooltip: 'Close account panel',
                      icon: Icon(
                        Icons.close_rounded,
                        color: VideoFeatureTheme.ink,
                        size: isPhone ? 28 : 34,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: VideoFeatureTheme.line),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isPhone ? 12 : 18,
                  vertical: isPhone ? 10 : 14,
                ),
                child: Column(
                  children: <Widget>[
                    _AccountActionTile(
                      label: 'Settings',
                      onTap: () =>
                          onActionSelected(HomeAccountMenuAction.settings),
                    ),
                    if (!isGuest)
                      _AccountActionTile(
                        label: 'View profile',
                        onTap: () =>
                            onActionSelected(HomeAccountMenuAction.profile),
                      ),
                    if (isGuest)
                      _AccountActionTile(
                        label: 'Login',
                        onTap: () =>
                            onActionSelected(HomeAccountMenuAction.login),
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
              if (!isGuest)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isPhone ? 12 : 18,
                    isPhone ? 10 : 14,
                    isPhone ? 12 : 18,
                    isPhone ? 12 : 18,
                  ),
                  child: _AccountActionTile(
                    label: 'Sign Out',
                    onTap: () =>
                        onActionSelected(HomeAccountMenuAction.signOut),
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
    final bool isPhone = MediaQuery.sizeOf(context).width < 600;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isPhone ? 18 : 22),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: isPhone ? 4 : 6),
          padding: EdgeInsets.symmetric(
            horizontal: isPhone ? 12 : 14,
            vertical: isPhone ? 13 : 16,
          ),
          decoration: BoxDecoration(
            color: isDestructive
                ? VideoFeatureTheme.accentSoft.withValues(alpha: 0.5)
                : VideoFeatureTheme.panel,
            borderRadius: BorderRadius.circular(isPhone ? 18 : 22),
            border: Border.all(
              color: isDestructive
                  ? VideoFeatureTheme.accent.withValues(alpha: 0.18)
                  : VideoFeatureTheme.line,
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isDestructive
                        ? VideoFeatureTheme.danger
                        : VideoFeatureTheme.ink,
                    fontSize: isPhone ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isDestructive)
                Icon(
                  Icons.arrow_forward_rounded,
                  color: VideoFeatureTheme.muted,
                  size: isPhone ? 18 : 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

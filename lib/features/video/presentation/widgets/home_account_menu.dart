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
    final bool isDark = VideoFeatureTheme.isDark(context);
    return Opacity(
      opacity: isBusy ? 0.68 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy ? null : () => _showAccountPanel(context),
          borderRadius: BorderRadius.circular(999),
          child: _AccountInitialsBadge(
            width: isPhone ? 48 : 56,
            height: isPhone ? 48 : 56,
            label: isGuest ? null : user!.initials,
            icon: isGuest ? Icons.person_outline_rounded : null,
            fontSize: isGuest ? (isPhone ? 16 : 18) : (isPhone ? 18 : 22),
            borderColor: isDark
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.8),
            showShadow: true,
          ),
        ),
      ),
    );
  }

  static Future<void> showAccountPanel({
    required BuildContext context,
    required AppUser? user,
    required String guestLabel,
    required ValueChanged<HomeAccountMenuAction> onSelected,
  }) {
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

  Future<void> _showAccountPanel(BuildContext context) {
    return showAccountPanel(
      context: context,
      user: user,
      guestLabel: guestLabel,
      onSelected: onSelected,
    );
  }
}

class AccountInitialsBadge extends StatelessWidget {
  const AccountInitialsBadge({
    super.key,
    required this.label,
    required this.size,
    this.fontSize = 18,
  });

  final String label;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final bool isDark = VideoFeatureTheme.isDark(context);
    return _AccountInitialsBadge(
      width: size,
      height: size,
      label: label,
      fontSize: fontSize,
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.white.withValues(alpha: 0.8),
      showShadow: false,
    );
  }
}

class _AccountInitialsBadge extends StatelessWidget {
  const _AccountInitialsBadge({
    required this.width,
    required this.height,
    required this.fontSize,
    required this.borderColor,
    required this.showShadow,
    this.label,
    this.icon,
  });

  final double width;
  final double height;
  final String? label;
  final IconData? icon;
  final double fontSize;
  final Color borderColor;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: VideoFeatureTheme.primaryGradient,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        boxShadow: showShadow ? VideoFeatureTheme.floatingShadow : null,
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: Colors.white, size: fontSize + 8)
            : Text(
                label ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                  letterSpacing: -0.4,
                ),
              ),
      ),
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
    final bool isDark = VideoFeatureTheme.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: VideoFeatureTheme.panelFor(
          context,
        ).withValues(alpha: isDark ? 0.96 : 0.94),
        borderRadius: BorderRadius.circular(isPhone ? 26 : 36),
        border: Border.all(color: VideoFeatureTheme.lineFor(context)),
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
                                gradient: VideoFeatureTheme.heroGradientFor(
                                  context,
                                ),
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
                                foregroundColor: VideoFeatureTheme.inkFor(
                                  context,
                                ),
                                backgroundColor:
                                    VideoFeatureTheme.panelMutedFor(
                                      context,
                                    ).withValues(alpha: 0.45),
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
                        color: VideoFeatureTheme.inkFor(context),
                        size: isPhone ? 28 : 34,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: VideoFeatureTheme.lineFor(context)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isPhone ? 12 : 18,
                  vertical: isPhone ? 10 : 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const _AccountSectionLabel(label: 'Workspace'),
                    _AccountActionTile(
                      label: 'Settings',
                      subtitle: 'Preferences and workspace controls',
                      icon: Icons.settings_outlined,
                      onTap: () =>
                          onActionSelected(HomeAccountMenuAction.settings),
                    ),
                    if (!isGuest)
                      _AccountActionTile(
                        label: 'View profile',
                        subtitle: 'Review your account details',
                        icon: Icons.person_outline_rounded,
                        onTap: () =>
                            onActionSelected(HomeAccountMenuAction.profile),
                      ),
                    if (isGuest)
                      _AccountActionTile(
                        label: 'Login',
                        subtitle: 'Unlock saved account features',
                        icon: Icons.login_rounded,
                        onTap: () =>
                            onActionSelected(HomeAccountMenuAction.login),
                      ),
                    _AccountActionTile(
                      label: 'Guide',
                      subtitle: 'See how recording works in Aks',
                      icon: Icons.play_lesson_outlined,
                      onTap: () =>
                          onActionSelected(HomeAccountMenuAction.guide),
                    ),
                    const SizedBox(height: 10),
                    const _AccountSectionLabel(label: 'Support'),
                    _AccountActionTile(
                      label: 'Help Center',
                      subtitle: 'Troubleshooting and best practices',
                      icon: Icons.help_outline_rounded,
                      onTap: () =>
                          onActionSelected(HomeAccountMenuAction.helpCenter),
                    ),
                    _AccountActionTile(
                      label: 'Privacy Policy',
                      subtitle: 'How recordings and account data are handled',
                      icon: Icons.privacy_tip_outlined,
                      onTap: () =>
                          onActionSelected(HomeAccountMenuAction.privacyPolicy),
                    ),
                    _AccountActionTile(
                      label: 'Terms & Conditions',
                      subtitle: 'Usage and recording responsibility',
                      icon: Icons.gavel_outlined,
                      onTap: () => onActionSelected(
                        HomeAccountMenuAction.termsAndConditions,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: VideoFeatureTheme.lineFor(context)),
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
                    subtitle: 'End this session on the current device',
                    icon: Icons.logout_rounded,
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
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final String subtitle;
  final IconData icon;
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
                ? VideoFeatureTheme.dangerFor(context).withValues(alpha: 0.12)
                : VideoFeatureTheme.panelMutedFor(
                    context,
                  ).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(isPhone ? 18 : 22),
            border: Border.all(
              color: isDestructive
                  ? VideoFeatureTheme.dangerFor(context).withValues(alpha: 0.28)
                  : VideoFeatureTheme.lineFor(context),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: isPhone ? 36 : 40,
                height: isPhone ? 36 : 40,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? VideoFeatureTheme.panelFor(
                          context,
                        ).withValues(alpha: 0.9)
                      : VideoFeatureTheme.panelFor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDestructive
                        ? VideoFeatureTheme.dangerFor(
                            context,
                          ).withValues(alpha: 0.18)
                        : VideoFeatureTheme.lineFor(context),
                  ),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? VideoFeatureTheme.dangerFor(context)
                      : VideoFeatureTheme.accentFor(context),
                  size: isPhone ? 18 : 20,
                ),
              ),
              SizedBox(width: isPhone ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: TextStyle(
                        color: isDestructive
                            ? VideoFeatureTheme.dangerFor(context)
                            : VideoFeatureTheme.inkFor(context),
                        fontSize: isPhone ? 14 : 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDestructive
                            ? VideoFeatureTheme.dangerFor(
                                context,
                              ).withValues(alpha: 0.82)
                            : VideoFeatureTheme.mutedFor(context),
                        fontSize: isPhone ? 12 : 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isDestructive)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: VideoFeatureTheme.mutedFor(context),
                    size: isPhone ? 18 : 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountSectionLabel extends StatelessWidget {
  const _AccountSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      child: Text(
        label,
        style: TextStyle(
          color: VideoFeatureTheme.mutedFor(context),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

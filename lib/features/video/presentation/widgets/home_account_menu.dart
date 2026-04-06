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
    return PopupMenuButton<HomeAccountMenuAction>(
      enabled: !isBusy,
      onSelected: onSelected,
      offset: const Offset(0, 12),
      position: PopupMenuPosition.under,
      tooltip: 'Open account menu',
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 14,
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 320),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: VideoFeatureTheme.line),
      ),
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<HomeAccountMenuAction>>[
            PopupMenuItem<HomeAccountMenuAction>(
              enabled: false,
              height: 88,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: VideoFeatureTheme.primary,
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          user.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: VideoFeatureTheme.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: VideoFeatureTheme.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 10),
            _menuItem(
              value: HomeAccountMenuAction.profile,
              icon: Icons.person_outline_rounded,
              label: 'Profile',
            ),
            // _menuItem(
            //   value: HomeAccountMenuAction.integrations,
            //   icon: Icons.extension_outlined,
            //   label: 'Integrations',
            // ),
            _menuItem(
              value: HomeAccountMenuAction.settings,
              icon: Icons.settings_outlined,
              label: 'Settings',
            ),
            _menuItem(
              value: HomeAccountMenuAction.guide,
              icon: Icons.description_outlined,
              label: 'Guide',
            ),
            const PopupMenuDivider(height: 10),
            _menuItem(
              value: HomeAccountMenuAction.helpCenter,
              icon: Icons.help_outline_rounded,
              label: 'Help Center',
            ),
            _menuItem(
              value: HomeAccountMenuAction.privacyPolicy,
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
            ),
            _menuItem(
              value: HomeAccountMenuAction.termsAndConditions,
              icon: Icons.gavel_outlined,
              label: 'Terms & Conditions',
            ),
            const PopupMenuDivider(height: 10),
            _menuItem(
              value: HomeAccountMenuAction.signOut,
              icon: Icons.logout_rounded,
              label: isBusy ? 'Signing out...' : 'Logout',
            ),
          ],
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
              fontSize: 28,
              letterSpacing: -0.6,
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<HomeAccountMenuAction> _menuItem({
    required HomeAccountMenuAction value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<HomeAccountMenuAction>(
      value: value,
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: <Widget>[
          Icon(icon, color: VideoFeatureTheme.ink, size: 26),
          const SizedBox(width: 18),
          Text(
            label,
            style: const TextStyle(
              color: VideoFeatureTheme.ink,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

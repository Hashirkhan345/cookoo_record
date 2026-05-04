import 'package:flutter/material.dart';

import '../../../auth/data/models/app_user.dart';
import '../controller/video_feature_theme.dart';
import 'home_account_menu.dart';

enum _SidebarSelection { profile, record }

class HomeSidebar extends StatefulWidget {
  const HomeSidebar({
    super.key,
    required this.minHeight,
    required this.onStartRecording,
    required this.recordedCount,
    required this.recordingLimit,
    required this.onOpenAccountMenu,
    required this.onUpgrade,
    this.user,
  });

  final double minHeight;
  final VoidCallback onStartRecording;
  final int recordedCount;
  final int recordingLimit;
  final VoidCallback onOpenAccountMenu;
  final VoidCallback onUpgrade;
  final AppUser? user;

  @override
  State<HomeSidebar> createState() => _HomeSidebarState();
}

class _HomeSidebarState extends State<HomeSidebar> {
  _SidebarSelection? _selectedTile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 212,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: _SidebarPanel(
          recordedCount: widget.recordedCount,
          recordingLimit: widget.recordingLimit,
          user: widget.user,
          selectedTile: _selectedTile,
          onSelectProfile: () {
            setState(() => _selectedTile = _SidebarSelection.profile);
            widget.onOpenAccountMenu();
          },
          onStartRecording: () {
            setState(() => _selectedTile = _SidebarSelection.record);
            widget.onStartRecording();
          },
          onUpgrade: widget.onUpgrade,
        ),
      ),
    );
  }
}

class _SidebarPanel extends StatelessWidget {
  const _SidebarPanel({
    required this.recordedCount,
    required this.recordingLimit,
    required this.user,
    required this.selectedTile,
    required this.onSelectProfile,
    required this.onStartRecording,
    required this.onUpgrade,
  });

  final int recordedCount;
  final int recordingLimit;
  final AppUser? user;
  final _SidebarSelection? selectedTile;
  final VoidCallback onSelectProfile;
  final VoidCallback onStartRecording;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final int safeLimit = recordingLimit <= 0 ? 1 : recordingLimit;
    final int safeCount = recordedCount.clamp(0, safeLimit);
    final bool nearingLimit = safeCount >= (safeLimit * 0.8).round();
    final Color selectedBackground = VideoFeatureTheme.accentSoft.withValues(
      alpha: 0.9,
    );
    final Color unselectedBackground = VideoFeatureTheme.panelMutedFor(context);
    final String? userInitials = user?.initials.trim();
    final bool hasUser = userInitials != null && userInitials.isNotEmpty;

    return Container(
      width: 202,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: VideoFeatureTheme.panelFor(context).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: VideoFeatureTheme.lineFor(context)),
        boxShadow: VideoFeatureTheme.panelShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SidebarInfoTile(
            backgroundColor: selectedTile == _SidebarSelection.profile
                ? selectedBackground
                : unselectedBackground,
            foregroundColor: selectedTile == _SidebarSelection.profile
                ? VideoFeatureTheme.primaryDeep
                : VideoFeatureTheme.inkFor(context),
            icon: null,
            leading: _SidebarProfileBadge(
              initials: hasUser ? userInitials : null,
            ),
            label: hasUser ? userInitials : 'Profile',
            onTap: onSelectProfile,
          ),
          const SizedBox(height: 10),
          _SidebarInfoTile(
            backgroundColor: selectedTile == _SidebarSelection.record
                ? selectedBackground
                : unselectedBackground,
            foregroundColor: selectedTile == _SidebarSelection.record
                ? VideoFeatureTheme.primaryDeep
                : VideoFeatureTheme.inkFor(context),
            icon: Icons.videocam_rounded,
            label: 'Record',
            onTap: onStartRecording,
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            thickness: 1,
            color: VideoFeatureTheme.lineFor(context),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'Usage',
              style: TextStyle(
                color: VideoFeatureTheme.mutedFor(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _UsageRow(
            countLabel: '$safeCount/$safeLimit',
            isHighlighted: nearingLimit,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: VideoFeatureTheme.panelMutedFor(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Need more recordings?',
                  style: TextStyle(
                    color: VideoFeatureTheme.inkFor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Upgrade your plan to unlock more recording capacity.',
                  style: TextStyle(
                    color: VideoFeatureTheme.mutedFor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: FilledButton(
                    onPressed: onUpgrade,
                    style: FilledButton.styleFrom(
                      backgroundColor: VideoFeatureTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const FittedBox(child: Text('Upgrade')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarProfileBadge extends StatelessWidget {
  const _SidebarProfileBadge({required this.initials});

  final String? initials;

  @override
  Widget build(BuildContext context) {
    final String? safeInitials = initials?.trim();
    if (safeInitials != null && safeInitials.isNotEmpty) {
      return AccountInitialsBadge(label: safeInitials, size: 44, fontSize: 17);
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: VideoFeatureTheme.panelFor(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VideoFeatureTheme.lineFor(context)),
      ),
      child: Icon(
        Icons.person_outline_rounded,
        color: VideoFeatureTheme.inkFor(context),
        size: 24,
      ),
    );
  }
}

class _SidebarInfoTile extends StatelessWidget {
  const _SidebarInfoTile({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    required this.onTap,
    this.leading,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: 10),
          ] else if (icon != null) ...<Widget>[
            Icon(icon, size: 22, color: foregroundColor),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: content,
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.countLabel, required this.isHighlighted});

  final String countLabel;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isHighlighted
            ? VideoFeatureTheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.video_collection_outlined,
            size: 20,
            color: isHighlighted
                ? VideoFeatureTheme.primary
                : VideoFeatureTheme.inkFor(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              countLabel,
              style: TextStyle(
                color: VideoFeatureTheme.inkFor(context),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

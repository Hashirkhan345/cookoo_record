import 'package:flutter/material.dart';

import '../controller/video_feature_theme.dart';

class HomeSidebar extends StatelessWidget {
  const HomeSidebar({super.key, this.accountMenu});

  final Widget? accountMenu;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child:
                accountMenu ??
                const _SidebarAction(
                  icon: Icons.account_circle_outlined,
                  label: 'You',
                  selected: true,
                ),
          ),
        ),
        const Spacer(),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SidebarAction extends StatelessWidget {
  const _SidebarAction({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VideoFeatureTheme.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: VideoFeatureTheme.ink, size: 30),
          if (label.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: VideoFeatureTheme.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

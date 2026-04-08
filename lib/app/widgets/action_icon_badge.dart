import 'package:flutter/material.dart';

class ActionIconBadge extends StatelessWidget {
  const ActionIconBadge({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.size = 30,
    this.iconSize = 16,
    this.borderColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;
  final double iconSize;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Icon(icon, size: iconSize, color: foregroundColor),
    );
  }
}

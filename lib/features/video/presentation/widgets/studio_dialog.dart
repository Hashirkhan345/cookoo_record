import 'package:flutter/material.dart';

import '../controller/video_feature_theme.dart';

Future<T?> showStudioDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: const Color(0x730B1326),
    builder: builder,
  );
}

class StudioDialogShell extends StatelessWidget {
  const StudioDialogShell({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.badge,
    this.content,
    this.actions,
    this.maxWidth = 760,
    this.showCloseButton = true,
    this.onClose,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final String? badge;
  final Widget? content;
  final Widget? actions;
  final double maxWidth;
  final bool showCloseButton;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final bool isCompact = screenSize.width < 600;
    final double horizontalInset = isCompact ? 14 : 24;
    final double verticalInset = isCompact ? 18 : 28;
    final double dialogRadius = isCompact ? 24 : 34;
    final double shellPadding = isCompact ? 18 : 28;
    final double titleSize = isCompact ? 20 : 24;
    final double messageSize = isCompact ? 14 : 15;
    final double iconBoxSize = isCompact ? 44 : 52;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalInset,
        vertical: verticalInset,
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isCompact
              ? screenSize.width - (horizontalInset * 2)
              : maxWidth,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(dialogRadius),
          child: Material(
            color: VideoFeatureTheme.panel,
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: isCompact ? -24 : -34,
                  right: isCompact ? -12 : -18,
                  child: Container(
                    width: isCompact ? 108 : 170,
                    height: isCompact ? 108 : 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VideoFeatureTheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  left: isCompact ? -26 : -40,
                  bottom: isCompact ? -34 : -52,
                  child: Container(
                    width: isCompact ? 110 : 160,
                    height: isCompact ? 110 : 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VideoFeatureTheme.focus.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(dialogRadius),
                    border: Border.all(color: VideoFeatureTheme.line),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x1A1A262D),
                        blurRadius: 36,
                        offset: Offset(0, 22),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(
                    shellPadding,
                    isCompact ? 18 : 26,
                    shellPadding,
                    shellPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (icon != null) ...<Widget>[
                            Container(
                              width: iconBoxSize,
                              height: iconBoxSize,
                              decoration: BoxDecoration(
                                gradient: VideoFeatureTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(
                                  isCompact ? 14 : 18,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: Colors.white,
                                size: isCompact ? 20 : 24,
                              ),
                            ),
                            SizedBox(width: isCompact ? 12 : 16),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                if (badge != null) ...<Widget>[
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isCompact ? 10 : 12,
                                      vertical: isCompact ? 6 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: VideoFeatureTheme.accentSoft,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      badge!,
                                      style: const TextStyle(
                                        color: VideoFeatureTheme.accent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.25,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 10 : 14),
                                ],
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: VideoFeatureTheme.ink,
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w800,
                                    height: 1.12,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                if (message != null) ...<Widget>[
                                  SizedBox(height: isCompact ? 10 : 12),
                                  Text(
                                    message!,
                                    style: TextStyle(
                                      color: VideoFeatureTheme.muted,
                                      fontSize: messageSize,
                                      height: 1.55,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (showCloseButton) ...<Widget>[
                            SizedBox(width: isCompact ? 10 : 14),
                            _DialogCloseButton(
                              compact: isCompact,
                              onPressed:
                                  onClose ?? () => Navigator.of(context).pop(),
                            ),
                          ],
                        ],
                      ),
                      if (content != null) ...<Widget>[
                        SizedBox(height: isCompact ? 18 : 24),
                        content!,
                      ],
                      if (actions != null) ...<Widget>[
                        SizedBox(height: isCompact ? 18 : 24),
                        actions!,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogCloseButton extends StatelessWidget {
  const _DialogCloseButton({required this.onPressed, required this.compact});

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        child: Container(
          width: compact ? 40 : 46,
          height: compact ? 40 : 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
            border: Border.all(color: VideoFeatureTheme.line),
          ),
          child: Icon(
            Icons.close_rounded,
            color: VideoFeatureTheme.ink,
            size: compact ? 20 : 24,
          ),
        ),
      ),
    );
  }
}

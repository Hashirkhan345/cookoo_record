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
    this.centerHeader = false,
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
  final bool centerHeader;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final bool isCompact = screenSize.width < 600;
    final bool isDark = VideoFeatureTheme.isDark(context);
    final double horizontalInset = isCompact ? 14 : 24;
    final double verticalInset = isCompact ? 18 : 28;
    final double dialogRadius = isCompact ? 24 : 34;
    final double shellPadding = isCompact ? 18 : 28;
    final double titleSize = isCompact ? 20 : 24;
    final double messageSize = isCompact ? 14 : 15;
    final double iconBoxSize = isCompact ? 44 : 52;
    final double closeButtonSlotWidth = isCompact ? 54 : 68;

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
            color: VideoFeatureTheme.panelFor(context),
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
                    border: Border.all(
                      color: VideoFeatureTheme.lineFor(context),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: isDark
                            ? const Color(0x5A020308)
                            : const Color(0x1A1A262D),
                        blurRadius: 36,
                        offset: const Offset(0, 22),
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
                      if (centerHeader)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                SizedBox(
                                  width: showCloseButton
                                      ? closeButtonSlotWidth
                                      : 0,
                                ),
                                Expanded(
                                  child: Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: VideoFeatureTheme.inkFor(context),
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w800,
                                      height: 1.12,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: showCloseButton
                                      ? closeButtonSlotWidth
                                      : 0,
                                  child: showCloseButton
                                      ? Align(
                                          alignment: Alignment.centerRight,
                                          child: _DialogCloseButton(
                                            compact: isCompact,
                                            onPressed:
                                                onClose ??
                                                () =>
                                                    Navigator.of(context).pop(),
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                            if (message != null) ...<Widget>[
                              SizedBox(height: isCompact ? 10 : 12),
                              Text(
                                message!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: VideoFeatureTheme.mutedFor(context),
                                  fontSize: messageSize,
                                  height: 1.55,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        )
                      else
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
                              child: _DialogHeaderContent(
                                badge: badge,
                                title: title,
                                message: message,
                                compact: isCompact,
                                titleSize: titleSize,
                                messageSize: messageSize,
                              ),
                            ),
                            if (showCloseButton) ...<Widget>[
                              SizedBox(width: isCompact ? 10 : 14),
                              _DialogCloseButton(
                                compact: isCompact,
                                onPressed:
                                    onClose ??
                                    () => Navigator.of(context).pop(),
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

class _DialogHeaderContent extends StatelessWidget {
  const _DialogHeaderContent({
    required this.title,
    required this.compact,
    required this.titleSize,
    required this.messageSize,
    this.badge,
    this.message,
    this.centerAligned = false,
  });

  final String title;
  final String? badge;
  final String? message;
  final bool compact;
  final double titleSize;
  final double messageSize;
  final bool centerAligned;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centerAligned
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        if (badge != null) ...<Widget>[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: VideoFeatureTheme.accentSoftFor(context),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge!,
              style: TextStyle(
                color: VideoFeatureTheme.accentFor(context),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.25,
              ),
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
        ],
        Text(
          title,
          textAlign: centerAligned ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: VideoFeatureTheme.inkFor(context),
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: -0.8,
          ),
        ),
        if (message != null) ...<Widget>[
          SizedBox(height: compact ? 10 : 12),
          Text(
            message!,
            textAlign: centerAligned ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: VideoFeatureTheme.mutedFor(context),
              fontSize: messageSize,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
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
            color: VideoFeatureTheme.panelFor(context).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
            border: Border.all(color: VideoFeatureTheme.lineFor(context)),
          ),
          child: Icon(
            Icons.close_rounded,
            color: VideoFeatureTheme.inkFor(context),
            size: compact ? 20 : 24,
          ),
        ),
      ),
    );
  }
}

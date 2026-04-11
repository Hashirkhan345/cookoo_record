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
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Material(
            color: VideoFeatureTheme.panel,
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: -34,
                  right: -18,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VideoFeatureTheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  left: -40,
                  bottom: -52,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VideoFeatureTheme.focus.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: VideoFeatureTheme.line),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x1A1A262D),
                        blurRadius: 36,
                        offset: Offset(0, 22),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (icon != null) ...<Widget>[
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: VideoFeatureTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(icon, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                if (badge != null) ...<Widget>[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
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
                                  const SizedBox(height: 14),
                                ],
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: VideoFeatureTheme.ink,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    height: 1.12,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                if (message != null) ...<Widget>[
                                  const SizedBox(height: 12),
                                  Text(
                                    message!,
                                    style: const TextStyle(
                                      color: VideoFeatureTheme.muted,
                                      fontSize: 15,
                                      height: 1.55,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (showCloseButton) ...<Widget>[
                            const SizedBox(width: 14),
                            _DialogCloseButton(
                              onPressed:
                                  onClose ?? () => Navigator.of(context).pop(),
                            ),
                          ],
                        ],
                      ),
                      if (content != null) ...<Widget>[
                        const SizedBox(height: 24),
                        content!,
                      ],
                      if (actions != null) ...<Widget>[
                        const SizedBox(height: 24),
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
  const _DialogCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: VideoFeatureTheme.line),
          ),
          child: const Icon(
            Icons.close_rounded,
            color: VideoFeatureTheme.ink,
            size: 24,
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/widgets/action_icon_badge.dart';
import '../../../auth/data/models/app_user.dart';
import '../../data/models/saved_video_recording_model.dart';
import '../controller/saved_recording_player_controller_factory.dart';
import '../controller/saved_recording_transfer.dart';
import '../controller/video_feature_theme.dart';
import 'saved_recording_player.dart';

enum _RecordingCardMenuAction { openPlayer, share, download, delete }

class SavedRecordingCard extends StatefulWidget {
  const SavedRecordingCard({
    super.key,
    required this.recording,
    required this.onDelete,
    this.currentUser,
  });

  final SavedVideoRecordingModel recording;
  final VoidCallback onDelete;
  final AppUser? currentUser;

  @override
  State<SavedRecordingCard> createState() => _SavedRecordingCardState();
}

class _SavedRecordingCardState extends State<SavedRecordingCard> {
  bool _isProcessingTransfer = false;

  @override
  Widget build(BuildContext context) {
    final SavedVideoRecordingModel recording = widget.recording;
    final bool isPhone = MediaQuery.sizeOf(context).width < 600;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: VideoFeatureTheme.panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: VideoFeatureTheme.line),
        boxShadow: VideoFeatureTheme.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
              isPhone ? 10 : 12,
              isPhone ? 10 : 12,
              isPhone ? 10 : 12,
              0,
            ),
            child: _SavedRecordingPreviewTile(
              recording: recording,
              durationLabel: _formatDuration(recording.duration),
              isBusy: _isProcessingTransfer,
              onTap: _openPlayer,
              onSelectedAction: _handleMenuAction,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isPhone ? 14 : 16,
              isPhone ? 12 : 16,
              isPhone ? 14 : 16,
              isPhone ? 14 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _OwnerAvatar(user: widget.currentUser),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.currentUser?.name ?? 'You',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: VideoFeatureTheme.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatRelativeSavedAt(recording.savedAt),
                            style: const TextStyle(
                              color: VideoFeatureTheme.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isPhone ? 12 : 16),
                Text(
                  _displayTitle(recording),
                  maxLines: isPhone ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: VideoFeatureTheme.ink,
                    fontSize: isPhone ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    height: 1.16,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: isPhone ? 4 : 6),
                Text(
                  '${_formatSavedAt(recording.savedAt)} • ${_formatBytes(recording.sizeInBytes)}',
                  maxLines: isPhone ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: VideoFeatureTheme.muted,
                    fontSize: isPhone ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    height: isPhone ? 1.35 : 1.2,
                  ),
                ),
                SizedBox(height: isPhone ? 12 : 14),
                if (isPhone)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      FilledButton.icon(
                        key: Key('playRecordingButton_${recording.id}'),
                        onPressed: _openPlayer,
                        icon: const ActionIconBadge(
                          icon: Symbols.play_arrow_rounded,
                          backgroundColor: Color(0x33FFFFFF),
                          foregroundColor: Colors.white,
                          size: 28,
                          iconSize: 16,
                        ),
                        label: const Text('Watch recording'),
                        style: FilledButton.styleFrom(
                          backgroundColor: VideoFeatureTheme.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _isProcessingTransfer
                            ? null
                            : () => _handleRecordingAction(
                                downloadSavedRecording,
                              ),
                        icon: const ActionIconBadge(
                          icon: Symbols.download_rounded,
                          backgroundColor: Color(0xFFEAF1FF),
                          foregroundColor: VideoFeatureTheme.primary,
                          size: 28,
                          iconSize: 16,
                        ),
                        label: const Text('Download'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: VideoFeatureTheme.ink,
                          backgroundColor: VideoFeatureTheme.panelMuted
                              .withValues(alpha: 0.36),
                          side: const BorderSide(color: VideoFeatureTheme.line),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.icon(
                          key: Key('playRecordingButton_${recording.id}'),
                          onPressed: _openPlayer,
                          icon: const ActionIconBadge(
                            icon: Symbols.play_arrow_rounded,
                            backgroundColor: Color(0x33FFFFFF),
                            foregroundColor: Colors.white,
                            size: 28,
                            iconSize: 16,
                          ),
                          label: const Text('Watch recording'),
                          style: FilledButton.styleFrom(
                            backgroundColor: VideoFeatureTheme.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isProcessingTransfer
                              ? null
                              : () => _handleRecordingAction(
                                  downloadSavedRecording,
                                ),
                          icon: const ActionIconBadge(
                            icon: Symbols.download_rounded,
                            backgroundColor: Color(0xFFEAF1FF),
                            foregroundColor: VideoFeatureTheme.primary,
                            size: 28,
                            iconSize: 16,
                          ),
                          label: const Text('Download'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: VideoFeatureTheme.ink,
                            backgroundColor: VideoFeatureTheme.panelMuted
                                .withValues(alpha: 0.36),
                            side: const BorderSide(
                              color: VideoFeatureTheme.line,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPlayer() {
    return SavedRecordingPlayer.showFullscreenDialog(
      context,
      recording: widget.recording,
      autoplayMuted: false,
    );
  }

  Future<void> _handleMenuAction(_RecordingCardMenuAction action) async {
    switch (action) {
      case _RecordingCardMenuAction.openPlayer:
        await _openPlayer();
        return;
      case _RecordingCardMenuAction.share:
        await _handleRecordingAction(shareSavedRecording);
        return;
      case _RecordingCardMenuAction.download:
        await _handleRecordingAction(downloadSavedRecording);
        return;
      case _RecordingCardMenuAction.delete:
        widget.onDelete();
        return;
    }
  }

  Future<void> _handleRecordingAction(
    Future<String> Function(SavedVideoRecordingModel recording) action,
  ) async {
    if (_isProcessingTransfer) {
      return;
    }

    setState(() {
      _isProcessingTransfer = true;
    });

    try {
      final String message = await action(widget.recording);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingTransfer = false;
        });
      }
    }
  }

  String _displayTitle(SavedVideoRecordingModel recording) {
    final String rawTitle = recording.fileName.replaceFirst(
      RegExp(r'\.[^.]+$'),
      '',
    );
    final String cleanedTitle = rawTitle
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (RegExp(
      r'^recording\s+\d+$',
      caseSensitive: false,
    ).hasMatch(cleanedTitle)) {
      return 'bloop recording • ${_formatLongDate(recording.savedAt)}';
    }

    if (cleanedTitle.isEmpty) {
      return 'bloop recording';
    }

    return cleanedTitle;
  }

  String _formatDuration(Duration duration) {
    final String minutes = duration.inMinutes.toString().padLeft(2, '0');
    final String seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatSavedAt(DateTime savedAt) {
    final String month = _monthLabel(savedAt.month);
    final String day = savedAt.day.toString().padLeft(2, '0');
    final int hour = savedAt.hour == 0
        ? 12
        : (savedAt.hour > 12 ? savedAt.hour - 12 : savedAt.hour);
    final String minute = savedAt.minute.toString().padLeft(2, '0');
    final String meridiem = savedAt.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $hour:$minute $meridiem';
  }

  String _formatLongDate(DateTime savedAt) {
    return '${savedAt.day} ${_monthLabel(savedAt.month)} ${savedAt.year}';
  }

  String _formatRelativeSavedAt(DateTime savedAt) {
    final Duration difference = DateTime.now().difference(savedAt);

    if (difference.inSeconds < 45) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      final int minutes = difference.inMinutes;
      return '$minutes min${minutes == 1 ? '' : 's'} ago';
    }
    if (difference.inHours < 24) {
      final int hours = difference.inHours;
      return '$hours hr${hours == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 7) {
      final int days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    }

    return _formatSavedAt(savedAt);
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  String _monthLabel(int month) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _SavedRecordingPreviewTile extends StatelessWidget {
  const _SavedRecordingPreviewTile({
    required this.recording,
    required this.durationLabel,
    required this.isBusy,
    required this.onTap,
    required this.onSelectedAction,
  });

  final SavedVideoRecordingModel recording;
  final String durationLabel;
  final bool isBusy;
  final VoidCallback onTap;
  final ValueChanged<_RecordingCardMenuAction> onSelectedAction;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.sizeOf(context).width < 600;
    return ClipRRect(
      borderRadius: BorderRadius.circular(isPhone ? 20 : 24),
      child: AspectRatio(
        aspectRatio: isPhone ? 1.18 : 1.34,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: _SavedRecordingThumbnail(recording: recording),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withValues(alpha: 0.08),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.24),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: isPhone ? 10 : 14,
                  left: isPhone ? 10 : 14,
                  child: _PreviewLabel(
                    icon: Icons.bookmark_rounded,
                    label: 'Saved',
                  ),
                ),
                Positioned(
                  top: isPhone ? 10 : 14,
                  right: isPhone ? 10 : 14,
                  child: _PreviewMenuButton(
                    isBusy: isBusy,
                    onSelected: onSelectedAction,
                  ),
                ),
                Positioned(
                  left: isPhone ? 10 : 16,
                  right: isPhone ? 10 : 16,
                  bottom: isPhone ? 10 : 16,
                  child: Row(
                    children: <Widget>[
                      Expanded(child: _PreviewActionPill(onTap: onTap)),
                      SizedBox(width: isPhone ? 8 : 12),
                      _PreviewDurationBadge(label: durationLabel),
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

class _SavedRecordingThumbnail extends StatefulWidget {
  const _SavedRecordingThumbnail({required this.recording});

  final SavedVideoRecordingModel recording;

  @override
  State<_SavedRecordingThumbnail> createState() =>
      _SavedRecordingThumbnailState();
}

class _SavedRecordingThumbnailState extends State<_SavedRecordingThumbnail> {
  VideoPlayerController? _controller;
  Future<void>? _initialization;
  Object? _initializationError;

  bool get _usesLivePreview {
    if (kIsWeb) {
      return true;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return false;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return true;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant _SavedRecordingThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recording.id != widget.recording.id ||
        oldWidget.recording.playbackPath != widget.recording.playbackPath) {
      _disposeController();
      _initializeController();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _initializeController() {
    if (!_usesLivePreview) {
      _disposeController();
      return;
    }

    final VideoPlayerController controller =
        createSavedRecordingPlayerController(widget.recording);

    _controller = controller;
    _initializationError = null;

    _initialization = controller
        .initialize()
        .then((_) async {
          await controller.setLooping(true);
          await controller.setVolume(0);
          await controller.play();
          if (mounted) {
            setState(() {});
          }
        })
        .catchError((Object error) {
          _initializationError = error;
          if (mounted) {
            setState(() {});
          }
        });
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _initialization = null;
    _initializationError = null;
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? controller = _controller;
    final Future<void>? initialization = _initialization;

    if (!_usesLivePreview) {
      return const _SavedRecordingThumbnailFallback();
    }

    if (controller == null || initialization == null) {
      return const _SavedRecordingThumbnailFallback();
    }

    return FutureBuilder<void>(
      future: initialization,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        final bool isReady =
            snapshot.connectionState == ConnectionState.done &&
            _initializationError == null &&
            controller.value.isInitialized;

        if (isReady) {
          final Size videoSize = controller.value.size;
          final double videoWidth = videoSize.width <= 0 ? 16 : videoSize.width;
          final double videoHeight = videoSize.height <= 0
              ? 9
              : videoSize.height;

          return ColoredBox(
            color: Colors.black,
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: videoWidth,
                height: videoHeight,
                child: IgnorePointer(child: VideoPlayer(controller)),
              ),
            ),
          );
        }

        return const _SavedRecordingThumbnailFallback();
      },
    );
  }
}

class _SavedRecordingThumbnailFallback extends StatelessWidget {
  const _SavedRecordingThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            VideoFeatureTheme.primaryDeep,
            VideoFeatureTheme.primary,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.video_library_rounded,
          color: Colors.white70,
          size: 40,
        ),
      ),
    );
  }
}

class _PreviewMenuButton extends StatelessWidget {
  const _PreviewMenuButton({required this.isBusy, required this.onSelected});

  final bool isBusy;
  final ValueChanged<_RecordingCardMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_RecordingCardMenuAction>(
      enabled: !isBusy,
      tooltip: 'Recording actions',
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 16,
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<_RecordingCardMenuAction>>[
            const PopupMenuItem<_RecordingCardMenuAction>(
              value: _RecordingCardMenuAction.openPlayer,
              child: _MenuActionLabel(
                icon: Symbols.play_circle_rounded,
                label: 'Watch recording',
              ),
            ),
            const PopupMenuItem<_RecordingCardMenuAction>(
              value: _RecordingCardMenuAction.share,
              child: _MenuActionLabel(
                icon: Symbols.share_rounded,
                label: 'Share',
              ),
            ),
            const PopupMenuItem<_RecordingCardMenuAction>(
              value: _RecordingCardMenuAction.download,
              child: _MenuActionLabel(
                icon: Symbols.download_rounded,
                label: 'Download',
              ),
            ),
            const PopupMenuDivider(height: 10),
            const PopupMenuItem<_RecordingCardMenuAction>(
              value: _RecordingCardMenuAction.delete,
              child: _MenuActionLabel(
                icon: Symbols.delete_sharp,
                label: 'Delete',
                isDestructive: true,
              ),
            ),
          ],
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: VideoFeatureTheme.ink.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          color: isBusy ? Colors.white38 : Colors.white,
          size: 24,
        ),
      ),
    );
  }
}

class _PreviewLabel extends StatelessWidget {
  const _PreviewLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: VideoFeatureTheme.ink.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewActionPill extends StatelessWidget {
  const _PreviewActionPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Watch recording',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: VideoFeatureTheme.ink.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const ActionIconBadge(
                  icon: Symbols.play_arrow_rounded,
                  backgroundColor: Color(0x33FFFFFF),
                  foregroundColor: Colors.white,
                  size: 26,
                  iconSize: 14,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Watch recording',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _MenuActionLabel extends StatelessWidget {
  const _MenuActionLabel({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isDestructive
        ? VideoFeatureTheme.danger
        : VideoFeatureTheme.ink;

    return Row(
      children: <Widget>[
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: iconColor,
            fontWeight: isDestructive ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PreviewDurationBadge extends StatelessWidget {
  const _PreviewDurationBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: VideoFeatureTheme.ink.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OwnerAvatar extends StatefulWidget {
  const _OwnerAvatar({this.user});

  final AppUser? user;

  @override
  State<_OwnerAvatar> createState() => _OwnerAvatarState();
}

class _OwnerAvatarState extends State<_OwnerAvatar> {
  bool _hidePhoto = false;

  @override
  void didUpdateWidget(covariant _OwnerAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? previousPhotoUrl = oldWidget.user?.photoUrl?.trim();
    final String? nextPhotoUrl = widget.user?.photoUrl?.trim();
    if (previousPhotoUrl != nextPhotoUrl && _hidePhoto) {
      _hidePhoto = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? photoUrl = widget.user?.photoUrl?.trim();
    if (photoUrl == null || photoUrl.isEmpty || _hidePhoto) {
      return SizedBox(
        width: 40,
        height: 40,
        child: _FallbackOwnerAvatar(initials: widget.user?.initials ?? 'B'),
      );
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _FallbackOwnerAvatar(initials: widget.user?.initials ?? 'B'),
            Image.network(
              photoUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    if (!_hidePhoto) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _hidePhoto = true;
                          });
                        }
                      });
                    }
                    return const SizedBox.shrink();
                  },
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackOwnerAvatar extends StatelessWidget {
  const _FallbackOwnerAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: VideoFeatureTheme.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../auth/data/models/app_user.dart';
import '../../data/models/admin_config_model.dart';
import '../../data/models/saved_video_recording_model.dart';
import '../controller/video_feature_theme.dart';
import 'saved_recording_player.dart';
import 'saved_recording_card.dart';

class SavedRecordingsSection extends StatefulWidget {
  const SavedRecordingsSection({
    super.key,
    required this.recordings,
    required this.currentUser,
    required this.adminConfig,
    required this.savedCountLabel,
    required this.onRenameRecording,
    required this.onDeleteRecording,
    required this.onStartRecording,
  });

  final List<SavedVideoRecordingModel> recordings;
  final AppUser? currentUser;
  final AdminConfigModel? adminConfig;
  final String savedCountLabel;
  final Future<void> Function(SavedVideoRecordingModel recording, String title)
  onRenameRecording;
  final ValueChanged<SavedVideoRecordingModel> onDeleteRecording;
  final VoidCallback? onStartRecording;

  @override
  State<SavedRecordingsSection> createState() => _SavedRecordingsSectionState();
}

class _SavedRecordingsSectionState extends State<SavedRecordingsSection> {
  int _preferredColumnCount = 3;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = VideoFeatureTheme.isDark(context);

    final List<SavedVideoRecordingModel> sortedRecordings =
        widget.recordings.toList()..sort(
          (SavedVideoRecordingModel a, SavedVideoRecordingModel b) =>
              b.savedAt.compareTo(a.savedAt),
        );

    if (sortedRecordings.isEmpty) {
      return EmptySavedRecordingsExperience(
        key: const Key('emptySavedRecordingsState'),
        config: widget.adminConfig ?? AdminConfigModel.defaults,
        onStartRecording: widget.onStartRecording,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1240),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: VideoFeatureTheme.panelFor(
            context,
          ).withValues(alpha: isDark ? 0.92 : 0.88),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: VideoFeatureTheme.lineFor(context)),
          boxShadow: VideoFeatureTheme.panelShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool stackHeader = constraints.maxWidth < 700;
                final Widget heading = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Library',
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Review, replay, and export every recording from one place.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: VideoFeatureTheme.mutedFor(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                );

                final Widget actions = Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: <Widget>[
                    if (constraints.maxWidth >= 760)
                      _GridLayoutToggle(
                        selectedColumnCount: _preferredColumnCount,
                        supportsThreeColumns: constraints.maxWidth >= 1080,
                        onSelected: (int value) {
                          setState(() {
                            _preferredColumnCount = value;
                          });
                        },
                      ),
                    _SavedCountChip(label: widget.savedCountLabel),
                    if (widget.onStartRecording != null)
                      FilledButton.icon(
                        onPressed: widget.onStartRecording,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('New recording'),
                        style: FilledButton.styleFrom(
                          backgroundColor: VideoFeatureTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                  ],
                );

                if (stackHeader) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      heading,
                      const SizedBox(height: 16),
                      actions,
                    ],
                  );
                }

                return Row(
                  children: <Widget>[
                    Expanded(child: heading),
                    const SizedBox(width: 16),
                    actions,
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const double spacing = 22;
                final int maxColumns = constraints.maxWidth >= 1080
                    ? 3
                    : constraints.maxWidth >= 760
                    ? 2
                    : 1;
                final int columnCount = _preferredColumnCount.clamp(
                  1,
                  maxColumns,
                );
                double cardWidth =
                    (constraints.maxWidth - (spacing * (columnCount - 1))) /
                    columnCount;

                if (columnCount == 1) {
                  cardWidth = cardWidth.clamp(0, 420);
                }

                return Wrap(
                  alignment: columnCount == 1
                      ? WrapAlignment.center
                      : WrapAlignment.start,
                  spacing: spacing,
                  runSpacing: spacing,
                  children: sortedRecordings
                      .map((SavedVideoRecordingModel recording) {
                        return SizedBox(
                          width: cardWidth,
                          child: SavedRecordingCard(
                            key: Key('savedRecordingCard_${recording.id}'),
                            recording: recording,
                            currentUser: widget.currentUser,
                            onRename: (String title) =>
                                widget.onRenameRecording(recording, title),
                            onDelete: () => widget.onDeleteRecording(recording),
                          ),
                        );
                      })
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GridLayoutToggle extends StatelessWidget {
  const _GridLayoutToggle({
    required this.selectedColumnCount,
    required this.supportsThreeColumns,
    required this.onSelected,
  });

  final int selectedColumnCount;
  final bool supportsThreeColumns;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: VideoFeatureTheme.panelFor(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VideoFeatureTheme.lineFor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _GridLayoutOption(
            label: '2',
            icon: Icons.grid_view_rounded,
            isSelected: selectedColumnCount == 2,
            onTap: () => onSelected(2),
          ),
          const SizedBox(width: 6),
          _GridLayoutOption(
            label: '3',
            icon: Icons.view_comfy_alt_rounded,
            isSelected: selectedColumnCount == 3,
            isEnabled: supportsThreeColumns,
            onTap: supportsThreeColumns ? () => onSelected(3) : null,
          ),
        ],
      ),
    );
  }
}

class _GridLayoutOption extends StatelessWidget {
  const _GridLayoutOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isEnabled = true,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = !isEnabled
        ? VideoFeatureTheme.mutedFor(context).withValues(alpha: 0.5)
        : isSelected
        ? Colors.white
        : VideoFeatureTheme.inkFor(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? VideoFeatureTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: foregroundColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedCountChip extends StatelessWidget {
  const _SavedCountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: VideoFeatureTheme.panelFor(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VideoFeatureTheme.lineFor(context)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: VideoFeatureTheme.inkFor(context),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class EmptySavedRecordingsExperience extends StatelessWidget {
  const EmptySavedRecordingsExperience({
    super.key,
    required this.config,
    required this.onStartRecording,
  });

  final AdminConfigModel config;
  final VoidCallback? onStartRecording;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 780;
    final bool isPhone = MediaQuery.sizeOf(context).width < 520;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = VideoFeatureTheme.isDark(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          compact ? 18 : 28,
          compact ? 20 : 28,
          compact ? 18 : 28,
          compact ? 22 : 30,
        ),
        decoration: BoxDecoration(
          color: VideoFeatureTheme.panelFor(
            context,
          ).withValues(alpha: isDark ? 0.94 : 0.9),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: VideoFeatureTheme.lineFor(context)),
          boxShadow: VideoFeatureTheme.panelShadow,
        ),
        child: Column(
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Column(
                children: <Widget>[
                  // Container(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 14,
                  //     vertical: 8,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: VideoFeatureTheme.accentSoftFor(context),
                  //     borderRadius: BorderRadius.circular(999),
                  //   ),
                  //   child: Text(
                  //     'Workspace ready',
                  //     style: TextStyle(
                  //       color: VideoFeatureTheme.accentFor(context),
                  //       fontSize: 12,
                  //       fontWeight: FontWeight.w800,
                  //     ),
                  //   ),
                  // ),
                  SizedBox(height: compact ? 14 : 18),
                  Text(
                    config.title,
                    textAlign: TextAlign.center,
                    style: textTheme.displayMedium?.copyWith(
                      fontSize: compact ? (isPhone ? 26 : 32) : 46,
                    ),
                  ),
                  SizedBox(height: compact ? (isPhone ? 10 : 14) : 18),
                  Text(
                    config.subtitle,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: VideoFeatureTheme.mutedFor(context),
                      fontSize: compact ? (isPhone ? 14 : 15) : 17,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: compact ? (isPhone ? 18 : 22) : 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: isPhone ? 10 : 14,
                    runSpacing: isPhone ? 10 : 14,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: onStartRecording,
                        icon: const Icon(Icons.videocam_rounded),
                        label: Text(config.primaryActionLabel),
                        style: FilledButton.styleFrom(
                          backgroundColor: VideoFeatureTheme.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 18 : 24,
                            vertical: compact ? 14 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: config.hasDemoVideo
                            ? () {
                                SavedRecordingPlayer.showFullscreenDialog(
                                  context,
                                  recording: config.toDemoRecording(),
                                  autoplayMuted: false,
                                );
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Demo video is not configured yet.',
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.play_circle_outline_rounded),
                        label: Text(config.secondaryActionLabel),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: VideoFeatureTheme.inkFor(context),
                          side: BorderSide(
                            color: VideoFeatureTheme.lineStrongFor(context),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 18 : 24,
                            vertical: compact ? 14 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 18 : 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: isPhone ? 12 : 16,
                    runSpacing: isPhone ? 12 : 14,
                    children: config.featurePoints
                        .map((String label) => _FeaturePoint(label: label))
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 20 : 28),
            _EmptyFirebasePreview(compact: compact, config: config),
          ],
        ),
      ),
    );
  }
}

class _FeaturePoint extends StatelessWidget {
  const _FeaturePoint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.sizeOf(context).width < 520;
    return Container(
      constraints: BoxConstraints(maxWidth: isPhone ? 160 : 220),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: isPhone ? 22 : 26,
            height: isPhone ? 22 : 26,
            decoration: const BoxDecoration(
              color: VideoFeatureTheme.focus,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: isPhone ? 14 : 16,
            ),
          ),
          SizedBox(width: isPhone ? 8 : 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: VideoFeatureTheme.mutedFor(context),
                fontSize: isPhone ? 13 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFirebasePreview extends StatelessWidget {
  const _EmptyFirebasePreview({required this.compact, required this.config});

  final bool compact;
  final AdminConfigModel config;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.sizeOf(context).width < 520;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? (isPhone ? 10 : 14) : 20),
      decoration: BoxDecoration(
        color: VideoFeatureTheme.isDark(context)
            ? const Color(0xFF111826)
            : const Color(0xFF0F2530),
        borderRadius: BorderRadius.circular(compact ? (isPhone ? 18 : 24) : 28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F2530).withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: _PreviewVideoPlaceholder(compact: compact, config: config),
    );
  }
}

class _PreviewVideoPlaceholder extends StatelessWidget {
  const _PreviewVideoPlaceholder({required this.compact, required this.config});

  final bool compact;
  final AdminConfigModel config;

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.sizeOf(context).width < 520;
    final double radius = compact ? (isPhone ? 14 : 18) : 20;
    final double videoHeight = compact ? (isPhone ? 200 : 240) : 500;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: double.infinity,
        height: videoHeight,
        child: config.hasDemoVideo
            ? SavedRecordingPlayer(recording: config.toDemoRecording())
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      VideoFeatureTheme.canvasShadeFor(context),
                      VideoFeatureTheme.panelMutedFor(context),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    size: 44,
                    color: VideoFeatureTheme.primary,
                  ),
                ),
              ),
      ),
    );
  }
}

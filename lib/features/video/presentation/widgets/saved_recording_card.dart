import 'package:flutter/material.dart';

import '../../data/models/saved_video_recording_model.dart';
import '../controller/saved_recording_transfer.dart';
import '../controller/video_feature_theme.dart';
import 'saved_recording_player.dart';

class SavedRecordingCard extends StatefulWidget {
  const SavedRecordingCard({
    super.key,
    required this.recording,
    required this.onDelete,
  });

  final SavedVideoRecordingModel recording;
  final VoidCallback onDelete;

  @override
  State<SavedRecordingCard> createState() => _SavedRecordingCardState();
}

class _SavedRecordingCardState extends State<SavedRecordingCard> {
  bool _isExpanded = false;
  bool _isProcessingTransfer = false;

  @override
  Widget build(BuildContext context) {
    final SavedVideoRecordingModel recording = widget.recording;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: VideoFeatureTheme.line),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x130B1326),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF2569DA), Color(0xFF163A9C)],
                  ),
                ),
                child: const Icon(
                  Icons.video_library_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      recording.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatSavedAt(recording.savedAt)} • ${_formatDuration(recording.duration)} • ${_formatBytes(recording.sizeInBytes)}',
                      style: const TextStyle(
                        color: VideoFeatureTheme.muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                tooltip: 'Delete recording',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: VideoFeatureTheme.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              FilledButton.icon(
                key: Key('playRecordingButton_${recording.id}'),
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                icon: Icon(
                  _isExpanded
                      ? Icons.visibility_off_rounded
                      : Icons.play_circle_fill_rounded,
                ),
                label: Text(_isExpanded ? 'Hide player' : 'Play recording'),
                style: FilledButton.styleFrom(
                  backgroundColor: VideoFeatureTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isProcessingTransfer
                    ? null
                    : () => _handleRecordingAction(downloadSavedRecording),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VideoFeatureTheme.ink,
                  side: const BorderSide(color: VideoFeatureTheme.line),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isProcessingTransfer
                    ? null
                    : () => _handleRecordingAction(shareSavedRecording),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VideoFeatureTheme.ink,
                  side: const BorderSide(color: VideoFeatureTheme.line),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          if (_isExpanded) ...<Widget>[
            const SizedBox(height: 18),
            SavedRecordingPlayer(recording: recording, autoplayMuted: true),
          ],
        ],
      ),
    );
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

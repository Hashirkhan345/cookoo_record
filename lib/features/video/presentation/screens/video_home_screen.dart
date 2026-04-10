import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../auth/provider/auth_state.dart';
import '../../data/enums/video_recording_mode.dart';
import '../../provider/video_provider.dart';
import '../../provider/video_state.dart';
import '../controller/record_video_flow_controller.dart';
import '../controller/video_feature_theme.dart';
import '../widgets/brand_lockup.dart';
import '../widgets/home_account_menu.dart';
import '../widgets/saved_recordings_section.dart';

class VideoHomeScreen extends ConsumerStatefulWidget {
  const VideoHomeScreen({super.key});

  @override
  ConsumerState<VideoHomeScreen> createState() => _VideoHomeScreenState();
}

class _VideoHomeScreenState extends ConsumerState<VideoHomeScreen> {
  bool _isRecordingFlowVisible = false;
  final ScrollController _pageScrollController = ScrollController();

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  Future<void> _showRecordingFlow() async {
    _isRecordingFlowVisible = true;
    await RecordVideoFlowController.show(context);

    if (!mounted) {
      return;
    }

    _isRecordingFlowVisible = false;
    ref.read(videoControllerProvider.notifier).dismissRecordingFlow();
  }

  Future<void> _handleSignOut() async {
    await ref.read(videoControllerProvider.notifier).closeRecordingFlow();
    await ref.read(authControllerProvider.notifier).signOut();
  }

  Future<void> _handleAccountMenuSelection(
    HomeAccountMenuAction action,
    AuthState authState,
  ) async {
    switch (action) {
      case HomeAccountMenuAction.profile:
        final user = authState.user;
        if (user == null) {
          return;
        }
        await Navigator.of(
          context,
        ).pushNamed(AppRoute.profile, arguments: user);
        return;
      // case HomeAccountMenuAction.integrations:
      //   await _showMenuDialog(
      //     title: 'Integrations',
      //     icon: Icons.extension_outlined,
      //     body:
      //         'Connect recording workflows with storage, sharing, and collaboration services from this section.',
      //   );
      //   return;
      case HomeAccountMenuAction.settings:
        await _showMenuDialog(
          title: 'Settings',
          icon: Icons.settings_outlined,
          body:
              'Workspace settings and recording preferences will appear here.',
        );
        return;
      case HomeAccountMenuAction.guide:
        await _showMenuDialog(
          title: 'Guide',
          icon: Icons.description_outlined,
          body:
              'Choose a recording mode, allow browser permissions, then save or export recordings from the home screen.',
        );
        return;
      case HomeAccountMenuAction.helpCenter:
        await Navigator.of(context).pushNamed(AppRoute.helpCenter);
        return;
      case HomeAccountMenuAction.privacyPolicy:
        await Navigator.of(context).pushNamed(AppRoute.privacyPolicy);
        return;
      case HomeAccountMenuAction.termsAndConditions:
        await Navigator.of(context).pushNamed(AppRoute.termsAndConditions);
        return;
      case HomeAccountMenuAction.signOut:
        await _handleSignOut();
        return;
    }
  }

  Future<void> _showMenuDialog({
    required String title,
    required IconData icon,
    required String body,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: VideoFeatureTheme.line),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          title: Row(
            children: <Widget>[
              Icon(icon, color: VideoFeatureTheme.ink, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: VideoFeatureTheme.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: Text(
            body,
            style: const TextStyle(
              color: VideoFeatureTheme.muted,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: VideoFeatureTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<VideoState>(videoControllerProvider, (previous, next) {
      if (next.isRecordingFlowVisible && !_isRecordingFlowVisible) {
        unawaited(_showRecordingFlow());
      }

      final String? feedbackMessage = next.feedbackMessage;
      if (feedbackMessage == null ||
          feedbackMessage == previous?.feedbackMessage) {
        return;
      }

      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(feedbackMessage)));
      ref.read(videoControllerProvider.notifier).clearFeedbackMessage();
    });
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
        return;
      }

      if ((previous?.isAuthenticated ?? false) && !next.isAuthenticated) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoute.login, (Route<dynamic> _) => false);
        return;
      }

      final String? feedbackMessage = next.feedbackMessage;
      if (feedbackMessage == null ||
          feedbackMessage == previous?.feedbackMessage) {
        return;
      }

      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(feedbackMessage)));
      ref.read(authControllerProvider.notifier).clearFeedbackMessage();
    });

    final VideoState state = ref.watch(videoControllerProvider);
    final AuthState authState = ref.watch(authControllerProvider);
    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final flow = state.flow;
    if (flow == null) {
      return Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => ref.read(videoControllerProvider.notifier).load(),
            child: const Text('Retry'),
          ),
        ),
      );
    }

    final Size screenSize = MediaQuery.sizeOf(context);
    final bool isDesktop = screenSize.width >= 980;
    final bool supportsDisplayCapture =
        supportedRecordingModesForCurrentPlatform().any(
          (VideoRecordingMode mode) => mode.capturesDisplay,
        );
    final double contentHorizontalPadding = isDesktop ? 36 : 20;
    final int savedCount = state.savedRecordings.length;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: VideoFeatureTheme.screenBackground,
              ),
            ),
          ),
          Positioned(
            left: -120,
            top: -80,
            child: _AmbientGlow(
              size: screenSize.width * 0.42,
              color: const Color(0x33E8BC67),
            ),
          ),
          Positioned(
            right: -140,
            top: 120,
            child: _AmbientGlow(
              size: screenSize.width * 0.48,
              color: const Color(0x26147A73),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 18, 0, 24),
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  scrollbars: false,
                ),
                child: Scrollbar(
                  controller: _pageScrollController,
                  thumbVisibility: isDesktop,
                  trackVisibility: false,
                  interactive: true,
                  radius: const Radius.circular(999),
                  thickness: 10,
                  child: SingleChildScrollView(
                    controller: _pageScrollController,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: contentHorizontalPadding,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1240),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Expanded(
                                    child: BrandLockup(brandLabel: 'bloop'),
                                  ),
                                  if (screenSize.width >= 620 &&
                                      supportsDisplayCapture)
                                    const _TopPill(
                                      icon: Icons.desktop_windows_rounded,
                                      label: 'Studio Web',
                                    )
                                  else if (screenSize.width >= 620)
                                    const _TopPill(
                                      icon: Icons.phone_iphone_rounded,
                                      label: 'Mobile Capture',
                                    ),
                                  if (authState.user != null) ...<Widget>[
                                    const SizedBox(width: 14),
                                    HomeAccountMenu(
                                      user: authState.user!,
                                      isBusy: authState.isSubmitting,
                                      onSelected:
                                          (HomeAccountMenuAction action) {
                                            unawaited(
                                              _handleAccountMenuSelection(
                                                action,
                                                authState,
                                              ),
                                            );
                                          },
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 26),
                              LayoutBuilder(
                                builder:
                                    (
                                      BuildContext context,
                                      BoxConstraints constraints,
                                    ) {
                                      final bool useSplit =
                                          constraints.maxWidth >= 1020;
                                      final Widget hero = _HomeHeroCard(
                                        title: flow.heroTitle,
                                        description: flow.heroDescription,
                                        buttonLabel: flow.heroActionLabel,
                                        recordingLimitLabel:
                                            flow.recordingLimitLabel,
                                        supportsDisplayCapture:
                                            supportsDisplayCapture,
                                        savedCount: savedCount,
                                        isBusy: state.isPreparingCameraPreview,
                                        onStart: ref
                                            .read(
                                              videoControllerProvider.notifier,
                                            )
                                            .openRecordingFlow,
                                      );
                                      final Widget sideCard = _WorkspaceCard(
                                        savedCount: savedCount,
                                        recordingLimitLabel:
                                            flow.recordingLimitLabel,
                                        isDesktop: isDesktop,
                                      );

                                      if (!useSplit) {
                                        return Column(
                                          children: <Widget>[
                                            hero,
                                            const SizedBox(height: 20),
                                            sideCard,
                                          ],
                                        );
                                      }

                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Expanded(flex: 7, child: hero),
                                          const SizedBox(width: 20),
                                          Expanded(flex: 4, child: sideCard),
                                        ],
                                      );
                                    },
                              ),
                              const SizedBox(height: 26),
                              SavedRecordingsSection(
                                recordings: state.savedRecordings,
                                currentUser: authState.user,
                                onDeleteRecording: ref
                                    .read(videoControllerProvider.notifier)
                                    .deleteSavedRecording,
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VideoFeatureTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: VideoFeatureTheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: VideoFeatureTheme.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.recordingLimitLabel,
    required this.supportsDisplayCapture,
    required this.savedCount,
    required this.isBusy,
    required this.onStart,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final String recordingLimitLabel;
  final bool supportsDisplayCapture;
  final int savedCount;
  final bool isBusy;
  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    final bool isCompact = MediaQuery.sizeOf(context).width < 760;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: VideoFeatureTheme.heroGradient,
        borderRadius: BorderRadius.circular(40),
        boxShadow: VideoFeatureTheme.panelShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -40,
              top: -20,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 32,
              bottom: 22,
              child: Container(
                width: 138,
                height: 138,
                decoration: BoxDecoration(
                  color: VideoFeatureTheme.focus.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(38),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isCompact ? 24 : 34,
                isCompact ? 24 : 34,
                isCompact ? 24 : 34,
                isCompact ? 24 : 34,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      'Recorder',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact ? 38 : 56,
                      fontWeight: FontWeight.w700,
                      height: 1.02,
                      letterSpacing: -1.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (!isCompact) ...<Widget>[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else
                    const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      FilledButton.icon(
                        key: const Key('recordVideoButton'),
                        onPressed: isBusy ? null : () => onStart(),
                        icon: const Icon(Icons.fiber_manual_record_rounded),
                        label: Text(buttonLabel),
                        style: FilledButton.styleFrom(
                          backgroundColor: VideoFeatureTheme.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 22,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              supportsDisplayCapture
                                  ? Icons.web_asset_rounded
                                  : Icons.videocam_rounded,
                              color: VideoFeatureTheme.focus,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              supportsDisplayCapture ? 'Web capture' : 'Camera',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      _HeroMetric(
                        label: 'Saved clips',
                        value: '$savedCount',
                        icon: Icons.video_library_rounded,
                      ),
                      _HeroMetric(
                        label: 'Capture type',
                        value: supportsDisplayCapture
                            ? 'Screen + cam'
                            : 'Camera',
                        icon: Icons.stacked_line_chart_rounded,
                      ),
                      _HeroMetric(
                        label: 'Limit',
                        value: recordingLimitLabel,
                        icon: Icons.timer_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: VideoFeatureTheme.focus, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.savedCount,
    required this.recordingLimitLabel,
    required this.isDesktop,
  });

  final int savedCount;
  final String recordingLimitLabel;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: VideoFeatureTheme.line),
        boxShadow: VideoFeatureTheme.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: VideoFeatureTheme.accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Overview',
              style: TextStyle(
                color: VideoFeatureTheme.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Quick stats',
            style: TextStyle(
              color: VideoFeatureTheme.ink,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.08,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 4),
          _WorkspaceStat(label: 'Recordings saved', value: '$savedCount'),
          const SizedBox(height: 14),
          _WorkspaceStat(label: 'Session limit', value: recordingLimitLabel),
          const SizedBox(height: 14),
          _WorkspaceStat(
            label: 'Best on',
            value: isDesktop ? 'Desktop workspace' : 'Compact screen',
          ),
        ],
      ),
    );
  }
}

class _WorkspaceStat extends StatelessWidget {
  const _WorkspaceStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: VideoFeatureTheme.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VideoFeatureTheme.line),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: VideoFeatureTheme.muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: VideoFeatureTheme.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

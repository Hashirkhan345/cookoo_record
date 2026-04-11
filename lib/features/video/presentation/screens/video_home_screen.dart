import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../auth/provider/auth_state.dart';
import '../../provider/video_provider.dart';
import '../../provider/video_state.dart';
import '../controller/record_video_flow_controller.dart';
import '../controller/video_feature_theme.dart';
import '../widgets/brand_lockup.dart';
import '../widgets/home_account_menu.dart';
import '../widgets/saved_recordings_section.dart';
import '../widgets/studio_dialog.dart';

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
        await _showSettingsDialog(authState);
        return;
      case HomeAccountMenuAction.login:
        await Navigator.of(context).pushNamed(AppRoute.login);
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
    return showStudioDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StudioDialogShell(
          icon: icon,
          badge: 'Workspace',
          title: title,
          message: body,
          maxWidth: 620,
          actions: Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: VideoFeatureTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSettingsDialog(AuthState authState) {
    final bool isGuest = !authState.isAuthenticated;

    return showStudioDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StudioDialogShell(
          icon: Icons.settings_outlined,
          badge: 'Settings',
          title: isGuest ? 'Guest mode' : 'Workspace settings',
          message: isGuest
              ? 'You are using bloop without signing in. You can keep browsing in guest mode, or sign in to access account features.'
              : 'Workspace settings and recording preferences will appear here.',
          maxWidth: 640,
          actions: Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              if (isGuest)
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).pushNamed(AppRoute.login);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Login'),
                ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: VideoFeatureTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                ),
                child: Text(isGuest ? 'Continue as guest' : 'Close'),
              ),
            ],
          ),
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
        ).pushNamedAndRemoveUntil(AppRoute.home, (Route<dynamic> _) => false);
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
    final double contentHorizontalPadding = isDesktop ? 36 : 20;

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
                                  HomeAccountMenu(
                                    user: authState.user,
                                    isBusy: authState.isSubmitting,
                                    onSelected: (HomeAccountMenuAction action) {
                                      unawaited(
                                        _handleAccountMenuSelection(
                                          action,
                                          authState,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 26),
                              LayoutBuilder(
                                builder:
                                    (
                                      BuildContext context,
                                      BoxConstraints constraints,
                                    ) {
                                      final Widget hero = _HomeHeroCard(
                                        title: flow.heroTitle,
                                        buttonLabel: flow.heroActionLabel,
                                        isBusy: state.isPreparingCameraPreview,
                                        onStart: ref
                                            .read(
                                              videoControllerProvider.notifier,
                                            )
                                            .openRecordingFlow,
                                      );

                                      return hero;
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

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard({
    required this.title,
    required this.buttonLabel,
    required this.isBusy,
    required this.onStart,
  });

  final String title;
  final String buttonLabel;
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact ? 32 : 44,
                      fontWeight: FontWeight.w700,
                      height: 1.06,
                      letterSpacing: -1.2,
                    ),
                  ),
                  SizedBox(height: isCompact ? 16 : 20),
                  Center(
                    child: FilledButton.icon(
                      key: const Key('recordVideoButton'),
                      onPressed: isBusy ? null : () => onStart(),
                      icon: const Icon(Icons.fiber_manual_record_rounded),
                      label: Text(buttonLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: VideoFeatureTheme.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 18,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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

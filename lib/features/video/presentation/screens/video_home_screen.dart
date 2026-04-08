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
import '../widgets/home_account_menu.dart';
import '../widgets/home_sidebar.dart';
// import '../widgets/home_top_bar.dart';
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
    final double headlineSize = screenSize.width < 640 ? 36 : 48;
    final double contentHorizontalPadding = isDesktop ? 112 : 20;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: VideoFeatureTheme.screenBackground,
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
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
                              constraints: const BoxConstraints(maxWidth: 980),
                              child: Column(
                                children: <Widget>[
                                  if (!isDesktop &&
                                      !state.isRecordingFlowVisible &&
                                      authState.user != null)
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: HomeAccountMenu(
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
                                    ),
                                  // HomeTopBar(isDesktop: isDesktop),
                                  const SizedBox(height: 28),
                                  Text(
                                    flow.heroTitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: headlineSize,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 620,
                                    ),
                                    child: Text(
                                      flow.heroDescription,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: VideoFeatureTheme.muted,
                                        fontSize: 18,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  FilledButton.icon(
                                    key: const Key('recordVideoButton'),
                                    onPressed: state.isPreparingCameraPreview
                                        ? null
                                        : ref
                                              .read(
                                                videoControllerProvider
                                                    .notifier,
                                              )
                                              .openRecordingFlow,
                                    icon: const Icon(
                                      Icons.videocam_outlined,
                                      size: 28,
                                    ),
                                    label: Text(flow.heroActionLabel),
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          VideoFeatureTheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 34,
                                        vertical: 24,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.86,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: VideoFeatureTheme.line,
                                      ),
                                    ),
                                    child: Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: <Widget>[
                                        const Icon(
                                          Icons.desktop_mac_outlined,
                                          color: VideoFeatureTheme.primary,
                                        ),
                                        Text(
                                          flow.helperMessage,
                                          style: const TextStyle(
                                            color: VideoFeatureTheme.muted,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 520,
                                    ),
                                    child: const Divider(
                                      color: VideoFeatureTheme.line,
                                      thickness: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 34),
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
              if (isDesktop && !state.isRecordingFlowVisible)
                Positioned(
                  right: 28,
                  top: 12,
                  bottom: 18,
                  child: HomeSidebar(
                    accountMenu: authState.user != null
                        ? HomeAccountMenu(
                            user: authState.user!,
                            isBusy: authState.isSubmitting,
                            onSelected: (HomeAccountMenuAction action) {
                              unawaited(
                                _handleAccountMenuSelection(action, authState),
                              );
                            },
                          )
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

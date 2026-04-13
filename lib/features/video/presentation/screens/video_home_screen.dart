import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../auth/provider/auth_state.dart';
import '../../provider/admin_config_provider.dart';
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
    final AsyncValue adminConfigAsync = ref.watch(adminConfigProvider);
    final videoController = ref.read(videoControllerProvider.notifier);
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
                              SavedRecordingsSection(
                                recordings: state.savedRecordings,
                                currentUser: authState.user,
                                adminConfig: adminConfigAsync.valueOrNull,
                                savedCountLabel:
                                    '${state.savedRecordings.length} saved',
                                onDeleteRecording:
                                    videoController.deleteSavedRecording,
                                onStartRecording:
                                    videoController.openRecordingFlow,
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
          Positioned(
            left: 16,
            bottom: 0,
            child: SafeArea(
              bottom: false,
              child: IconButton(
                key: const Key('recordVideoFloatingButton'),
                onPressed: state.isPreparingCameraPreview
                    ? null
                    : videoController.openRecordingFlow,
                tooltip: 'Record a video',
                style: IconButton.styleFrom(
                  backgroundColor: VideoFeatureTheme.accent,
                  disabledBackgroundColor: VideoFeatureTheme.muted,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(58, 58),
                  shape: const CircleBorder(),
                  elevation: 6,
                ),
                icon: const Icon(Icons.videocam_rounded, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

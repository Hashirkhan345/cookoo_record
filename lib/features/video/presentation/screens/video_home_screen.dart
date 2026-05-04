import 'dart:async';

import 'package:bloop/features/video/data/models/saved_video_recording_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_theme_controller.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../auth/provider/auth_state.dart';
import '../../data/models/admin_config_model.dart';
import '../../provider/admin_config_provider.dart';
import '../../provider/video_provider.dart';
import '../../provider/video_state.dart';
import '../controller/record_video_flow_controller.dart';
import '../controller/video_feature_theme.dart';
import '../widgets/brand_lockup.dart';
import '../widgets/home_account_menu.dart';
import '../widgets/home_sidebar.dart';
import '../widgets/home_top_bar.dart';
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
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            final AppThemePreference selectedTheme = ref.watch(
              themeControllerProvider,
            );

            return StudioDialogShell(
              icon: Icons.settings_outlined,
              badge: 'Settings',
              title: isGuest ? 'Guest mode' : 'Workspace settings',
              message: isGuest
                  ? 'You are using Aks without signing in. You can keep browsing in guest mode, or sign in to access account features.'
                  : 'Choose how Aks should appear across the app.',
              maxWidth: 640,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Appearance mode',
                    style: TextStyle(
                      color: VideoFeatureTheme.inkFor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AppThemePreference.values
                        .map((AppThemePreference preference) {
                          return _ThemeModeCard(
                            preference: preference,
                            isSelected: preference == selectedTheme,
                            onTap: () => ref
                                .read(themeControllerProvider.notifier)
                                .setPreference(preference),
                          );
                        })
                        .toList(growable: false),
                  ),
                ],
              ),
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
      },
    );
  }

  Future<void> _showRecordingRestrictedDialog() {
    return showStudioDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StudioDialogShell(
          icon: Icons.lock_outline_rounded,
          badge: 'Recording',
          title: 'Login required',
          message:
              'You cannot capture a recording right now. Please log in first to use the recording feature.',
          maxWidth: 560,
          actions: Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(this.context).pushNamed(AppRoute.login);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: VideoFeatureTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go to login'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showUpgradeDialog({
    required int usedVideos,
    required int freeVideoLimit,
  }) {
    const List<_SubscriptionPlan> plans = <_SubscriptionPlan>[
      _SubscriptionPlan(
        name: 'Starter',
        price: r'$9',
        interval: '/month',
        description:
            'For light creators who need more room than the free plan.',
        videoLimit: '100 videos',
        duration: '10 min each',
        highlights: <String>[
          'Cloud saved recordings',
          'Shareable video links',
          'Basic workspace history',
        ],
        actionLabel: 'Choose Starter',
      ),
      _SubscriptionPlan(
        name: 'Pro',
        price: r'$19',
        interval: '/month',
        description:
            'Best for regular walkthroughs, product demos, and support.',
        videoLimit: '500 videos',
        duration: '30 min each',
        highlights: <String>[
          'Priority uploads',
          'Longer recordings',
          'Advanced sharing controls',
        ],
        actionLabel: 'Choose Pro',
        isRecommended: true,
      ),
      _SubscriptionPlan(
        name: 'Team',
        price: r'$49',
        interval: '/month',
        description: 'For teams that record, review, and share together.',
        videoLimit: 'Unlimited videos',
        duration: '60 min each',
        highlights: <String>[
          'Team workspace',
          'Admin controls',
          'Shared recording library',
        ],
        actionLabel: 'Choose Team',
      ),
    ];

    return showStudioDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StudioDialogShell(
          icon: Icons.workspace_premium_outlined,
          badge: 'Upgrade',
          title: 'Choose a recording plan',
          message:
              'You have used $usedVideos of $freeVideoLimit free recordings. Pick a plan to unlock more capacity and keep recording without interruption.',
          maxWidth: 920,
          content: _SubscriptionPlansContent(
            plans: plans,
            usedVideos: usedVideos,
            freeVideoLimit: freeVideoLimit,
          ),
        );
      },
    );
  }

  Future<void> _handleRecordingAccess(
    AuthState authState,
    VideoState videoState,
  ) async {
    final bool isGuest = !authState.isAuthenticated;
    if (isGuest && videoState.hasReachedRecordingRestriction) {
      await _showRecordingRestrictedDialog();
      return;
    }

    await ref.read(videoControllerProvider.notifier).openRecordingFlow();
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
    final bool isDesktop = screenSize.width >= 1100;
    final bool isPhone = screenSize.width < 600;
    final double contentHorizontalPadding = isDesktop ? 0 : (isPhone ? 14 : 20);
    final double desktopSidebarMinHeight =
        screenSize.height - MediaQuery.paddingOf(context).vertical - 40;
    const double desktopSidebarSlotWidth = 212;
    const double desktopSidebarGap = 12;
    final AdminConfigModel adminConfig =
        adminConfigAsync.valueOrNull ?? AdminConfigModel.defaults;
    final int usageCount =
        authState.user?.recordedVideosCount ?? state.currentRecordedCount;
    final Widget accountMenu = HomeAccountMenu(
      user: authState.user,
      isBusy: authState.isSubmitting,
      onSelected: (HomeAccountMenuAction action) {
        unawaited(_handleAccountMenuSelection(action, authState));
      },
    );

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: isPhone
          ? FloatingActionButton.extended(
              key: const Key('recordVideoFloatingButton'),
              onPressed: state.isPreparingCameraPreview
                  ? null
                  : () => unawaited(_handleRecordingAccess(authState, state)),
              backgroundColor: VideoFeatureTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.videocam_rounded),
              label: const Text('Record'),
            )
          : null,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: VideoFeatureTheme.canvasFor(context),
              ),
            ),
          ),
          SafeArea(
            bottom: isPhone,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                isPhone ? 12 : 18,
                0,
                isPhone ? 16 : 0,
              ),
              child: Stack(
                children: <Widget>[
                  ScrollConfiguration(
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
                              constraints: const BoxConstraints(maxWidth: 1360),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  if (isDesktop)
                                    const SizedBox(
                                      width:
                                          desktopSidebarSlotWidth +
                                          desktopSidebarGap,
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        if (!isDesktop) ...<Widget>[
                                          Row(
                                            children: <Widget>[
                                              const Expanded(
                                                child: BrandLockup(
                                                  brandLabel: 'Aks',
                                                ),
                                              ),
                                              accountMenu,
                                            ],
                                          ),
                                          SizedBox(height: isPhone ? 16 : 20),
                                        ],
                                        HomeTopBar(
                                          title: flow.heroTitle,
                                          subtitle: flow.heroDescription,
                                          primaryActionLabel:
                                              flow.heroActionLabel,
                                          onPrimaryAction: () => unawaited(
                                            _handleRecordingAccess(
                                              authState,
                                              state,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: isPhone ? 16 : 22),
                                        const _SectionEyebrow(label: 'Library'),
                                        const SizedBox(height: 10),
                                        LayoutBuilder(
                                          builder:
                                              (
                                                BuildContext context,
                                                BoxConstraints constraints,
                                              ) {
                                                final Widget
                                                library = SavedRecordingsSection(
                                                  recordings:
                                                      state.savedRecordings,
                                                  currentUser: authState.user,
                                                  adminConfig: adminConfigAsync
                                                      .valueOrNull,
                                                  savedCountLabel:
                                                      '${state.savedRecordings.length} saved',
                                                  onRenameRecording:
                                                      (
                                                        SavedVideoRecordingModel
                                                        recording,
                                                        String title,
                                                      ) => videoController
                                                          .renameSavedRecording(
                                                            recording,
                                                            title: title,
                                                          ),
                                                  onDeleteRecording:
                                                      videoController
                                                          .deleteSavedRecording,
                                                  onStartRecording: () =>
                                                      unawaited(
                                                        _handleRecordingAccess(
                                                          authState,
                                                          state,
                                                        ),
                                                      ),
                                                );

                                                return library;
                                              },
                                        ),
                                        SizedBox(height: isPhone ? 24 : 32),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (isDesktop)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: contentHorizontalPadding,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1360),
                          child: Row(
                            children: <Widget>[
                              HomeSidebar(
                                minHeight: desktopSidebarMinHeight,
                                user: authState.user,
                                onStartRecording: () => unawaited(
                                  _handleRecordingAccess(authState, state),
                                ),
                                recordedCount: usageCount,
                                recordingLimit: adminConfig.freeVideoLimit,
                                onOpenAccountMenu: () => unawaited(
                                  HomeAccountMenu.showAccountPanel(
                                    context: context,
                                    user: authState.user,
                                    guestLabel: 'Guest user',
                                    onSelected: (HomeAccountMenuAction action) {
                                      unawaited(
                                        _handleAccountMenuSelection(
                                          action,
                                          authState,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                onUpgrade: () => unawaited(
                                  _showUpgradeDialog(
                                    usedVideos: usageCount,
                                    freeVideoLimit: adminConfig.freeVideoLimit,
                                  ),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: VideoFeatureTheme.mutedFor(context),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({
    required this.preference,
    required this.isSelected,
    required this.onTap,
  });

  final AppThemePreference preference;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (preference) {
      AppThemePreference.system => Icons.brightness_auto_rounded,
      AppThemePreference.light => Icons.light_mode_rounded,
      AppThemePreference.dark => Icons.dark_mode_rounded,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 168,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? VideoFeatureTheme.accentSoftFor(context)
                : VideoFeatureTheme.panelMutedFor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected
                  ? VideoFeatureTheme.primary
                  : VideoFeatureTheme.lineFor(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                icon,
                color: isSelected
                    ? VideoFeatureTheme.primary
                    : VideoFeatureTheme.mutedFor(context),
              ),
              const SizedBox(height: 12),
              Text(
                preference.label,
                style: TextStyle(
                  color: VideoFeatureTheme.inkFor(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                preference == AppThemePreference.system
                    ? 'Follow device appearance'
                    : 'Use this theme everywhere',
                style: TextStyle(
                  color: VideoFeatureTheme.mutedFor(context),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionPlan {
  const _SubscriptionPlan({
    required this.name,
    required this.price,
    required this.interval,
    required this.description,
    required this.videoLimit,
    required this.duration,
    required this.highlights,
    required this.actionLabel,
    this.isRecommended = false,
  });

  final String name;
  final String price;
  final String interval;
  final String description;
  final String videoLimit;
  final String duration;
  final List<String> highlights;
  final String actionLabel;
  final bool isRecommended;
}

class _SubscriptionPlansContent extends StatefulWidget {
  const _SubscriptionPlansContent({
    required this.plans,
    required this.usedVideos,
    required this.freeVideoLimit,
  });

  final List<_SubscriptionPlan> plans;
  final int usedVideos;
  final int freeVideoLimit;

  @override
  State<_SubscriptionPlansContent> createState() =>
      _SubscriptionPlansContentState();
}

class _SubscriptionPlansContentState extends State<_SubscriptionPlansContent> {
  late String _selectedPlanName = _initialSelectedPlanName();

  String _initialSelectedPlanName() {
    final _SubscriptionPlan recommendedPlan = widget.plans.firstWhere(
      (_SubscriptionPlan plan) => plan.isRecommended,
      orElse: () => widget.plans.first,
    );
    return recommendedPlan.name;
  }

  void _selectPlan(String planName) {
    setState(() => _selectedPlanName = planName);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final bool isCompact = screenSize.width < 720;
    final int safeLimit = widget.freeVideoLimit <= 0
        ? 1
        : widget.freeVideoLimit;
    final int safeCount = widget.usedVideos.clamp(0, safeLimit);
    final double progress = (safeCount / safeLimit).clamp(0, 1).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VideoFeatureTheme.panelMutedFor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: VideoFeatureTheme.lineFor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Current free usage',
                      style: TextStyle(
                        color: VideoFeatureTheme.inkFor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$safeCount/$safeLimit videos',
                    style: TextStyle(
                      color: VideoFeatureTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: VideoFeatureTheme.lineFor(context),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    VideoFeatureTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: widget.plans
              .map((_SubscriptionPlan plan) {
                return _SubscriptionPlanCard(
                  plan: plan,
                  isSelected: plan.name == _selectedPlanName,
                  width: isCompact ? double.infinity : 258,
                  onSelected: () => _selectPlan(plan.name),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _SubscriptionPlanCard extends StatelessWidget {
  const _SubscriptionPlanCard({
    required this.plan,
    required this.isSelected,
    required this.width,
    required this.onSelected,
  });

  final _SubscriptionPlan plan;
  final bool isSelected;
  final double width;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final bool isRecommended = plan.isRecommended;
    final Color borderColor = isSelected
        ? VideoFeatureTheme.primary
        : VideoFeatureTheme.lineFor(context);
    final Color cardColor = isSelected
        ? VideoFeatureTheme.accentSoftFor(context)
        : VideoFeatureTheme.panelMutedFor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: width,
          constraints: const BoxConstraints(minHeight: 316),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: borderColor, width: isSelected ? 1.6 : 1),
            boxShadow: isSelected ? VideoFeatureTheme.glowShadow : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      plan.name,
                      style: TextStyle(
                        color: VideoFeatureTheme.inkFor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  if (isSelected || isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? VideoFeatureTheme.primary
                            : VideoFeatureTheme.panelFor(context),
                        borderRadius: BorderRadius.circular(999),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: VideoFeatureTheme.lineFor(context),
                              ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (isSelected) ...<Widget>[
                            const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            isSelected ? 'Selected' : 'Best value',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : VideoFeatureTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: plan.price,
                      style: TextStyle(
                        color: VideoFeatureTheme.inkFor(context),
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
                    TextSpan(
                      text: plan.interval,
                      style: TextStyle(
                        color: VideoFeatureTheme.mutedFor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plan.description,
                style: TextStyle(
                  color: VideoFeatureTheme.mutedFor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              _PlanMetric(
                icon: Icons.video_library_outlined,
                label: plan.videoLimit,
              ),
              const SizedBox(height: 8),
              _PlanMetric(icon: Icons.schedule_rounded, label: plan.duration),
              const SizedBox(height: 12),
              ...plan.highlights.map((String highlight) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.check_circle_rounded,
                        color: VideoFeatureTheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          highlight,
                          style: TextStyle(
                            color: VideoFeatureTheme.inkFor(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: isSelected
                    ? FilledButton.icon(
                        onPressed: onSelected,
                        style: FilledButton.styleFrom(
                          backgroundColor: VideoFeatureTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Selected'),
                      )
                    : OutlinedButton(
                        onPressed: onSelected,
                        child: Text(plan.actionLabel),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanMetric extends StatelessWidget {
  const _PlanMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: VideoFeatureTheme.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: VideoFeatureTheme.inkFor(context),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../video/presentation/controller/video_feature_theme.dart';
import '../../../video/presentation/screens/video_home_screen.dart';
import '../../provider/auth_provider.dart';
import '../../provider/auth_state.dart';
import 'login_screen.dart';

class AuthGateScreen extends ConsumerWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState authState = ref.watch(authControllerProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: VideoFeatureTheme.screenBackground,
          ),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (authState.isAuthenticated) {
      return const VideoHomeScreen();
    }

    return const LoginScreen();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../video/presentation/controller/video_feature_theme.dart';
import '../../provider/auth_provider.dart';
import '../../provider/auth_state.dart';

class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key});

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> {
  @override
  Widget build(BuildContext context) {
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

    final String targetRoute = authState.isAuthenticated
        ? AppRoute.home
        : AppRoute.login;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(targetRoute);
    });

    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: VideoFeatureTheme.screenBackground),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

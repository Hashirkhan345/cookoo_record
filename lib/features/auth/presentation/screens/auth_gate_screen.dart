import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../video/presentation/controller/video_feature_theme.dart';
import '../../../video/presentation/widgets/brand_lockup.dart';
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
      return const _LoadingSplash();
    }

    const String targetRoute = AppRoute.home;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacementNamed(targetRoute);
    });

    return const _LoadingSplash();
  }
}

class _LoadingSplash extends StatelessWidget {
  const _LoadingSplash();

  @override
  Widget build(BuildContext context) {
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
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: VideoFeatureTheme.line),
                boxShadow: VideoFeatureTheme.floatingShadow,
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  BrandMark(size: 56),
                  SizedBox(height: 18),
                  Text(
                    'Loading your studio',
                    style: TextStyle(
                      color: VideoFeatureTheme.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: VideoFeatureTheme.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

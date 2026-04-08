import 'package:flutter/material.dart';

import 'app_routes.dart';
import '../../features/auth/data/models/app_user.dart';
import '../../features/auth/presentation/screens/auth_gate_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/video/presentation/screens/help_center_screen.dart';
import '../../features/video/presentation/screens/privacy_policy_screen.dart';
import '../../features/video/presentation/screens/profile_screen.dart';
import '../../features/video/presentation/screens/terms_and_conditions_screen.dart';
import '../../features/video/presentation/screens/video_home_screen.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoute.root:
        return _buildRoute<void>(
          settings: settings,
          builder: (_) => const AuthGateScreen(),
        );
      case AppRoute.login:
        return _buildRoute<void>(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case AppRoute.home:
        return _buildRoute<void>(
          settings: settings,
          builder: (_) => const VideoHomeScreen(),
        );
      case AppRoute.register:
        return _buildRoute<void>(
          settings: settings,
          builder: (_) => const RegisterScreen(),
        );
      case AppRoute.forgotPassword:
        final String initialEmail = settings.arguments is String
            ? settings.arguments! as String
            : '';

        return _buildRoute<String>(
          settings: settings,
          builder: (_) => ForgotPasswordScreen(initialEmail: initialEmail),
        );
      case AppRoute.profile:
        final AppUser? user = settings.arguments is AppUser
            ? settings.arguments! as AppUser
            : null;

        return _buildRoute<void>(
          settings: settings,
          builder: (_) =>
              user != null ? ProfileScreen(user: user) : const VideoHomeScreen(),
        );
      case AppRoute.helpCenter:
        return _buildRoute<void>(
          settings: settings,
          builder: (_) => const HelpCenterScreen(),
        );
      case AppRoute.privacyPolicy:
        return _buildRoute<void>(
          settings: settings,
          builder: (_) => const PrivacyPolicyScreen(),
        );
      case AppRoute.termsAndConditions:
        return _buildRoute<void>(
          settings: settings,
          builder: (_) => const TermsAndConditionsScreen(),
        );
      default:
        return _buildRoute<void>(
          settings: settings,
          builder: (_) => const AuthGateScreen(),
        );
    }
  }

  static Route<T> _buildRoute<T>({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    return MaterialPageRoute<T>(settings: settings, builder: builder);
  }
}

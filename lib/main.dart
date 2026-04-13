import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'app/router/app_routes.dart';
import 'firebase_options.dart';
import 'features/video/presentation/controller/video_feature_theme.dart';
import 'features/video/presentation/controller/video_web_camera_registration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  registerVideoWebCameraPlugin();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: VideoFeatureTheme.primary,
      brightness: Brightness.light,
      surface: VideoFeatureTheme.panel,
    );
    final ThemeData baseTheme = ThemeData.light(useMaterial3: true);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'bloop',
      theme: baseTheme.copyWith(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: VideoFeatureTheme.canvas,
        pageTransitionsTheme: AppRouter.pageTransitionsTheme,
        dividerColor: VideoFeatureTheme.line,
        textTheme: VideoFeatureTheme.buildTextTheme(baseTheme.textTheme),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: VideoFeatureTheme.ink,
          contentTextStyle: const TextStyle(
            fontFamily: VideoFeatureTheme.fontFamily,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(34),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(
              fontFamily: VideoFeatureTheme.fontFamily,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: VideoFeatureTheme.ink,
            side: const BorderSide(color: VideoFeatureTheme.line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(
              fontFamily: VideoFeatureTheme.fontFamily,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: VideoFeatureTheme.panelMuted.withValues(alpha: 0.5),
          labelStyle: const TextStyle(
            fontFamily: VideoFeatureTheme.fontFamily,
            color: VideoFeatureTheme.muted,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: VideoFeatureTheme.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: VideoFeatureTheme.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(
              color: VideoFeatureTheme.primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: VideoFeatureTheme.danger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(
              color: VideoFeatureTheme.danger,
              width: 1.5,
            ),
          ),
        ),
      ),
      initialRoute: AppRoute.root,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

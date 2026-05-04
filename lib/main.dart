import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme_controller.dart';
import 'firebase_options.dart';
import 'features/video/presentation/controller/video_feature_theme.dart';
import 'features/video/presentation/controller/video_web_camera_registration.dart';
//flutter run -d 192.168.100.136:5555

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  registerVideoWebCameraPlugin();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemePreference themePreference = ref.watch(
      themeControllerProvider,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aks',
      theme: VideoFeatureTheme.buildTheme(brightness: Brightness.light),
      darkTheme: VideoFeatureTheme.buildTheme(brightness: Brightness.dark),
      themeMode: themePreference.themeMode,
      initialRoute: AppRouter.resolveInitialRoute(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      onGenerateInitialRoutes: AppRouter.onGenerateInitialRoutes,
    );
  }
}

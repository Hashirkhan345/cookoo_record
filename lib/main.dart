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
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'bloop',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: VideoFeatureTheme.canvas,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: VideoFeatureTheme.ink,
          displayColor: VideoFeatureTheme.ink,
        ),
      ),
      initialRoute: AppRoute.root,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'app/router/app_router.dart';
import 'app/router/app_routes.dart';
import 'firebase_options.dart';
import 'features/video/presentation/controller/video_feature_theme.dart';
import 'features/video/presentation/controller/video_web_camera_registration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _preloadMaterialSymbolFonts();
  registerVideoWebCameraPlugin();
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _preloadMaterialSymbolFonts() async {
  const List<_PackagedFontAsset> fonts = <_PackagedFontAsset>[
    _PackagedFontAsset(
      assetPath:
          'packages/material_symbols_icons/lib/fonts/MaterialSymbolsOutlined.ttf',
      familyNames: <String>[
        'MaterialSymbolsOutlined',
        'packages/material_symbols_icons/MaterialSymbolsOutlined',
      ],
    ),
    _PackagedFontAsset(
      assetPath:
          'packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf',
      familyNames: <String>[
        'MaterialSymbolsRounded',
        'packages/material_symbols_icons/MaterialSymbolsRounded',
      ],
    ),
    _PackagedFontAsset(
      assetPath:
          'packages/material_symbols_icons/lib/fonts/MaterialSymbolsSharp.ttf',
      familyNames: <String>[
        'MaterialSymbolsSharp',
        'packages/material_symbols_icons/MaterialSymbolsSharp',
      ],
    ),
  ];

  await Future.wait(
    fonts.expand(
      (_PackagedFontAsset font) => font.familyNames.map((String familyName) {
        final FontLoader loader = FontLoader(familyName);
        loader.addFont(rootBundle.load(font.assetPath));
        return loader.load();
      }),
    ),
  );
}

class _PackagedFontAsset {
  const _PackagedFontAsset({
    required this.assetPath,
    required this.familyNames,
  });

  final String assetPath;
  final List<String> familyNames;
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

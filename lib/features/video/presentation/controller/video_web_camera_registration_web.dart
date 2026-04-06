import 'package:camera_web/camera_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:video_player_web/video_player_web.dart';

void registerVideoWebCameraPlugin() {
  CameraPlugin.registerWith(webPluginRegistrar);
  SharedPreferencesPlugin.registerWith(webPluginRegistrar);
  VideoPlayerPlugin.registerWith(webPluginRegistrar);
}

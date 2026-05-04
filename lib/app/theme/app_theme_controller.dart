import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { system, light, dark }

extension AppThemePreferenceX on AppThemePreference {
  ThemeMode get themeMode {
    switch (this) {
      case AppThemePreference.system:
        return ThemeMode.system;
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  String get label {
    switch (this) {
      case AppThemePreference.system:
        return 'Auto';
      case AppThemePreference.light:
        return 'White';
      case AppThemePreference.dark:
        return 'Dark';
    }
  }

  String get storageValue {
    switch (this) {
      case AppThemePreference.system:
        return 'system';
      case AppThemePreference.light:
        return 'light';
      case AppThemePreference.dark:
        return 'dark';
    }
  }

  static AppThemePreference fromStorageValue(String? value) {
    switch (value) {
      case 'light':
        return AppThemePreference.light;
      case 'dark':
        return AppThemePreference.dark;
      case 'system':
      default:
        return AppThemePreference.system;
    }
  }
}

final themeControllerProvider =
    StateNotifierProvider<AppThemeController, AppThemePreference>(
      (Ref ref) => AppThemeController()..load(),
    );

class AppThemeController extends StateNotifier<AppThemePreference> {
  AppThemeController() : super(AppThemePreference.system);

  static const String _storageKey = 'app_theme_preference';

  Future<void> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    state = AppThemePreferenceX.fromStorageValue(
      preferences.getString(_storageKey),
    );
  }

  Future<void> setPreference(AppThemePreference preference) async {
    if (state == preference) {
      return;
    }

    state = preference;

    unawaited(_persist(preference));
  }

  Future<void> _persist(AppThemePreference preference) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, preference.storageValue);
  }
}

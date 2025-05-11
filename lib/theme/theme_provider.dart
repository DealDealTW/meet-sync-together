import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 定義主題模式
enum AppThemeMode { light, dark, system }

// 共享偏好設置提供者
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('需要在 ProviderScope.overrides 中被覆蓋');
});

// 主題狀態通知者
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  final SharedPreferences prefs;
  
  ThemeNotifier(this.prefs)
      : super(
          // Default to light theme
          AppThemeMode.values[prefs.getInt('theme_mode') ?? AppThemeMode.light.index],
        );
  
  void setTheme(AppThemeMode mode) {
    prefs.setInt('theme_mode', mode.index);
    state = mode;
  }
  
  void toggleTheme() {
    final newMode = state == AppThemeMode.light 
        ? AppThemeMode.dark 
        : AppThemeMode.light;
    setTheme(newMode);
  }
}

// 主題提供者
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier(ref.read(sharedPreferencesProvider));
}); 
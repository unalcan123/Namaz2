import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prefs_repository.dart';

class ThemeController extends StateNotifier<ThemeMode> {
  final PrefsRepository _prefs;

  ThemeController(this._prefs) : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    // getThemeMode async değilse yine de Future yazmak sorun değil
    final saved = _prefs.getThemeMode();
    state = saved;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await _prefs.saveThemeMode(mode);
  }
}

final themeProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  final prefs = ref.watch(prefsRepositoryProvider); // nullable olmasın
  return ThemeController(prefs);
});

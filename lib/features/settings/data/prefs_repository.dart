import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../locations/data/models.dart';
import 'alert_settings.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final prefsRepositoryProvider =
    Provider<PrefsRepository>((ref) => PrefsRepository(ref.watch(sharedPrefsProvider)));

class PrefsRepository {
  final SharedPreferences _prefs;

  PrefsRepository(this._prefs);

  static const _recentLocationsKey = 'recent_locations';
  static const _themeModeKey = 'theme_mode';
  static const _alertTypeKey = 'alert_type';
  static const _customAudioPathsKey = 'custom_audio_paths';
  static const _cachedVakitlerKey = 'cached_vakitler_';

  Future<void> saveVakitler(String ilceId, List<Vakit> list) async {
    final data = list.map((v) => v.toJson()).toList();
    await _prefs.setString(_cachedVakitlerKey + ilceId, json.encode(data));
  }

  List<Vakit>? getCachedVakitler(String ilceId) {
    final jsonStr = _prefs.getString(_cachedVakitlerKey + ilceId);
    if (jsonStr == null) return null;
    final List<dynamic> data = json.decode(jsonStr);
    return data.map((item) => Vakit.fromJson(item as Map<String, dynamic>)).toList();
  }

  List<SavedLocation> getRecentLocations() {
    final locationsJson = _prefs.getStringList(_recentLocationsKey) ?? [];
    return locationsJson
        .map((jsonString) => SavedLocation.fromJson(json.decode(jsonString) as Map<String, dynamic>))
        .toList();
  }

  Future<void> addRecentLocation(SavedLocation newLocation) async {
    final currentLocations = getRecentLocations();
    currentLocations.removeWhere((loc) => loc.ilce.ilceId == newLocation.ilce.ilceId);
    currentLocations.insert(0, newLocation);
    final updatedList = currentLocations.take(4).toList();
    final List<String> jsonList = updatedList.map((loc) => json.encode(loc.toJson())).toList();
    await _prefs.setStringList(_recentLocationsKey, jsonList);
  }

  ThemeMode getThemeMode() {
    final themeName = _prefs.getString(_themeModeKey);
    return ThemeMode.values.firstWhere((e) => e.name == themeName, orElse: () => ThemeMode.system);
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setAlarmSettings(AlertSettings settings) async {
    await _prefs.setString(_alertTypeKey, settings.alertType.name);
    await _prefs.setStringList(_customAudioPathsKey, settings.customAudioPaths);
    for (final preNotif in settings.preNotifications.entries) {
      await _prefs.setBool('pre_notif_${preNotif.key}', preNotif.value);
    }
    for (final prayer in settings.prayerAlarms.entries) {
      await _prefs.setBool('alarm_${prayer.key}', prayer.value);
    }
  }

  Future<AlertSettings> getAlarmSettings() async {
    final alertTypeName = _prefs.getString(_alertTypeKey);
    final alertType = AlertType.values.firstWhere(
      (e) => e.name == alertTypeName, 
      orElse: () => AlertType.ezan,
    );

    final prayerAlarms = {for (var name in prayerNames) name: _prefs.getBool('alarm_$name') ?? false};
    final customAudioPaths = _prefs.getStringList(_customAudioPathsKey) ?? [];
    final preNotifications = {for (var minute in preNotificationMinutes) minute: _prefs.getBool('pre_notif_$minute') ?? false};

    return AlertSettings(
      prayerAlarms: prayerAlarms,
      alertType: alertType,
      customAudioPaths: customAudioPaths,
      preNotifications: preNotifications,
    );
  }
}

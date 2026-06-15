import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/alert_settings.dart';

final alertSettingsProvider = StateNotifierProvider<AlertSettingsNotifier, AlertSettings>((ref) {
  return AlertSettingsNotifier();
});

class AlertSettingsNotifier extends StateNotifier<AlertSettings> {
  AlertSettingsNotifier() : super(AlertSettings()) {
    _loadSettings();
  }

  static const _keyPrayerAlarms = 'prayer_alarms';
  static const _keyAlertType = 'alert_type';
  static const _keyCustomAudios = 'custom_audios';
  static const _keySelectedAudio = 'selected_audio';
  static const _keyPreNotifications = 'pre_notifications';
  static const _keySlideDuration = 'slide_duration';
  static const _keySlideCategory = 'slide_category';
  static const _keyUserCategories = 'user_categories';
  static const _keyBgMusicPaths = 'bg_music_paths'; // Değişti: List için
  static const _keyBgMusicEnabled = 'bg_music_enabled';

  void touchLastUpdate() {
    state = state.copyWith(lastUpdate: DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final alarmMap = <String, bool>{};
    for (var name in prayerNames) {
      alarmMap[name] = prefs.getBool('${_keyPrayerAlarms}_$name') ?? false;
    }

    final preNotifyMap = <int, bool>{};
    for (var m in preNotificationMinutes) {
      preNotifyMap[m] = prefs.getBool('${_keyPreNotifications}_$m') ?? false;
    }

    final userCatsRaw = prefs.getString(_keyUserCategories);
    Map<String, String> userCats = {};
    if (userCatsRaw != null) {
      userCats = Map<String, String>.from(json.decode(userCatsRaw));
    }

    final musicPaths = prefs.getStringList(_keyBgMusicPaths) ?? [defaultBgMusicPath];

    state = state.copyWith(
      prayerAlarms: alarmMap,
      alertType: AlertType.values[prefs.getInt(_keyAlertType) ?? 0],
      customAudioPaths: prefs.getStringList(_keyCustomAudios) ?? [],
      selectedCustomAudioPath: prefs.getString(_keySelectedAudio),
      preNotifications: preNotifyMap,
      slideDuration: prefs.getInt(_keySlideDuration) ?? 15,
      slideCategory: prefs.getString(_keySlideCategory) ?? 'resim',
      userCategories: userCats,
      bgMusicPaths: musicPaths,
      bgMusicEnabled: prefs.getBool(_keyBgMusicEnabled) ?? true,
    );
  }

  Future<void> togglePrayerAlarm(String name, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_keyPrayerAlarms}_$name', value);

    final newAlarms = Map<String, bool>.from(state.prayerAlarms);
    newAlarms[name] = value;
    state = state.copyWith(prayerAlarms: newAlarms);
  }

  Future<void> setAlertType(AlertType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAlertType, type.index);
    state = state.copyWith(alertType: type);
  }

  Future<void> pickCustomAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final newList = [...state.customAudioPaths, path];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyCustomAudios, newList);
      
      state = state.copyWith(customAudioPaths: newList);
      if (state.selectedCustomAudioPath == null) {
        selectCustomAudio(path);
      }
    }
  }

  Future<void> selectCustomAudio(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedAudio, path);
    state = state.copyWith(selectedCustomAudioPath: path);
  }

  Future<void> removeCustomAudio(String path) async {
    final newList = state.customAudioPaths.where((p) => p != path).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyCustomAudios, newList);
    
    String? newSelected = state.selectedCustomAudioPath;
    if (newSelected == path) {
      newSelected = newList.isNotEmpty ? newList.first : null;
      if (newSelected != null) {
        await prefs.setString(_keySelectedAudio, newSelected);
      } else {
        await prefs.remove(_keySelectedAudio);
      }
    }
    
    state = state.copyWith(customAudioPaths: newList, selectedCustomAudioPath: newSelected);
  }

  Future<void> togglePreNotification(int minute, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_keyPreNotifications}_$minute', value);

    final newNotify = Map<int, bool>.from(state.preNotifications);
    newNotify[minute] = value;
    state = state.copyWith(preNotifications: newNotify);
  }

  Future<void> setSlideDuration(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySlideDuration, seconds);
    state = state.copyWith(slideDuration: seconds);
  }

  Future<void> setSlideCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySlideCategory, category);
    state = state.copyWith(slideCategory: category);
  }

  void triggerRefresh() {
    state = state.copyWith(lastUpdate: DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> addUserCategory(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newCats = Map<String, String>.from(state.userCategories);
    newCats[id] = name;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserCategories, json.encode(newCats));

    state = state.copyWith(userCategories: newCats);
  }

  Future<void> removeUserCategory(String id) async {
    final newCats = Map<String, String>.from(state.userCategories);
    newCats.remove(id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserCategories, json.encode(newCats));

    String newCategory = state.slideCategory;
    if (state.slideCategory == id) {
      newCategory = 'resim';
      await prefs.setString(_keySlideCategory, newCategory);
    }

    state = state.copyWith(userCategories: newCats, slideCategory: newCategory);
  }

  // ✅ Birden fazla arka plan müziği ekle
  Future<void> addBgMusicPaths(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    final newList = {...state.bgMusicPaths, ...paths}.toList();
    await prefs.setStringList(_keyBgMusicPaths, newList);
    state = state.copyWith(bgMusicPaths: newList);
  }

  // ✅ Arka plan müziği kaldır
  Future<void> removeBgMusicPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final newList = state.bgMusicPaths.where((p) => p != path).toList();
    if (newList.isEmpty) newList.add(defaultBgMusicPath);
    await prefs.setStringList(_keyBgMusicPaths, newList);
    state = state.copyWith(bgMusicPaths: newList);
  }

  // ✅ Arka plan müzik aç/kapat
  Future<void> toggleBgMusic(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBgMusicEnabled, value);
    state = state.copyWith(bgMusicEnabled: value);
  }
}

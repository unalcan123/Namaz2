import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/notification_service.dart';
import 'features/settings/data/prefs_repository.dart';
import 'features/settings/presentation/tv_mode_effect.dart';

Future<void> main() async {
  // Flutter framework'ünü başlat ve plugin'lerin hazır olmasını bekle
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('web_user_images');
  // Lock screen orientation to landscape mode for TV
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,


  ]);

  // SharedPreferences'ı yükle
  final prefs = await SharedPreferences.getInstance();

  // ProviderScope'u hazır SharedPreferences nesnesi ile başlat
  final container = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
    ],
  );

  // Bildirim servisini de uygulama başlamadan önce başlat
  await container.read(notificationServiceProvider).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TvModeEffect(child: EzanApp()),
    ),
  );
}

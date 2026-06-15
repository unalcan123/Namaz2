import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/bg_music_service.dart';
import 'features/locations/presentation/country_page.dart';
import 'features/settings/data/prefs_repository.dart';
import 'features/settings/presentation/alert_settings_controller.dart';
import 'features/settings/presentation/theme_controller.dart';
import 'features/times/presentation/times_page.dart';

/// ✅ Ana uygulama widget'ı — müzik servisi burada başlatılır
class EzanApp extends ConsumerStatefulWidget {
  const EzanApp({super.key});

  @override
  ConsumerState<EzanApp> createState() => _EzanAppState();
}

class _EzanAppState extends ConsumerState<EzanApp> {
  @override
  void initState() {
    super.initState();
    // Müzik servisini uygulama başlar başlamaz başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bgMusicServiceProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final recentLocations =
        ref.watch(prefsRepositoryProvider).getRecentLocations();
    final lastLocation =
        recentLocations.isNotEmpty ? recentLocations.first : null;

    final themeMode = ref.watch(themeProvider);
    final isMuted = ref.watch(bgMusicMutedProvider);
    final settings = ref.watch(alertSettingsProvider);

    final homePage = lastLocation != null
        ? TimesPage(
            ulke: lastLocation.ulke,
            sehir: lastLocation.sehir,
            ilce: lastLocation.ilce,
          )
        : const CountryPage();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ezan Vakti',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      builder: (context, child) {
        // ✅ Tüm sayfaların üstüne mute butonu ekle
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            // ✅ Müzik açıksa mute butonu göster — her yerde görünür
            if (settings.bgMusicEnabled)
              Positioned(
                left: 8,
                bottom: 58,
                child: SafeArea(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () =>
                          ref.read(bgMusicServiceProvider).toggleMute(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      home: homePage,
    );
  }
}

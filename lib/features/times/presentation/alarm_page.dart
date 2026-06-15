import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../settings/data/alert_settings.dart';
import '../../settings/presentation/alert_settings_controller.dart';

class AlarmPage extends ConsumerStatefulWidget {
  final String nextPrayerName;

  const AlarmPage({super.key, required this.nextPrayerName});

  @override
  ConsumerState<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends ConsumerState<AlarmPage> {
  final _audioPlayer = AudioPlayer();
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final settings = ref.read(alertSettingsProvider);
    String? audioPath;

    if (settings.alertType == AlertType.custom) {
      // Eğer özel ses seçiliyse onu çal, değilse rastgele bir tane çal
      audioPath = settings.selectedCustomAudioPath;
      if (audioPath == null && settings.customAudioPaths.isNotEmpty) {
        final randomIndex = Random().nextInt(settings.customAudioPaths.length);
        audioPath = settings.customAudioPaths[randomIndex];
      }
    } else {
      audioPath = _getAudioPathForPrayer(settings.alertType, widget.nextPrayerName);
    }

    if (audioPath == null) {
      debugPrint("Çalınacak ses dosyası yolu bulunamadı.");
      return;
    }

    try {
      if (settings.alertType == AlertType.custom) {
        await _audioPlayer.setFilePath(audioPath);
      } else {
        // Asset yolunun doğru olduğundan emin ol
        await _audioPlayer.setAsset(audioPath);
      }
      
      _playerStateSubscription = _audioPlayer.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          _closePage();
        }
      });
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("Ses dosyası çalınamadı ($audioPath): $e");
      // Saniye bekle ve sayfayı kapatma, kullanıcı görsün
    }
  }

  String? _getAudioPathForPrayer(AlertType alertType, String prayerName) {
    if (alertType == AlertType.ezan) {
      switch (prayerName) {
        case 'İmsak':
          return 'assets/audio/sabah_ezan.mp3';
        case 'Öğle':
          return 'assets/audio/ogle_ezan.mp3';
        case 'İkindi':
          return 'assets/audio/ikindi_ezan.mp3';
        case 'Akşam':
          return 'assets/audio/aksam_ezan.mp3';
        case 'Yatsı':
          return 'assets/audio/yatsi_ezan.mp3';
        default:
          return null;
      }
    }
    return null;
  }

  void _closePage() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mosque, size: 100, color: Colors.amber),
            const SizedBox(height: 32),
            Text(
              '${widget.nextPrayerName} Vakti Girdi',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ezan okunuyor...',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              onPressed: _closePage,
              child: const Text('DURDUR', style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

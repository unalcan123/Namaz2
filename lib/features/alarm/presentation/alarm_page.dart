import 'dart:async';
import 'dart:math';
import 'dart:ui';

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

class _AlarmPageState extends ConsumerState<AlarmPage> with SingleTickerProviderStateMixin {
  final _audioPlayer = AudioPlayer();
  StreamSubscription? _playerStateSubscription;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initPlayer();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initPlayer() async {
    final settings = ref.read(alertSettingsProvider);
    String? audioPath;

    if (settings.alertType == AlertType.custom) {
      if (settings.customAudioPaths.isNotEmpty) {
        final randomIndex = Random().nextInt(settings.customAudioPaths.length);
        audioPath = settings.customAudioPaths[randomIndex];
      }
    } else {
      audioPath = _getAudioPathForPrayer(settings.alertType, widget.nextPrayerName);
    }

    if (audioPath == null) return;

    try {
      await (settings.alertType == AlertType.custom
          ? _audioPlayer.setFilePath(audioPath)
          : _audioPlayer.setAsset(audioPath));

      _playerStateSubscription = _audioPlayer.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) _closePage();
      });
      _audioPlayer.play();
    } catch (e) {
      debugPrint("Ses dosyası çalınamadı: $e");
      _closePage();
    }
  }

  String? _getAudioPathForPrayer(AlertType alertType, String prayerName) {
    if (alertType == AlertType.ezan) {
      switch (prayerName) {
        case 'İmsak': return 'assets/audio/sabah_ezan.mp3';
        case 'Öğle': return 'assets/audio/ogle_ezan.mp3';
        case 'İkindi': return 'assets/audio/ikindi_ezan.mp3';
        case 'Akşam': return 'assets/audio/aksam_ezan.mp3';
        case 'Yatsı': return 'assets/audio/yatsi_ezan.mp3';
        default: return null;
      }
    }
    return null; // For custom, we handle it in _initPlayer
  }

  void _closePage() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/image/cami.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x8C000000), 
                  Color(0x59000000), 
                  Color(0xB3000000), 
                ],
              ),
            ),
          ),
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                      decoration: BoxDecoration(
                        color: const Color(0x1FFFFFFF), 
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0x38FFFFFF)), 
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x59000000), 
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0x1FFFFFFF), 
                                border: Border.all(color: const Color(0x2EFFFFFF)), 
                              ),
                              child: const Icon(
                                Icons.mosque_outlined,
                                size: 72,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Namaz Vakti Girdi',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: const Color(0xF2FFFFFF), 
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sıradaki vakit',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xBFFFFFFF), 
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xF2FFD740),
                                  Color(0xD8FF9100),
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x40000000), 
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.nextPrayerName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          Container(
                            height: 1,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  const Color(0x59FFFFFF), 
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xE0FFFFFF), 
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                              onPressed: _closePage,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.stop_circle_outlined),
                                  SizedBox(width: 10),
                                  Text(
                                    'Durdur / Kapat',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

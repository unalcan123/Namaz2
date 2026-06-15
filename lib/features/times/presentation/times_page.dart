import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notification_service.dart';
import '../../../widgets/app_drawer.dart';
import '../../locations/data/location_providers.dart';
import '../../locations/data/models.dart';
import '../../settings/data/alert_settings.dart';
import '../../settings/presentation/alert_settings_controller.dart';
import 'alarm_page.dart';
import 'slayt_widget.dart';

final timesProvider = FutureProvider.family<List<Vakit>, String>((ref, ilceId) async {
  final repo = ref.watch(locationRepoProvider);
  return repo.vakitler(ilceId);
});

class TimesPage extends ConsumerStatefulWidget {
  final Ulke ulke;
  final Sehir sehir;
  final Ilce ilce;

  const TimesPage({super.key, required this.ulke, required this.sehir, required this.ilce});

  @override
  ConsumerState<TimesPage> createState() => _TimesPageState();
}

class _TimesPageState extends ConsumerState<TimesPage> {
  Timer? _timer;

  List<Vakit>? _list; // ✅ listeyi sakla
  Vakit? _today;

  DateTime _now = DateTime.now();
  DateTime _lastDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day); // ✅

  ({String name, DateTime time})? _nextPrayer;
  String? _currentPrayerName;
  Duration _remaining = Duration.zero;

  String? _lastTriggeredPrayerName;
  final Map<int, String> _lastTriggeredPrePrayer = {};
  bool _isCoolingDown = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final list = await ref.read(timesProvider(widget.ilce.ilceId).future);
    if (!mounted) return;

    _list = list; // ✅

    final today = _findToday(list, DateTime.now());
    if (today != null) {
      setState(() => _today = today);

      _startTimer();

      final settings = ref.read(alertSettingsProvider);
      ref.read(notificationServiceProvider).scheduleAlarms(list, settings);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || _today == null) return;

      final now = DateTime.now();
      final dayKey = DateTime(now.year, now.month, now.day);

      // ✅ Gün değişti mi?
      if (_list != null && dayKey != _lastDay) {
        final oldMoonUrl = _today?.ayinSekliURL;

        _lastDay = dayKey;
        final newToday = _findToday(_list!, now);

        if (newToday != null) {
          setState(() {
            _today = newToday;
            _lastTriggeredPrayerName = null;
            _lastTriggeredPrePrayer.clear();
            _isCoolingDown = false;
          });
          if (oldMoonUrl != null) {
            await NetworkImage(oldMoonUrl).evict();
          }
          await NetworkImage(newToday.ayinSekliURL).evict();
          // ✅ (Opsiyonel ama tavsiye) yeni gün için alarmları tekrar kur
          final settings = ref.read(alertSettingsProvider);
          ref.read(notificationServiceProvider).scheduleAlarms(_list!, settings);
        } else {
          // liste yeni günü kapsamıyorsa yeniden çek
          await _initData();
          return;
        }
      }

      setState(() {
        _now = now;
        _updateCountdown(_today!);
        _checkAndTriggerAlarm();
        _checkAndTriggerPreNotification();
      });
    });
  }

  DateTime _parsePrayerTime(String timeStr, DateTime date) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  void _updateCountdown(Vakit today) {
    _nextPrayer = nextPrayerFromList(today, _now);
    if (_nextPrayer != null) {
      _remaining = _nextPrayer!.time.difference(_now);
    } else {
      _remaining = Duration.zero;
    }

    final prayers = [
      (name: 'İmsak', time: _parsePrayerTime(today.imsak, _now)),
      (name: 'Güneş', time: _parsePrayerTime(today.gunes, _now)),
      (name: 'Öğle', time: _parsePrayerTime(today.ogle, _now)),
      (name: 'İkindi', time: _parsePrayerTime(today.ikindi, _now)),
      (name: 'Akşam', time: _parsePrayerTime(today.aksam, _now)),
      (name: 'Yatsı', time: _parsePrayerTime(today.yatsi, _now)),
    ];

    final passedPrayers = prayers.where((p) => p.time.isBefore(_now));
    if (passedPrayers.isNotEmpty) {
      _currentPrayerName = passedPrayers.last.name;
    } else {
      _currentPrayerName = 'Yatsı';
    }
  }

  void _checkAndTriggerAlarm() {
    if (_nextPrayer == null) return;

    final settings = ref.read(alertSettingsProvider);
    if (!settings.isPrayerEnabled(_nextPrayer!.name) || _isCoolingDown || _nextPrayer!.name == 'Güneş') return;

    if (_remaining.inSeconds <= 0 && _lastTriggeredPrayerName != _nextPrayer!.name) {
      _lastTriggeredPrayerName = _nextPrayer!.name;
      _isCoolingDown = true;

      Navigator.push(context, MaterialPageRoute(builder: (_) => AlarmPage(nextPrayerName: _nextPrayer!.name)));

      Future.delayed(const Duration(seconds: 20), () {
        if (mounted) setState(() => _isCoolingDown = false);
      });
    }
  }

  void _checkAndTriggerPreNotification() {
    if (_nextPrayer == null) return;

    final settings = ref.read(alertSettingsProvider);
    final prayerName = _nextPrayer!.name;

    if (prayerName == 'İmsak') return;

    for (final minute in preNotificationMinutes) {
      if (settings.isPreNotificationEnabled(minute)) {
        if (_remaining.inMinutes == minute &&
            _remaining.inSeconds % 60 == 0 &&
            _lastTriggeredPrePrayer[minute] != prayerName) {
          _lastTriggeredPrePrayer[minute] = prayerName;
          ref.read(notificationServiceProvider).showPrePrayerNotification(
            prayerName,
            minute,
            preNotificationAssets[minute],
          );
        }
      }
    }
  }

  /// ✅ Asıl fix burada: gün bittiğinde yarının imsakını, yarının Vakit datasından al.
  ({String name, DateTime time})? nextPrayerFromList(Vakit today, DateTime now) {
    DateTime parse(String timeStr, DateTime date) {
      final parts = timeStr.split(':');
      return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
    }

    final prayers = [
      (name: 'İmsak', time: parse(today.imsak, now)),
      (name: 'Güneş', time: parse(today.gunes, now)),
      (name: 'Öğle', time: parse(today.ogle, now)),
      (name: 'İkindi', time: parse(today.ikindi, now)),
      (name: 'Akşam', time: parse(today.aksam, now)),
      (name: 'Yatsı', time: parse(today.yatsi, now)),
    ];

    for (final p in prayers) {
      if (p.time.isAfter(now)) return p;
    }

    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowVakit = _list == null ? null : _findToday(_list!, tomorrow);

    final imsakStr = tomorrowVakit?.imsak ?? today.imsak; // fallback
    return (name: 'İmsak', time: parse(imsakStr, tomorrow));
  }

  Vakit? _findToday(List<Vakit> list, DateTime now) {
    try {
      return list.firstWhere((v) {
        final parts = v.miladiTarihKisaIso8601.split('.');
        if (parts.length != 3) return false;

        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d == null || m == null || y == null) return false;

        final date = DateTime(y, m, d);
        return date.year == now.year && date.month == now.month && date.day == now.day;
      });
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncTimes = ref.watch(timesProvider(widget.ilce.ilceId));

    ref.listen(alertSettingsProvider, (previous, next) {
      if (previous != next && _today != null) {
        asyncTimes.whenData((list) {
          ref.read(notificationServiceProvider).scheduleAlarms(list, next);
        });
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: SafeArea(
          child: asyncTimes.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (e, _) => Center(child: Text("Hata: $e", style: const TextStyle(color: Colors.white))),
            data: (list) {
              // liste yeni geldiyse cache'i güncelle (hot reload / refetch durumları için)
              _list ??= list;

              if (_today == null) return const Center(child: CircularProgressIndicator(color: Colors.white));

              return OrientationBuilder(
                builder: (context, orientation) {
                  final isPortrait = orientation == Orientation.portrait;

                  Widget bottomBar() {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xCC000000), Colors.transparent],
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildPrayerTimesHorizontalStrip(_today!, _currentPrayerName, context),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _scaffoldKey.currentState?.openDrawer(),
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Icon(Icons.menu, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (isPortrait) {
                    return Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: SlaytWidget(
                                height: double.infinity,
                                userImages: const [],
                                hideOnPortrait: false,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              color: const Color(0x22000000),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              child: Column(
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      widget.ilce.ilceAdi.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Divider(color: Colors.white10, height: 10),
                                  NextPrayerCountdownWidget(
                                    remaining: _remaining,
                                    nextPrayer: _nextPrayer,
                                    today: _today!,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        bottomBar(),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 75,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(10, 10, 4, 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: const SlaytWidget(
                                    height: double.infinity,
                                    userImages: [],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 25,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2, right: 4, bottom: 4),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            widget.ilce.ilceAdi.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Divider(color: Colors.white10, height: 2),
                                      NextPrayerCountdownWidget(
                                        remaining: _remaining,
                                        nextPrayer: _nextPrayer,
                                        today: _today!,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      bottomBar(),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerTimesHorizontalStrip(Vakit today, String? currentPrayerName, BuildContext context) {
    final prayerTimes = {
      'İmsak': today.imsak,
      'Güneş': today.gunes,
      'Öğle': today.ogle,
      'İkindi': today.ikindi,
      'Akşam': today.aksam,
      'Yatsı': today.yatsi,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: prayerTimes.entries.map((entry) {
        final name = entry.key;
        final time = entry.value;
        final isCurrent = name == currentPrayerName;

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 1),
            decoration: BoxDecoration(
              color: isCurrent ? Theme.of(context).colorScheme.primary.withAlpha(100) : const Color(0x33000000),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrent ? Theme.of(context).colorScheme.primary : Colors.white24,
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name,
                    style: TextStyle(
                      color: isCurrent ? Colors.white : Colors.white70,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    time,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

String formatDurationHHMMSS(Duration d) {
  if (d.isNegative) return '00:00:00';
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
}

class NextPrayerCountdownWidget extends StatelessWidget {
  final Duration remaining;
  final ({String name, DateTime time})? nextPrayer;
  final Vakit today;
  final bool compact;

  const NextPrayerCountdownWidget({
    super.key,
    required this.remaining,
    required this.nextPrayer,
    required this.today,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final prayerName = nextPrayer?.name ?? '';
    final title = prayerName == 'Güneş' ? 'Güneşin Doğmasına' : '$prayerName Vaktine';

    final titleGap = compact ? 10.0 : 20.0;
    final countdownFont = compact ? 50.0 : 50.0;
    final clockFont = compact ? 16.0 : 20.0;
    final moonHeight = compact ? 48.0 : 65.0;
    final boxVPad = compact ? 6.0 : 10.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        LiveClock(fontSize: clockFont),
        const Divider(color: Colors.white24, height: 1),
        SizedBox(height: titleGap),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatDurationHHMMSS(remaining),
            style: TextStyle(
              fontSize: countdownFont,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'monospace',
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Image.network(
          today.ayinSekliURL,
          key: ValueKey('${today.ayinSekliURL}-${today.miladiTarihKisaIso8601}'),
          height: moonHeight,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.brightness_3, color: Colors.white70, size: moonHeight),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: boxVPad),
          decoration: BoxDecoration(
            color: const Color(0x4D000000),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  today.miladiTarihUzun,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 14 : null,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  today.hicriTarihUzun,
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall?.copyWith(
                    color: Colors.white70,
                    fontSize: compact ? 12 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LiveClock extends StatefulWidget {
  final double fontSize;

  const LiveClock({Key? key, this.fontSize = 20}) : super(key: key);

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late DateTime _now;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time =
        "${_now.hour.toString().padLeft(2, '0')}:"
        "${_now.minute.toString().padLeft(2, '0')}:"
        "${_now.second.toString().padLeft(2, '0')}";

    return Text(
      time,
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w500,
        color: Colors.white60,
        fontFamily: 'monospace',
      ),
    );
  }
}
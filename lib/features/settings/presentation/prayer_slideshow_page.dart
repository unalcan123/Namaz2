import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../times/presentation/slayt_widget.dart';
/// ✅ Hem yatay hem dikey serbest
Future<void> allowAllOrientations() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

class PrayerSlideshowPage extends ConsumerStatefulWidget {
  const PrayerSlideshowPage({super.key});

  @override
  ConsumerState<PrayerSlideshowPage> createState() => _PrayerSlideshowPageState();
}

class _PrayerSlideshowPageState extends ConsumerState<PrayerSlideshowPage> {
  @override
  void initState() {
    super.initState();
    allowAllOrientations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isPortrait = orientation == Orientation.portrait;

            if (isPortrait) {
              // ✅ PORTRAIT: Üstte slayt -> altına bilgi paneli -> en altta namaz bar
              return Column(
                children: [
                  Expanded(
                    child: SlaytWidget(
                      height: double.infinity,
                      hideOnPortrait: false, // ✅ portrait'te slayt görünsün
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TopInfoPanel(
                      // ✅ BURAYA kendi değerlerini bağlayacaksın
                      city: "ROTTERDAM",
                      nowTime: "00:16:12",
                      title: "İmsak Vaktine",
                      remaining: "05:38:47",
                      miladi: "20 Şubat 2026 Cuma",
                      hicri: "2 Ramazan 1447",
                      // ay resmi url'in varsa ver
                      moonImageUrl: null,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ✅ Namaz vakitleri bar (senin mevcut alt bar kodunu buraya yapıştır)
                  const PrayerTimesBar(),
                ],
              );
            }

            // ✅ LANDSCAPE: Solda slayt, sağda panel, altta namaz bar
            return Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: SlaytWidget(
                          height: double.infinity,
                          hideOnPortrait: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 320,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: TopInfoPanel(
                              city: "ROTTERDAM",
                              nowTime: "00:16:12",
                              title: "İmsak Vaktine",
                              remaining: "05:38:47",
                              miladi: "20 Şubat 2026 Cuma",
                              hicri: "2 Ramazan 1447",
                              moonImageUrl: null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const PrayerTimesBar(),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ✅ Sağ üstteki her şeyin “alt bölüme” taşınmış hali.
/// Burayı senin mevcut panel kodunla 1-1 değiştirebilirsin.
class TopInfoPanel extends StatelessWidget {
  final String city;
  final String nowTime;
  final String title;
  final String remaining;
  final String miladi;
  final String hicri;
  final String? moonImageUrl;

  const TopInfoPanel({
    super.key,
    required this.city,
    required this.nowTime,
    required this.title,
    required this.remaining,
    required this.miladi,
    required this.hicri,
    this.moonImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x4D000000),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ✅ şehir
          Text(
            city,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),

          // ✅ bilgisayar saati (normal saat)
          Text(
            nowTime,
            style: textTheme.titleSmall?.copyWith(color: Colors.white54),
          ),

          const SizedBox(height: 10),

          // ✅ başlık
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(color: Colors.white70),
          ),

          const SizedBox(height: 6),

          // ✅ geri sayım
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              remaining,
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'monospace',
                height: 1.0,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ✅ ay görseli (varsa)
          if (moonImageUrl != null) ...[
            Image.network(
              moonImageUrl!,
              height: 60,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.brightness_3, color: Colors.white70, size: 50),
            ),
            const SizedBox(height: 8),
          ],

          // ✅ tarihler
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x33000000),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                Text(
                  miladi,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hicri,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ Alt namaz vakitleri bar’ı (placeholder).
/// Burayı SENİN mevcut namaz chips/row widget’larınla değiştir.
class PrayerTimesBar extends StatelessWidget {
  const PrayerTimesBar({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔁 Burayı kendi mevcut “namaz vakitleri” widget kodunla değiştir.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: const [
              _TimeChip(label: "İmsak", time: "05:55"),
              SizedBox(width: 8),
              _TimeChip(label: "Güneş", time: "07:41"),
              SizedBox(width: 8),
              _TimeChip(label: "Öğle", time: "13:01"),
              SizedBox(width: 8),
              _TimeChip(label: "İkindi", time: "15:36"),
              SizedBox(width: 8),
              _TimeChip(label: "Akşam", time: "18:11"),
              SizedBox(width: 8),
              _TimeChip(label: "Yatsı", time: "19:44", selected: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final String time;
  final bool selected;

  const _TimeChip({
    required this.label,
    required this.time,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.white12 : Colors.black54,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? Colors.white38 : Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 2),
          Text(time, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
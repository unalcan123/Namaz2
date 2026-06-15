import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'mode_controller.dart';

/// TV Modu'nun yan etkilerini yöneten, UI göstermeyen bir widget.
/// Bu widget, mod değişikliklerini dinler ve şunları yapar:
/// - TV Modu: Ekranı sürekli açık tutar (Wakelock) ve tam ekran yapar.
/// - Telefon Modu: Varsayılan ayarları geri yükler.
class TvModeEffect extends ConsumerWidget {
  final Widget child;
  const TvModeEffect({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AppMode>(modeProvider, (_, mode) {
      if (mode == AppMode.tv) {
        // TV Modu Aktif
        WakelockPlus.enable();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        // Telefon Modu Aktif (Varsayılanlar)
        WakelockPlus.disable();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });

    return child;
  }
}

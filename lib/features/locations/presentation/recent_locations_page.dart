import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/modern_list_tile.dart';
import '../../settings/data/prefs_repository.dart';
import '../../times/presentation/times_page.dart';

class RecentLocationsPage extends ConsumerWidget {
  const RecentLocationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentLocations = ref.watch(prefsRepositoryProvider).getRecentLocations();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Son Konumlarım'),
      ),
      body: recentLocations.isEmpty
          ? const Center(
              child: Text('Henüz kayıtlı bir konum bulunmuyor.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: recentLocations.length,
              itemBuilder: (context, index) {
                final location = recentLocations[index];
                return ModernListTile(
                  title: '${location.sehir.sehirAdi} • ${location.ilce.ilceAdi}',
                  subtitle: location.ulke.ulkeAdi,
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => TimesPage(
                          ulke: location.ulke,
                          sehir: location.sehir,
                          ilce: location.ilce,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                );
              },
            ),
    );
  }
}

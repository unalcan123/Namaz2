import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/modern_list_tile.dart';
import '../data/location_providers.dart';
import '../data/models.dart';
import '../../settings/data/prefs_repository.dart';
import '../../times/presentation/times_page.dart';

final districtsProvider = FutureProvider.family<List<Ilce>, String>((ref, sehirId) async {
  final repo = ref.watch(locationRepoProvider);
  return repo.ilceler(sehirId);
});

class DistrictPage extends ConsumerStatefulWidget {
  final Ulke ulke;
  final Sehir sehir;
  const DistrictPage({super.key, required this.ulke, required this.sehir});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DistrictPageState();
}

class _DistrictPageState extends ConsumerState<DistrictPage> {
  String _searchQuery = '';

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => Card(
        child: Container(
          height: 70,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncDistricts = ref.watch(districtsProvider(widget.sehir.sehirId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.sehir.sehirAdi)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(labelText: 'İlçe Ara'),
            ),
          ),
          Expanded(
            child: asyncDistricts.when(
              loading: () => _buildLoadingSkeleton(),
              error: (e, _) => Center(child: Text("Hata: $e")),
              data: (ilceler) {
                final filteredList = ilceler.where((d) {
                  final query = _searchQuery.toLowerCase();
                  return d.ilceAdi.toLowerCase().contains(query) ||
                      d.ilceAdiEn.toLowerCase().contains(query);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: filteredList.length,
                  itemBuilder: (context, i) {
                    final d = filteredList[i];
                    return ModernListTile(
                      title: d.ilceAdi,
                      subtitle: d.ilceAdiEn,
                      accentColor: Colors.orange.shade300,
                      onTap: () async {
                        // Create a SavedLocation object and add it to recent locations
                        final savedLocation = SavedLocation(ulke: widget.ulke, sehir: widget.sehir, ilce: d);
                        await ref.read(prefsRepositoryProvider).addRecentLocation(savedLocation);
                        
                        if (!context.mounted) return;

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TimesPage(ulke: widget.ulke, sehir: widget.sehir, ilce: d),
                          ),
                          (route) => false, // Remove all previous routes
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

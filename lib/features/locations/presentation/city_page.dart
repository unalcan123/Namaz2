import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/modern_list_tile.dart';
import '../data/location_providers.dart'; // Updated import
import '../data/models.dart';
import 'district_page.dart';

final citiesProvider = FutureProvider.family<List<Sehir>, String>((ref, ulkeId) async {
  final repo = ref.watch(locationRepoProvider);
  return repo.sehirler(ulkeId);
});

class CityPage extends ConsumerStatefulWidget {
  final Ulke ulke;
  const CityPage({super.key, required this.ulke});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CityPageState();
}

class _CityPageState extends ConsumerState<CityPage> {
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
    final asyncCities = ref.watch(citiesProvider(widget.ulke.ulkeId));

    return Scaffold(
      appBar: AppBar(title: Text(widget.ulke.ulkeAdi)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(labelText: 'Şehir Ara'),
            ),
          ),
          Expanded(
            child: asyncCities.when(
              loading: () => _buildLoadingSkeleton(),
              error: (e, _) => Center(child: Text("Hata: $e")),
              data: (sehirler) {
                final filteredList = sehirler.where((s) {
                  final query = _searchQuery.toLowerCase();
                  return s.sehirAdi.toLowerCase().contains(query) ||
                      s.sehirAdiEn.toLowerCase().contains(query);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: filteredList.length,
                  itemBuilder: (context, i) {
                    final s = filteredList[i];
                    return ModernListTile(
                      title: s.sehirAdi,
                      subtitle: s.sehirAdiEn,
                      accentColor: Colors.teal.shade300,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DistrictPage(ulke: widget.ulke, sehir: s),
                          ),
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

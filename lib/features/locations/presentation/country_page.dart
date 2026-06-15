import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../flags.dart';
import '../../../widgets/modern_list_tile.dart';
import '../data/location_providers.dart'; // Updated import
import '../data/models.dart';
import 'city_page.dart';

final countriesProvider = FutureProvider<List<Ulke>>((ref) async {
  final repo = ref.watch(locationRepoProvider);
  return repo.ulkeler();
});

class CountryPage extends ConsumerStatefulWidget {
  const CountryPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CountryPageState();
}

class _CountryPageState extends ConsumerState<CountryPage> {
  String _searchQuery = '';
  final List<Color> _accentColors = [
    Colors.blue.shade300,
    Colors.green.shade300,
    Colors.orange.shade300,
    Colors.purple.shade300,
    Colors.red.shade300,
    Colors.teal.shade300,
  ];

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
    final asyncCountries = ref.watch(countriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Ülke Seç")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(labelText: 'Ülke Ara'),
            ),
          ),
          Expanded(
            child: asyncCountries.when(
              loading: () => _buildLoadingSkeleton(),
              error: (e, _) => Center(child: Text("Hata: $e")),
              data: (ulkeler) {
                final filteredList = ulkeler.where((u) {
                  final query = _searchQuery.toLowerCase();
                  return u.ulkeAdi.toLowerCase().contains(query) ||
                      u.ulkeAdiEn.toLowerCase().contains(query);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: filteredList.length,
                  itemBuilder: (context, i) {
                    final u = filteredList[i];
                    return ModernListTile(
                      title: u.ulkeAdi,
                      subtitle: u.ulkeAdiEn,
                      leading: FlagWidget(countryNameEn: u.ulkeAdiEn),
                      accentColor: _accentColors[i % _accentColors.length],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CityPage(ulke: u)),
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

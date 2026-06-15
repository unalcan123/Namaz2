import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'alert_settings_controller.dart';

String _prettyMusicName(String path) {
  String name = path.split('/').last.split('\\').last;
  if (name.toLowerCase().endsWith('.mp3')) {
    name = name.substring(0, name.length - 4);
  }
  return name;
}

class BgMusicSettingsPage extends ConsumerWidget {
  const BgMusicSettingsPage({super.key});

  /// assets/music/ klasöründeki tüm mp3 dosyalarını listeler
  Future<List<String>> _loadAppMusicAssets() async {
    try {
      final manifest = await _loadAssetManifest();
      final musicAssets = manifest.keys
          .where((key) => key.startsWith('assets/music/') && key.endsWith('.mp3'))
          .toList()
        ..sort();
      if (musicAssets.length > 1) return musicAssets;
    } catch (e) {
      debugPrint('Uygulama müzikleri yüklenirken hata: $e');
    }

    return List.generate(
      21,
      (index) => 'assets/music/Video download (${index + 1}).mp3',
    );
  }

  Future<Map<String, dynamic>> _loadAssetManifest() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      return json.decode(manifestContent) as Map<String, dynamic>;
    } catch (_) {
      final manifestContent = await rootBundle.loadString('AssetManifest.bin.json');
      return json.decode(manifestContent) as Map<String, dynamic>;
    }
  }

  /// Dosya adını yoldan çıkarır ve güzelleştirir
  String _prettyName(String path) => _prettyMusicName(path);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(alertSettingsProvider);
    final controller = ref.read(alertSettingsProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arka Plan Müziği'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8),
            child: Text('GENEL AYARLAR', style: textTheme.titleSmall?.copyWith(color: Colors.grey)),
          ),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.music_note),
              title: const Text('Arka Plan Müzik Çal'),
              subtitle: const Text('Seçilen müzikler sırayla ve döngüde çalar'),
              value: settings.bgMusicEnabled,
              onChanged: (value) => controller.toggleBgMusic(value),
            ),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8),
            child: Text('ÇALMA LİSTESİ', style: textTheme.titleSmall?.copyWith(color: Colors.grey)),
          ),
          Card(
            child: Column(
              children: [
                if (settings.bgMusicPaths.isEmpty)
                  const ListTile(title: Text('Liste boş')),
                ...settings.bgMusicPaths.map((path) => ListTile(
                      leading: Icon(path.startsWith('assets/') ? Icons.audiotrack : Icons.file_present),
                      title: Text(_prettyName(path)),
                      subtitle: Text(path.startsWith('assets/') ? 'Uygulama İçi' : 'Cihazdan'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => controller.removeBgMusicPath(path),
                      ),
                    )),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.library_music),
                  title: const Text('Uygulama Müziklerinden Ekle'),
                  onTap: () async {
                    final musicList = await _loadAppMusicAssets();
                    if (!context.mounted) return;
                    _showMultiSelectAsset(context, musicList, settings.bgMusicPaths, controller);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_to_drive),
                  title: const Text('Cihazdan Müzik Seç'),
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.audio,
                      allowMultiple: true,
                    );
                    if (result != null) {
                      final paths = result.paths.whereType<String>().toList();
                      controller.addBgMusicPaths(paths);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMultiSelectAsset(BuildContext context, List<String> assets, List<String> current, AlertSettingsNotifier controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MusicAssetPickerSheet(
        assets: assets,
        current: current,
        controller: controller,
      ),
    );
  }
}

class _MusicAssetPickerSheet extends StatefulWidget {
  final List<String> assets;
  final List<String> current;
  final AlertSettingsNotifier controller;

  const _MusicAssetPickerSheet({
    required this.assets,
    required this.current,
    required this.controller,
  });

  @override
  State<_MusicAssetPickerSheet> createState() => _MusicAssetPickerSheetState();
}

class _MusicAssetPickerSheetState extends State<_MusicAssetPickerSheet> {
  late final Set<String> _selectedPaths;

  @override
  void initState() {
    super.initState();
    _selectedPaths = widget.current.toSet();
  }

  Future<void> _addPath(String path) async {
    if (_selectedPaths.contains(path)) return;
    setState(() {
      _selectedPaths.add(path);
    });
    await widget.controller.addBgMusicPaths([path]);
  }

  Future<void> _addAllPaths() async {
    setState(() {
      _selectedPaths.addAll(widget.assets);
    });
    await widget.controller.addBgMusicPaths(widget.assets);
  }

  @override
  Widget build(BuildContext context) {
    final selectedAssetCount = widget.assets.where(_selectedPaths.contains).length;
    final allSelected = selectedAssetCount == widget.assets.length;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          AppBar(
            title: const Text('Müzik Seç'),
            actions: [
              TextButton(
                onPressed: allSelected ? null : _addAllPaths,
                child: const Text('Hepsini Ekle'),
              )
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              '$selectedAssetCount / ${widget.assets.length} müzik seçili',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: widget.assets.length,
              itemBuilder: (ctx, index) {
                final path = widget.assets[index];
                final isAdded = _selectedPaths.contains(path);
                return ListTile(
                  key: ValueKey(path),
                  selected: isAdded,
                  selectedTileColor: Colors.green.withValues(alpha: 0.08),
                  title: Text(_prettyMusicName(path)),
                  subtitle: Text(isAdded ? 'Çalma listesinde' : 'Eklenmedi'),
                  trailing: isAdded
                      ? const Chip(
                          avatar: Icon(Icons.check_circle, color: Colors.green, size: 18),
                          label: Text('Eklendi'),
                        )
                      : FilledButton.tonalIcon(
                          onPressed: () => _addPath(path),
                          icon: const Icon(Icons.add),
                          label: const Text('Ekle'),
                        ),
                  onTap: isAdded ? null : () => _addPath(path),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

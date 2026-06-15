import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/alert_settings.dart';
import 'alert_settings_controller.dart';
import 'theme_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(alertSettingsProvider);
    final alertController = ref.read(alertSettingsProvider.notifier);
    final themeMode = ref.watch(themeProvider);
    final themeController = ref.read(themeProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    final anyAlarmEnabled = settings.prayerAlarms.values.any((isEnabled) => isEnabled);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygulama Ayarları'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Theme Section ---
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8),
            child: Text('TEMA', style: textTheme.titleSmall?.copyWith(color: Colors.grey)),
          ),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Sistem Varsayılanı'),
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  onChanged: (value) => value != null ? themeController.setThemeMode(value) : null,
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: const Text('Açık Tema'),
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  onChanged: (value) => value != null ? themeController.setThemeMode(value) : null,
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: const Text('Koyu Tema'),
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: (value) => value != null ? themeController.setThemeMode(value) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Prayer Time Alarms ---
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8),
            child: Text('VAKİT GİRİNCE ALARMLAR', style: textTheme.titleSmall?.copyWith(color: Colors.grey)),
          ),
          Card(
            child: Column(
              children: prayerNames
                  .map((name) => SwitchListTile(
                        title: Text('$name Vakti Alarmı'),
                        value: settings.isPrayerEnabled(name),
                        onChanged: (value) => alertController.togglePrayerAlarm(name, value),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),

          // --- Pre-Notification Alarms ---
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8),
            child: Text('SON YARIM SAAT UYARILARI', style: textTheme.titleSmall?.copyWith(color: Colors.grey)),
          ),
          Card(
            child: Column(
              children: preNotificationMinutes
                  .map((minute) => SwitchListTile(
                        title: Text('$minute Dakika Kala Uyar'),
                        subtitle: const Text('İmsak hariç tüm vakitler için'),
                        value: settings.isPreNotificationEnabled(minute),
                        onChanged: (value) => alertController.togglePreNotification(minute, value),
                      ))
                  .toList(),
            ),
          ),

          // --- Conditional Alarm Type ---
          if (anyAlarmEnabled) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8),
              child: Text('VAKİT GİRİNCE ALARM TÜRÜ', style: textTheme.titleSmall?.copyWith(color: Colors.grey)),
            ),
            Card(
              child: Column(
                children: AlertType.values
                    .map((type) => RadioListTile<AlertType>(
                          title: Text(type.displayName),
                          value: type,
                          groupValue: settings.alertType,
                          onChanged: (value) => value != null ? alertController.setAlertType(value) : null,
                        ))
                    .toList(),
              ),
            ),
          ],

          // --- Conditional Custom Audio ---
          if (settings.alertType == AlertType.custom && anyAlarmEnabled) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8),
              child: Text('ÖZEL SES DOSYALARI', style: textTheme.titleSmall?.copyWith(color: Colors.grey)),
            ),
            Card(
              child: Column(
                children: [
                  ...settings.customAudioPaths.map((path) {
                    final fileName = path.split('/').last;
                    final isSelected = settings.selectedCustomAudioPath == path;

                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(fileName, overflow: TextOverflow.ellipsis),
                      subtitle: isSelected ? const Text('Seçili', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)) : null,
                      onTap: () => alertController.selectCustomAudio(path),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: path,
                            groupValue: settings.selectedCustomAudioPath,
                            onChanged: (v) {
                              if (v != null) alertController.selectCustomAudio(v);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => alertController.removeCustomAudio(path),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Yeni Ses Ekle...'),
                    onTap: () => alertController.pickCustomAudio(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

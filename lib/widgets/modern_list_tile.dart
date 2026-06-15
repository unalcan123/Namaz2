import 'package:flutter/material.dart';

class ModernListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback onTap;
  final Color accentColor;

  const ModernListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.onTap,
    this.accentColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 5,
              color: accentColor.withValues(alpha: 0.7),
            ),
            Expanded(
              child: ListTile(
                leading: leading,
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: subtitle != null ? Text(subtitle!) : null,
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

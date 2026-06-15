import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

Future<Uint8List> readLocalFileBytes(String path) {
  return File(path).readAsBytes();
}

Future<String> saveUserImageBytes(String category, Uint8List bytes) async {
  final appDir = await getApplicationDocumentsDirectory();
  final categoryDir = Directory('${appDir.path}/userImages/$category');

  if (!await categoryDir.exists()) {
    await categoryDir.create(recursive: true);
  }

  final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
  final file = File('${categoryDir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<List<String>> listUserImagePaths(String category) async {
  final appDir = await getApplicationDocumentsDirectory();
  final categoryDir = Directory('${appDir.path}/userImages/$category');

  if (!await categoryDir.exists()) return [];

  return categoryDir.listSync().whereType<File>().where((file) {
    final p = file.path.toLowerCase();
    return p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.png') ||
        p.endsWith('.webp');
  }).map((file) => file.path).toList();
}

Future<void> deleteLocalFile(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}

ImageProvider localFileImageProvider(String path) => FileImage(File(path));

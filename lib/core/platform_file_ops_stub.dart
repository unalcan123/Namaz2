import 'dart:typed_data';

import 'package:flutter/widgets.dart';

Future<Uint8List> readLocalFileBytes(String path) {
  throw UnsupportedError('Local files are not available on this platform.');
}

Future<String> saveUserImageBytes(String category, Uint8List bytes) {
  throw UnsupportedError('Local files are not available on this platform.');
}

Future<List<String>> listUserImagePaths(String category) async => [];

Future<void> deleteLocalFile(String path) async {}

ImageProvider localFileImageProvider(String path) {
  throw UnsupportedError('Local files are not available on this platform.');
}

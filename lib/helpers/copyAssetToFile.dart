import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

Future<String> copyAssetToFile(String assetPath, String fileName) async {
  final byteData = await rootBundle.load(assetPath);
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$fileName');

  await file.writeAsBytes(byteData.buffer.asUint8List());

  return file.path;
}

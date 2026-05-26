import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/clip_item.dart';

class StorageService {
  static late Directory _appDir;
  static late File _clipsFile;
  static late Directory _imagesDir;

  static Future<void> initialize() async {
    final docs = await getApplicationDocumentsDirectory();
    _appDir = Directory('${docs.path}\\clipped');
    _imagesDir = Directory('${_appDir.path}\\images');
    _clipsFile = File('${_appDir.path}\\clips.json');

    await _imagesDir.create(recursive: true);
    if (!await _clipsFile.exists()) {
      await _clipsFile.writeAsString('[]');
    }
  }

  static Future<List<ClipItem>> loadClips() async {
    try {
      final content = await _clipsFile.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list
          .map((e) => ClipItem.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveClips(List<ClipItem> clips) async {
    final json = jsonEncode(clips.map((e) => e.toJson()).toList());
    await _clipsFile.writeAsString(json);
  }

  static Future<String> saveImage(Uint8List pngBytes) async {
    final id = const Uuid().v4();
    final file = File('${_imagesDir.path}\\$id.png');
    await file.writeAsBytes(pngBytes);
    return file.path;
  }

  static Future<Uint8List?> loadImage(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteImage(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  static Future<void> clearAll(List<ClipItem> clips) async {
    for (final item in clips) {
      await deleteImage(item.imagePath);
    }
    await _clipsFile.writeAsString('[]');
  }
}

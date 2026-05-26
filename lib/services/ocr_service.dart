import 'package:flutter/services.dart';

class OcrService {
  static const _channel = MethodChannel('com.clipped/native');

  static Future<String?> recognizeFromFile(String imagePath) async {
    try {
      final result = await _channel.invokeMethod<String>('ocrRecognize', {
        'path': imagePath,
      });
      final text = result?.trim();
      return (text == null || text.isEmpty) ? null : text;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('[OCR] ${e.code}: ${e.message}');
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('[OCR] $e');
      return null;
    }
  }
}

import 'package:flutter/services.dart';

class PasteService {
  static const _channel = MethodChannel('com.clipped/native');

  static Future<void> captureFocus() async {
    try {
      await _channel.invokeMethod('captureFocus');
    } catch (_) {}
  }

  static Future<void> restoreAndPaste() async {
    try {
      await _channel.invokeMethod('restoreAndPaste');
    } catch (_) {}
  }

  static Future<void> writeImageToClipboard(String imagePath) async {
    try {
      await _channel.invokeMethod('writeImageToClipboard', {'path': imagePath});
    } catch (_) {}
  }
}

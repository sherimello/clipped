import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:win32/win32.dart';

typedef ClipboardCallback = void Function(
    String type, String? text, Uint8List? imageBytes, int? width, int? height);

class ClipboardService {
  static ClipboardCallback? onClipboardChanged;
  static bool _isOurWrite = false;
  static Timer? _monitorTimer;
  static String _lastSignature = '';
  static int _pngFormatId = 0;

  static void _ensurePngFormatId() {
    if (_pngFormatId != 0) return;
    using((Arena arena) {
      final ptr = 'PNG'.toNativeUtf16(allocator: arena);
      _pngFormatId = RegisterClipboardFormat(ptr);
    });
  }

  static void startMonitoring() {
    _ensurePngFormatId();
    _monitorTimer =
        Timer.periodic(const Duration(milliseconds: 600), (_) async {
      if (_isOurWrite) return;
      await _checkClipboard();
    });
  }

  static void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  static Future<void> _checkClipboard() async {
    try {
      final result = _readClipboard();
      if (result == null) return;

      final (type, text, imageBytes, width, height) = result;

      if ((type == 'text' || type == 'url') && text != null) {
        if (text == _lastSignature) return;
        _lastSignature = text;
        onClipboardChanged?.call(type, text, null, null, null);
      } else if (type == 'image' && imageBytes != null) {
        final sig = '__img__${imageBytes.length}';
        if (sig == _lastSignature) return;
        _lastSignature = sig;
        onClipboardChanged?.call('image', null, imageBytes, width, height);
      }
    } catch (_) {}
  }

  static (String, String?, Uint8List?, int?, int?)? _readClipboard() {
    if (OpenClipboard(0) == 0) return null;

    try {
      // ── PNG image ────────────────────────────────────────────────────────
      if (_pngFormatId != 0 &&
          IsClipboardFormatAvailable(_pngFormatId) != 0) {
        final hData = GetClipboardData(_pngFormatId);
        if (hData != 0) {
          final hPtr = Pointer<NativeType>.fromAddress(hData);
          final size = GlobalSize(hPtr);
          final dataPtr = GlobalLock(hPtr);
          if (dataPtr.address != 0) {
            try {
              final bytes = Uint8List.fromList(
                  dataPtr.cast<Uint8>().asTypedList(size));
              final decoded = img.decodePng(bytes);
              return ('image', null, bytes, decoded?.width, decoded?.height);
            } finally {
              GlobalUnlock(hPtr);
            }
          }
        }
      }

      // ── DIB bitmap ───────────────────────────────────────────────────────
      if (IsClipboardFormatAvailable(CF_DIB) != 0) {
        final hData = GetClipboardData(CF_DIB);
        if (hData != 0) {
          final hPtr = Pointer<NativeType>.fromAddress(hData);
          final size = GlobalSize(hPtr);
          final dataPtr = GlobalLock(hPtr);
          if (dataPtr.address != 0) {
            try {
              final dibBytes = Uint8List.fromList(
                  dataPtr.cast<Uint8>().asTypedList(size));
              final pngBytes = _dibToPng(dibBytes);
              if (pngBytes != null) {
                final decoded = img.decodePng(pngBytes);
                return ('image', null, pngBytes, decoded?.width,
                    decoded?.height);
              }
            } finally {
              GlobalUnlock(hPtr);
            }
          }
        }
      }

      // ── Unicode text ──────────────────────────────────────────────────────
      if (IsClipboardFormatAvailable(CF_UNICODETEXT) != 0) {
        final hData = GetClipboardData(CF_UNICODETEXT);
        if (hData != 0) {
          final hPtr = Pointer<NativeType>.fromAddress(hData);
          final dataPtr = GlobalLock(hPtr);
          if (dataPtr.address != 0) {
            try {
              final text = dataPtr.cast<Utf16>().toDartString();
              if (text.isNotEmpty) {
                final type = _isUrl(text) ? 'url' : 'text';
                return (type, text, null, null, null);
              }
            } finally {
              GlobalUnlock(hPtr);
            }
          }
        }
      }

      return null;
    } finally {
      CloseClipboard();
    }
  }

  // ── DIB → PNG conversion ─────────────────────────────────────────────────

  static Uint8List? _dibToPng(Uint8List dib) {
    try {
      if (dib.length < 40) return null;
      final width = _i32(dib, 4);
      final height = _i32(dib, 8);
      final bitCount = _u16(dib, 14);
      final compression = _u32(dib, 16);
      if (compression != 0 && compression != 3) return null;
      if (bitCount != 24 && bitCount != 32) return null;

      final headerSize = _u32(dib, 0);
      final colorsUsed = _u32(dib, 32);
      final paletteOffset = headerSize + colorsUsed * 4;
      final bytesPerRow = ((width * bitCount + 31) ~/ 32) * 4;
      final absHeight = height.abs();

      if (paletteOffset + bytesPerRow * absHeight > dib.length) return null;

      final image = img.Image(width: width, height: absHeight);
      final bottomUp = height > 0;

      for (int y = 0; y < absHeight; y++) {
        final srcY = bottomUp ? (absHeight - 1 - y) : y;
        final rowOffset = paletteOffset + srcY * bytesPerRow;
        for (int x = 0; x < width; x++) {
          final p = rowOffset + x * (bitCount ~/ 8);
          if (p + (bitCount ~/ 8) > dib.length) break;
          final b = dib[p], g = dib[p + 1], r = dib[p + 2];
          final a = bitCount == 32 ? dib[p + 3] : 255;
          image.setPixelRgba(x, y, r, g, b, a);
        }
      }
      return Uint8List.fromList(img.encodePng(image));
    } catch (_) {
      return null;
    }
  }

  static int _i32(Uint8List b, int o) {
    final v = _u32(b, o);
    return v > 0x7FFFFFFF ? v - 0x100000000 : v;
  }

  static int _u32(Uint8List b, int o) =>
      b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24);

  static int _u16(Uint8List b, int o) => b[o] | (b[o + 1] << 8);

  static bool _isUrl(String text) {
    final t = text.trim();
    if (t.contains('\n')) return false;
    return t.startsWith('http://') ||
        t.startsWith('https://') ||
        t.startsWith('www.');
  }

  static Future<void> writeTextToClipboard(String text) async {
    _isOurWrite = true;
    _lastSignature = text;
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } finally {
      Future.delayed(
          const Duration(milliseconds: 800), () => _isOurWrite = false);
    }
  }

  static void suppressNextChange() {
    _isOurWrite = true;
    Future.delayed(
        const Duration(milliseconds: 800), () => _isOurWrite = false);
  }

  // Call after writing an image to clipboard so the monitor won't re-add it.
  // pngLength must be the byte length of the PNG file that was written.
  static void suppressImageWrite(int pngLength) {
    _isOurWrite = true;
    _lastSignature = '__img__$pngLength';
    Future.delayed(
        const Duration(milliseconds: 1200), () => _isOurWrite = false);
  }
}

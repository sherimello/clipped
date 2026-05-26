import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class StartupService {
  static const _subKey = r'Software\Microsoft\Windows\CurrentVersion\Run';
  static const _valueName = 'Clipped';

  static bool isEnabled() {
    return using((Arena arena) {
      final hKey = arena<IntPtr>();
      final ret = RegOpenKeyEx(
        HKEY_CURRENT_USER,
        _subKey.toNativeUtf16(allocator: arena),
        0,
        KEY_READ,
        hKey,
      );
      if (ret != ERROR_SUCCESS) return false;
      final cbData = arena<Uint32>()..value = 0;
      final qret = RegQueryValueEx(
        hKey.value,
        _valueName.toNativeUtf16(allocator: arena),
        nullptr,
        nullptr,
        nullptr,
        cbData,
      );
      RegCloseKey(hKey.value);
      return qret == ERROR_SUCCESS;
    });
  }

  static void setEnabled(bool enabled) {
    using((Arena arena) {
      final hKey = arena<IntPtr>();
      final ret = RegOpenKeyEx(
        HKEY_CURRENT_USER,
        _subKey.toNativeUtf16(allocator: arena),
        0,
        KEY_WRITE,
        hKey,
      );
      if (ret != ERROR_SUCCESS) return;
      final valueName = _valueName.toNativeUtf16(allocator: arena);
      if (enabled) {
        final exePath = '"${Platform.resolvedExecutable}"';
        final valueData = exePath.toNativeUtf16(allocator: arena);
        RegSetValueEx(
          hKey.value,
          valueName,
          0,
          REG_SZ,
          valueData.cast<Uint8>(),
          (exePath.length + 1) * 2,
        );
      } else {
        RegDeleteValue(hKey.value, valueName);
      }
      RegCloseKey(hKey.value);
    });
  }
}

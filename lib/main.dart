import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'services/hotkey_service.dart';
import 'services/paste_service.dart';
import 'services/storage_service.dart';
import 'services/tray_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Storage must be ready before the provider initializes
  await StorageService.initialize();

  // Window & acrylic effect initialization (order matters)
  await Window.initialize();
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    size: Size(960, 620),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await Window.setEffect(
      effect: WindowEffect.transparent,
      color: const Color(0x00000000),
      dark: true,
    );
    await windowManager.setAsFrameless();
    await windowManager.setResizable(false);
    await windowManager.hide();
  });

  // System tray
  await TrayService.initialize();

  // Global hotkey Alt+C — capture focus first, then toggle visibility
  await HotkeyService.initialize(() async {
    await PasteService.captureFocus();
    final isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  });

  runApp(const ClippedApp());
}

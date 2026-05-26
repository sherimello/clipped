import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class TrayService {
  static final SystemTray _systemTray = SystemTray();

  static Future<void> initialize() async {
    await _systemTray.initSystemTray(
      iconPath: 'assets/icons/tray_icon.ico',
      toolTip: 'Clipped — Clipboard Manager\nAlt+C to open',
    );

    final menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: 'Show Clipped',
        onClicked: (_) async {
          await windowManager.show();
          await windowManager.focus();
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Settings',
        onClicked: (_) async {
          await windowManager.show();
          await windowManager.focus();
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Quit',
        onClicked: (_) async {
          await windowManager.destroy();
        },
      ),
    ]);

    await _systemTray.setContextMenu(menu);

    _systemTray.registerSystemTrayEventHandler((eventName) async {
      if (eventName == kSystemTrayEventClick) {
        final isVisible = await windowManager.isVisible();
        if (isVisible) {
          await windowManager.hide();
        } else {
          await windowManager.show();
          await windowManager.focus();
        }
      } else if (eventName == kSystemTrayEventRightClick) {
        await _systemTray.popUpContextMenu();
      }
    });
  }

  static Future<void> dispose() async {
    await _systemTray.destroy();
  }
}

<div align="center">
  <img src="assets/images/clipped logo.png" width="96" height="96" alt="Clipped logo" />
  <h1>Clipped</h1>
  <p>A beautiful, offline-first clipboard manager for Windows.</p>

  ![Platform](https://img.shields.io/badge/platform-Windows%2010%2B-blue?style=flat-square)
  ![Flutter](https://img.shields.io/badge/Flutter-3.41-54C5F8?style=flat-square&logo=flutter)
  ![Version](https://img.shields.io/badge/version-1.0.0-success?style=flat-square)
  ![License](https://img.shields.io/badge/license-MIT-orange?style=flat-square)
</div>

---

Clipped lives in your system tray and remembers everything you copy — text, links, and images. Press **Alt+C** to summon it instantly, click any item to paste it, and it's gone. No cloud, no telemetry, no subscriptions.

## Features

| | |
|---|---|
| **Alt+C Global Hotkey** | Show or hide the window from anywhere, instantly |
| **Text, URL & Image History** | Captures all three types automatically as you copy |
| **Offline OCR** | Extracts text from copied images using Windows.Media.Ocr — no internet required |
| **Pins** | Pin items you want to keep forever, safe from history clearing |
| **Tags** | Organize clips with custom labels and browse by tag |
| **Full-text Search** | Searches text content, OCR results, and tags simultaneously |
| **Instant Paste** | Click an item → window hides → content pastes directly into your active app |
| **Theme Tints** | Four dark themes: Void, Midnight, Forest, Grape |
| **Launch at Startup** | Optional autostart with Windows |
| **100% Offline & Private** | Everything stored locally in `Documents\clipped\` as plain JSON |

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Alt + C` | Show / hide Clipped |
| `Esc` | Hide Clipped |

## Installation

Download the latest installer from [Releases](../../releases/latest):

```
Clipped-Setup-1.0.0.exe
```

Run it and follow the wizard. No admin rights required for a per-user install.

**System requirements:** Windows 10 version 1809 or later, 64-bit.

## Building from Source

**Prerequisites**

- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) 3.41+
- Visual Studio 2022 with the **Desktop development with C++** workload
- Windows 10 SDK 10.0.17763 or later

**Steps**

```powershell
git clone https://github.com/thabtat/clipped.git
cd clipped
flutter pub get
flutter build windows --release
```

The built app lands in:
```
build\windows\x64\runner\Release\
```

**Regenerate the installer** (requires [Inno Setup 6](https://jrsoftware.org/isinfo.php)):

```powershell
flutter build windows --release
& "C:\...\Inno Setup 6\iscc.exe" installer\clipped_setup.iss
# → dist\Clipped-Setup-1.0.0.exe
```

## How It Works

Clipped polls the Windows clipboard every 600 ms using `win32` FFI to read Unicode text and PNG/DIB images. When you click an item, it writes the content back to the clipboard and uses `AttachThreadInput` + `SendInput` (Ctrl+V) via a native C++ channel to paste into the previously focused window.

OCR runs on a background thread via the WinRT `Windows.Media.Ocr` API — fully local, no network calls ever.

All data is persisted to `Documents\clipped\clips.json`. Copied images are saved to `Documents\clipped\images\` as PNG files referenced by the JSON entries.

## Data & Privacy

Clipped makes **zero network requests**. All clipboard data stays on your machine. Uninstalling and deleting `Documents\clipped\` removes everything completely.

## License

MIT © 2026 [Thabat Inc.](https://github.com/thabtat)

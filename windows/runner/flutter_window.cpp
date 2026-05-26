#include "flutter_window.h"

#include <dwmapi.h>
#pragma comment(lib, "dwmapi.lib")
#include <fstream>
#include <optional>
#include <thread>
#include <vector>
#include <string>
#include <memory>

// WinRT headers for OCR
#define WINRT_LEAN_AND_MEAN
#include <unknwn.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Globalization.h>
#include <winrt/Windows.Media.Ocr.h>
#include <winrt/Windows.Graphics.Imaging.h>
#include <winrt/Windows.Storage.Streams.h>

// GDI+ for image clipboard operations
#include <gdiplus.h>
#pragma comment(lib, "gdiplus.lib")
#pragma comment(lib, "WindowsApp.lib")

#include "flutter/generated_plugin_registrant.h"


static HWND g_prev_foreground_window = nullptr;
static ULONG_PTR g_gdiplus_token = 0;

static std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) return {};
  int size = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, nullptr, 0);
  std::wstring result(size, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, result.data(), size);
  return result;
}

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {
  // Initialize GDI+ once
  Gdiplus::GdiplusStartupInput input;
  Gdiplus::GdiplusStartup(&g_gdiplus_token, &input, nullptr);
}

FlutterWindow::~FlutterWindow() {
  if (g_gdiplus_token) {
    Gdiplus::GdiplusShutdown(g_gdiplus_token);
    g_gdiplus_token = 0;
  }
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) return false;

  // Remove the Windows 11 DWM 1px window border (DWMWA_BORDER_COLOR = 34,
  // DWMWA_COLOR_NONE = 0xFFFFFFFE).
  COLORREF no_border = 0xFFFFFFFE;
  DwmSetWindowAttribute(GetHandle(), 34, &no_border, sizeof(no_border));

  RECT frame = GetClientArea();
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);

  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }

  RegisterPlugins(flutter_controller_->engine());

  // ── Native method channel ────────────────────────────────────────────────
  auto* messenger = flutter_controller_->engine()->messenger();
  native_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.clipped/native",
      &flutter::StandardMethodCodec::GetInstance());

  native_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

        // ── captureFocus ─────────────────────────────────────────────────
        if (call.method_name() == "captureFocus") {
          g_prev_foreground_window = GetForegroundWindow();
          result->Success();
          return;
        }

        // ── restoreAndPaste ───────────────────────────────────────────────
        if (call.method_name() == "restoreAndPaste") {
          if (g_prev_foreground_window && IsWindow(g_prev_foreground_window)) {
            DWORD fg_thread = GetWindowThreadProcessId(g_prev_foreground_window, nullptr);
            DWORD cur_thread = GetCurrentThreadId();
            AttachThreadInput(cur_thread, fg_thread, TRUE);
            SetForegroundWindow(g_prev_foreground_window);
            AttachThreadInput(cur_thread, fg_thread, FALSE);
            Sleep(80);
          }
          // Ctrl+V
          INPUT inputs[4] = {};
          inputs[0].type = INPUT_KEYBOARD; inputs[0].ki.wVk = VK_CONTROL;
          inputs[1].type = INPUT_KEYBOARD; inputs[1].ki.wVk = 'V';
          inputs[2].type = INPUT_KEYBOARD; inputs[2].ki.wVk = 'V';
          inputs[2].ki.dwFlags = KEYEVENTF_KEYUP;
          inputs[3].type = INPUT_KEYBOARD; inputs[3].ki.wVk = VK_CONTROL;
          inputs[3].ki.dwFlags = KEYEVENTF_KEYUP;
          SendInput(4, inputs, sizeof(INPUT));
          result->Success();
          return;
        }

        // ── writeImageToClipboard ─────────────────────────────────────────
        if (call.method_name() == "writeImageToClipboard") {
          const auto* args =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (!args) {
            result->Error("INVALID_ARGS", "Expected map");
            return;
          }
          auto it = args->find(flutter::EncodableValue("path"));
          if (it == args->end()) {
            result->Error("NO_PATH", "Missing path");
            return;
          }
          const auto* path_str = std::get_if<std::string>(&it->second);
          if (!path_str) {
            result->Error("INVALID_PATH", "Path must be string");
            return;
          }

          std::wstring wide_path = Utf8ToWide(*path_str);

          // Read raw PNG bytes so we can write both CF_BITMAP and PNG format.
          // The Dart-side monitor reads PNG format first, so its dedup
          // signature will match _lastSignature and no duplicate is added.
          std::vector<uint8_t> png_bytes;
          {
            std::ifstream f(wide_path, std::ios::binary | std::ios::ate);
            if (f.is_open()) {
              auto sz = f.tellg();
              if (sz > 0) {
                png_bytes.resize(static_cast<size_t>(sz));
                f.seekg(0);
                f.read(reinterpret_cast<char*>(png_bytes.data()),
                       static_cast<std::streamsize>(sz));
              }
            }
          }

          Gdiplus::Bitmap* bmp = new Gdiplus::Bitmap(wide_path.c_str());
          HBITMAP hBitmap = nullptr;
          if (bmp && bmp->GetLastStatus() == Gdiplus::Ok) {
            bmp->GetHBITMAP(Gdiplus::Color(0, 0, 0, 0), &hBitmap);
          }
          delete bmp;

          if (OpenClipboard(nullptr)) {
            EmptyClipboard();
            if (hBitmap) {
              SetClipboardData(CF_BITMAP, hBitmap);
            }
            if (!png_bytes.empty()) {
              UINT png_fmt = RegisterClipboardFormatW(L"PNG");
              HGLOBAL hg = GlobalAlloc(GMEM_MOVEABLE, png_bytes.size());
              if (hg) {
                auto* ptr = GlobalLock(hg);
                std::memcpy(ptr, png_bytes.data(), png_bytes.size());
                GlobalUnlock(hg);
                SetClipboardData(png_fmt, hg);
              }
            }
            CloseClipboard();
          }
          result->Success();
          return;
        }

        // ── ocrRecognize ──────────────────────────────────────────────────
        if (call.method_name() == "ocrRecognize") {
          const auto* args =
              std::get_if<flutter::EncodableMap>(call.arguments());
          if (!args) { result->Error("INVALID_ARGS", "Expected map"); return; }

          auto it = args->find(flutter::EncodableValue("path"));
          if (it == args->end()) { result->Error("NO_PATH", "Missing path"); return; }
          const auto* path_str = std::get_if<std::string>(&it->second);
          if (!path_str) { result->Error("BAD_PATH", "Path must be string"); return; }

          std::wstring wide_path = Utf8ToWide(*path_str);

          // Read raw PNG bytes from disk
          std::vector<uint8_t> png_bytes;
          {
            std::ifstream f(wide_path, std::ios::binary | std::ios::ate);
            if (!f.is_open()) {
              result->Error("FILE_ERR", "Cannot open image file");
              return;
            }
            auto sz = f.tellg();
            if (sz <= 0) {
              result->Error("FILE_ERR", "Empty image file");
              return;
            }
            png_bytes.resize(static_cast<size_t>(sz));
            f.seekg(0);
            f.read(reinterpret_cast<char*>(png_bytes.data()),
                   static_cast<std::streamsize>(sz));
          }

          auto result_ptr = std::make_shared<
              std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>>(
              std::move(result));

          std::thread([png_bytes = std::move(png_bytes), result_ptr]() mutable {
            try {
              winrt::init_apartment(winrt::apartment_type::multi_threaded);

              // Write PNG bytes into an in-memory WinRT stream
              winrt::Windows::Storage::Streams::InMemoryRandomAccessStream stream;
              {
                winrt::Windows::Storage::Streams::DataWriter writer(stream);
                writer.WriteBytes(winrt::array_view<const uint8_t>(
                    png_bytes.data(),
                    static_cast<uint32_t>(png_bytes.size())));
                writer.StoreAsync().get();
                writer.DetachStream();
              }
              stream.Seek(0);
              png_bytes.clear();

              // Decode PNG → SoftwareBitmap using WinRT BitmapDecoder
              auto decoder = winrt::Windows::Graphics::Imaging::BitmapDecoder::
                  CreateAsync(stream).get();

              uint32_t imgW = decoder.PixelWidth();
              uint32_t imgH = decoder.PixelHeight();

              // Honour the engine's maximum dimension limit
              uint32_t maxDim =
                  winrt::Windows::Media::Ocr::OcrEngine::MaxImageDimension();
              uint32_t outW = imgW, outH = imgH;
              if (imgW > maxDim || imgH > maxDim) {
                double scale =
                    static_cast<double>(maxDim) / std::max(imgW, imgH);
                outW = static_cast<uint32_t>(imgW * scale);
                outH = static_cast<uint32_t>(imgH * scale);
              }

              winrt::Windows::Graphics::Imaging::BitmapTransform transform;
              transform.ScaledWidth(outW);
              transform.ScaledHeight(outH);

              auto softBitmap = decoder.GetSoftwareBitmapAsync(
                  winrt::Windows::Graphics::Imaging::BitmapPixelFormat::Bgra8,
                  winrt::Windows::Graphics::Imaging::BitmapAlphaMode::
                      Premultiplied,
                  transform,
                  winrt::Windows::Graphics::Imaging::ExifOrientationMode::
                      IgnoreExifOrientation,
                  winrt::Windows::Graphics::Imaging::ColorManagementMode::
                      DoNotColorManage).get();

              // Try user's language, fall back to English, then any installed
              winrt::Windows::Media::Ocr::OcrEngine engine{nullptr};
              engine = winrt::Windows::Media::Ocr::OcrEngine::
                  TryCreateFromUserProfileLanguages();
              if (!engine) {
                try {
                  engine = winrt::Windows::Media::Ocr::OcrEngine::
                      TryCreateFromLanguage(
                          winrt::Windows::Globalization::Language(L"en"));
                } catch (...) {}
              }
              if (!engine) {
                auto langs = winrt::Windows::Media::Ocr::OcrEngine::
                    AvailableRecognizerLanguages();
                if (langs.Size() > 0) {
                  engine = winrt::Windows::Media::Ocr::OcrEngine::
                      TryCreateFromLanguage(langs.GetAt(0));
                }
              }
              if (!engine) {
                (*result_ptr)->Error("NO_ENGINE",
                    "No OCR language pack installed. Install an English language"
                    " pack in Windows Settings > Time & Language > Language.");
                return;
              }

              auto ocr_result = engine.RecognizeAsync(softBitmap).get();
              std::string text = winrt::to_string(ocr_result.Text());
              (*result_ptr)->Success(flutter::EncodableValue(text));

            } catch (const winrt::hresult_error& ex) {
              (*result_ptr)->Error("HRESULT_ERR",
                                   winrt::to_string(ex.message()));
            } catch (const std::exception& ex) {
              (*result_ptr)->Error("STD_ERR", ex.what());
            } catch (...) {
              (*result_ptr)->Error("UNKNOWN_ERR", "OCR failed unexpectedly");
            }
          }).detach();

          return;
        }

        result->NotImplemented();
      });

  // ── Show Flutter window after first frame ────────────────────────────────
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  flutter_controller_->engine()->SetNextFrameCallback([&]() { this->Show(); });
  flutter_controller_->ForceRedraw();
  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) flutter_controller_ = nullptr;
  Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) return *result;
  }
  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }
  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

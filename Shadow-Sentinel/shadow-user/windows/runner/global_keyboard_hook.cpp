#include "global_keyboard_hook.h"

#include <flutter/encodable_value.h>
#include <iostream>
#include <map>

// Static members
HHOOK GlobalKeyboardHook::hook_handle_ = nullptr;
std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>>
    GlobalKeyboardHook::channel_ = nullptr;

void GlobalKeyboardHook::Register(flutter::FlutterEngine *engine)
{
  // Create the method channel
  channel_ = std::make_shared<flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), "com.shadow_sentinel/global_keyboard",
      &flutter::StandardMethodCodec::GetInstance());

  // Handle method calls from Dart
  channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue> &call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result)
      {
        if (call.method_name() == "startHook")
        {
          if (hook_handle_ == nullptr)
          {
            hook_handle_ = SetWindowsHookEx(
                WH_KEYBOARD_LL, LowLevelKeyboardProc, nullptr, 0);
            if (hook_handle_)
            {
              result->Success(flutter::EncodableValue(true));
            }
            else
            {
              result->Error("HOOK_FAILED",
                            "Failed to install keyboard hook");
            }
          }
          else
          {
            result->Success(flutter::EncodableValue(true)); // already hooked
          }
        }
        else if (call.method_name() == "stopHook")
        {
          Unregister();
          result->Success(flutter::EncodableValue(true));
        }
        else if (call.method_name() == "getForegroundWindow")
        {
          result->Success(
              flutter::EncodableValue(GetForegroundWindowTitle()));
        }
        else
        {
          result->NotImplemented();
        }
      });
}

void GlobalKeyboardHook::Unregister()
{
  if (hook_handle_)
  {
    UnhookWindowsHookEx(hook_handle_);
    hook_handle_ = nullptr;
  }
}

LRESULT CALLBACK GlobalKeyboardHook::LowLevelKeyboardProc(int nCode,
                                                          WPARAM wParam,
                                                          LPARAM lParam)
{
  if (nCode == HC_ACTION && channel_)
  {
    KBDLLHOOKSTRUCT *kbd = reinterpret_cast<KBDLLHOOKSTRUCT *>(lParam);
    bool isDown =
        (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN);
    bool isUp =
        (wParam == WM_KEYUP || wParam == WM_SYSKEYUP);

    if (isDown || isUp)
    {
      std::string keyLabel = VkCodeToString(kbd->vkCode);
      std::string foregroundWindow = GetForegroundWindowTitle();

      flutter::EncodableMap eventData;
      eventData[flutter::EncodableValue("key")] =
          flutter::EncodableValue(keyLabel);
      eventData[flutter::EncodableValue("isDown")] =
          flutter::EncodableValue(isDown);
      eventData[flutter::EncodableValue("vkCode")] =
          flutter::EncodableValue(static_cast<int>(kbd->vkCode));
      eventData[flutter::EncodableValue("timestamp")] =
          flutter::EncodableValue(static_cast<int64_t>(kbd->time));
      eventData[flutter::EncodableValue("foregroundWindow")] =
          flutter::EncodableValue(foregroundWindow);

      // Invoke on the Dart side (fire-and-forget)
      channel_->InvokeMethod(
          "onGlobalKey",
          std::make_unique<flutter::EncodableValue>(
              flutter::EncodableValue(eventData)));
    }
  }
  return CallNextHookEx(hook_handle_, nCode, wParam, lParam);
}

std::string GlobalKeyboardHook::VkCodeToString(DWORD vkCode)
{
  // Map common virtual key codes to readable labels
  switch (vkCode)
  {
  case VK_BACK:
    return "Backspace";
  case VK_TAB:
    return "Tab";
  case VK_RETURN:
    return "Enter";
  case VK_SHIFT:
  case VK_LSHIFT:
  case VK_RSHIFT:
    return "Shift";
  case VK_CONTROL:
  case VK_LCONTROL:
  case VK_RCONTROL:
    return "Control";
  case VK_MENU:
  case VK_LMENU:
  case VK_RMENU:
    return "Alt";
  case VK_CAPITAL:
    return "CapsLock";
  case VK_ESCAPE:
    return "Escape";
  case VK_SPACE:
    return " ";
  case VK_DELETE:
    return "Delete";
  case VK_OEM_PERIOD:
    return ".";
  case VK_OEM_COMMA:
    return ",";
  case VK_OEM_1:
    return ";";
  case VK_OEM_2:
    return "/";
  case VK_OEM_3:
    return "`";
  case VK_OEM_4:
    return "[";
  case VK_OEM_5:
    return "\\";
  case VK_OEM_6:
    return "]";
  case VK_OEM_7:
    return "'";
  case VK_OEM_MINUS:
    return "-";
  case VK_OEM_PLUS:
    return "=";
  default:
    break;
  }

  // Alphanumeric keys (0x30-0x39 = '0'-'9', 0x41-0x5A = 'A'-'Z')
  if (vkCode >= 0x30 && vkCode <= 0x39)
  {
    char c = static_cast<char>(vkCode);
    return std::string(1, c);
  }
  if (vkCode >= 0x41 && vkCode <= 0x5A)
  {
    // Return lowercase by default
    char c = static_cast<char>(vkCode + 32);
    return std::string(1, c);
  }

  // Function keys
  if (vkCode >= VK_F1 && vkCode <= VK_F24)
  {
    return "F" + std::to_string(vkCode - VK_F1 + 1);
  }

  // Numpad
  if (vkCode >= VK_NUMPAD0 && vkCode <= VK_NUMPAD9)
  {
    return std::to_string(vkCode - VK_NUMPAD0);
  }

  return "VK_" + std::to_string(vkCode);
}

std::string GlobalKeyboardHook::GetForegroundWindowTitle()
{
  HWND hwnd = GetForegroundWindow();
  if (!hwnd)
    return "";

  wchar_t title[256];
  int len = GetWindowTextW(hwnd, title, sizeof(title) / sizeof(wchar_t));
  if (len == 0)
    return "";

  // Convert wide string to UTF-8
  int utf8Len =
      WideCharToMultiByte(CP_UTF8, 0, title, len, nullptr, 0, nullptr, nullptr);
  if (utf8Len == 0)
    return "";

  std::string result(utf8Len, '\0');
  WideCharToMultiByte(CP_UTF8, 0, title, len, &result[0], utf8Len, nullptr,
                      nullptr);
  return result;
}

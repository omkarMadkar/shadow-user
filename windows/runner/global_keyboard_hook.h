#ifndef GLOBAL_KEYBOARD_HOOK_H_
#define GLOBAL_KEYBOARD_HOOK_H_

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/flutter_engine.h>
#include <windows.h>
#include <string>
#include <memory>

/// Registers a global low-level keyboard hook (WH_KEYBOARD_LL) that
/// forwards every key-down / key-up event to the Dart side via a
/// MethodChannel named "com.shadow_sentinel/global_keyboard".
///
/// Events sent to Dart:
///   "onGlobalKey" -> { "key": <string>, "isDown": <bool>, "vkCode": <int>,
///                      "timestamp": <int64>, "foregroundWindow": <string> }
class GlobalKeyboardHook
{
public:
  static void Register(flutter::FlutterEngine *engine);
  static void Unregister();

private:
  static LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam,
                                               LPARAM lParam);
  static std::string VkCodeToString(DWORD vkCode);
  static std::string GetForegroundWindowTitle();

  static HHOOK hook_handle_;
  static std::shared_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      channel_;
};

#endif // GLOBAL_KEYBOARD_HOOK_H_

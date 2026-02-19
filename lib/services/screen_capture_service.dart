import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Captures silent (invisible) screenshots of the screen without any visible indication.
/// 
/// Uses Windows native API (win32) to capture the desktop directly to a PNG file.
/// Stores captured images in the application documents directory.
class ScreenCaptureService {
  /// Captures a silent screenshot of the entire screen.
  /// 
  /// Returns the file path to the saved PNG image, or null if capture failed.
  /// 
  /// Errors are logged internally but do not throw exceptions.
  static Future<String?> captureSilentScreenshot() async {
    try {
      final hDesktop = GetDesktopWindow();
      final hdcScreen = GetDC(hDesktop);
      final hdcMem = CreateCompatibleDC(hdcScreen);

      final width = GetSystemMetrics(SM_CXSCREEN);
      final height = GetSystemMetrics(SM_CYSCREEN);

      final hBitmap = CreateCompatibleBitmap(hdcScreen, width, height);
      SelectObject(hdcMem, hBitmap);

      BitBlt(hdcMem, 0, 0, width, height, hdcScreen, 0, 0, SRCCOPY);

      final bitmapInfo = calloc<BITMAPINFO>();
      bitmapInfo.ref.bmiHeader.biSize = sizeOf<BITMAPINFOHEADER>();
      bitmapInfo.ref.bmiHeader.biWidth = width;
      bitmapInfo.ref.bmiHeader.biHeight = -height;
      bitmapInfo.ref.bmiHeader.biPlanes = 1;
      bitmapInfo.ref.bmiHeader.biBitCount = 32;
      bitmapInfo.ref.bmiHeader.biCompression = BI_RGB;

      final bufferSize = width * height * 4;
      final buffer = calloc<Uint8>(bufferSize);
      GetDIBits(hdcMem, hBitmap, 0, height, buffer, bitmapInfo, DIB_RGB_COLORS);

      final Uint8List pixelList = buffer.asTypedList(bufferSize);

      free(bitmapInfo);
      DeleteObject(hBitmap);
      DeleteDC(hdcMem);
      ReleaseDC(hDesktop, hdcScreen);

      final ui.ImmutableBuffer immutableBuffer =
          await ui.ImmutableBuffer.fromUint8List(pixelList);
      final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
        immutableBuffer,
        width: width,
        height: height,
        pixelFormat: ui.PixelFormat.bgra8888,
      );

      final ui.Codec codec = await descriptor.instantiateCodec();
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ByteData? byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);

      free(buffer);

      if (byteData == null) {
        debugPrint('[ScreenCapture] Failed to convert frame to PNG');
        return null;
      }

      final directory = await getApplicationDocumentsDirectory();
      final String fileName =
          'sentinel_shot_${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = p.join(directory.path, fileName);

      final File imageFile = File(filePath);
      await imageFile.writeAsBytes(byteData.buffer.asUint8List());

      debugPrint('[ScreenCapture] Screenshot saved to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('[ScreenCapture] Capture error: $e');
      return null;
    }
  }

  /// Captures a screenshot and returns the image data as bytes without saving to file.
  /// 
  /// Returns PNG-encoded bytes, or null if capture failed.
  static Future<Uint8List?> captureScreenshotBytes() async {
    try {
      final hDesktop = GetDesktopWindow();
      final hdcScreen = GetDC(hDesktop);
      final hdcMem = CreateCompatibleDC(hdcScreen);

      final width = GetSystemMetrics(SM_CXSCREEN);
      final height = GetSystemMetrics(SM_CYSCREEN);

      final hBitmap = CreateCompatibleBitmap(hdcScreen, width, height);
      SelectObject(hdcMem, hBitmap);

      BitBlt(hdcMem, 0, 0, width, height, hdcScreen, 0, 0, SRCCOPY);

      final bitmapInfo = calloc<BITMAPINFO>();
      bitmapInfo.ref.bmiHeader.biSize = sizeOf<BITMAPINFOHEADER>();
      bitmapInfo.ref.bmiHeader.biWidth = width;
      bitmapInfo.ref.bmiHeader.biHeight = -height;
      bitmapInfo.ref.bmiHeader.biPlanes = 1;
      bitmapInfo.ref.bmiHeader.biBitCount = 32;
      bitmapInfo.ref.bmiHeader.biCompression = BI_RGB;

      final bufferSize = width * height * 4;
      final buffer = calloc<Uint8>(bufferSize);
      GetDIBits(hdcMem, hBitmap, 0, height, buffer, bitmapInfo, DIB_RGB_COLORS);

      final Uint8List pixelList = buffer.asTypedList(bufferSize);

      free(bitmapInfo);
      DeleteObject(hBitmap);
      DeleteDC(hdcMem);
      ReleaseDC(hDesktop, hdcScreen);

      final ui.ImmutableBuffer immutableBuffer =
          await ui.ImmutableBuffer.fromUint8List(pixelList);
      final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
        immutableBuffer,
        width: width,
        height: height,
        pixelFormat: ui.PixelFormat.bgra8888,
      );

      final ui.Codec codec = await descriptor.instantiateCodec();
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ByteData? byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);

      free(buffer);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[ScreenCapture] Bytes capture error: $e');
      return null;
    }
  }
}

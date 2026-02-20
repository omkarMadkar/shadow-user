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
      final ByteData? byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );

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
      final ByteData? byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      free(buffer);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[ScreenCapture] Bytes capture error: $e');
      return null;
    }
  }

  /// Captures a photo from the device camera using Python + OpenCV (real webcam).
  ///
  /// Tries Python (opencv-python) first — gives a real camera frame.
  /// Falls back to ffmpeg if Python is unavailable.
  /// Returns the file path to the saved JPEG, or null if all methods fail.
  static Future<String?> captureFromCamera() async {
    try {
      debugPrint('[CameraCapture] Starting REAL webcam capture...');

      final directory = await getApplicationDocumentsDirectory();
      final String outputPath = p.join(
        directory.path,
        'sentinel_face_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Locate the Python helper script bundled with the app
      final pythonScript = await _getPythonScriptPath();

      if (pythonScript != null) {
        debugPrint('[CameraCapture] Trying Python/OpenCV capture...');
        final result = await Process.run('python', [
          pythonScript,
          outputPath,
        ], runInShell: true);
        debugPrint('[CameraCapture] Python exit: ${result.exitCode}');
        if (result.stdout.toString().isNotEmpty) {
          debugPrint('[CameraCapture] Python stdout: ${result.stdout}');
        }
        if (result.stderr.toString().isNotEmpty) {
          debugPrint('[CameraCapture] Python stderr: ${result.stderr}');
        }
        final file = File(outputPath);
        if (result.exitCode == 0 &&
            file.existsSync() &&
            await file.length() > 0) {
          debugPrint('[CameraCapture] SUCCESS via Python: $outputPath');
          return outputPath;
        }
        debugPrint('[CameraCapture] Python method failed, trying ffmpeg...');
      }

      // ---------- ffmpeg fallback ----------
      debugPrint('[CameraCapture] Trying ffmpeg webcam capture...');
      final ffmpegResult = await Process.run('ffmpeg', [
        '-y',
        '-f',
        'dshow',
        '-i',
        'video=0',
        '-vframes',
        '1',
        '-q:v',
        '2',
        outputPath,
      ], runInShell: true);
      debugPrint('[CameraCapture] ffmpeg exit: ${ffmpegResult.exitCode}');
      if (ffmpegResult.stdout.toString().isNotEmpty) {
        debugPrint('[CameraCapture] ffmpeg stdout: ${ffmpegResult.stdout}');
      }
      if (ffmpegResult.stderr.toString().isNotEmpty) {
        debugPrint('[CameraCapture] ffmpeg stderr: ${ffmpegResult.stderr}');
      }
      final ffFile = File(outputPath);
      if (ffFile.existsSync() && await ffFile.length() > 0) {
        debugPrint('[CameraCapture] SUCCESS via ffmpeg: $outputPath');
        return outputPath;
      }

      debugPrint('[CameraCapture] All camera methods failed.');
      return null;
    } catch (e) {
      debugPrint('[CameraCapture] Exception: $e');
      return null;
    }
  }

  /// Returns the absolute path to the Python camera capture script.
  ///
  /// Looks for [capture_camera.py] next to the executable first,
  /// then falls back to the windows/ sibling of the project root.
  static Future<String?> _getPythonScriptPath() async {
    // 1. Next to the executable (works in release builds)
    final exe = Platform.resolvedExecutable;
    final exeDir = p.dirname(exe);
    final candidate1 = p.join(exeDir, 'capture_camera.py');
    if (File(candidate1).existsSync()) return candidate1;

    // 2. During development: project_root/windows/capture_camera.py
    //    Walk up from the exe until we find a 'windows' sibling.
    try {
      var dir = Directory(exeDir);
      for (var i = 0; i < 6; i++) {
        final candidate = p.join(dir.path, 'windows', 'capture_camera.py');
        if (File(candidate).existsSync()) return candidate;
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    } catch (_) {}

    debugPrint(
      '[CameraCapture] capture_camera.py not found on disk, '
      'ensure opencv-python is installed: pip install opencv-python',
    );
    return null;
  }

  /// Captures both screen and camera simultaneously and pairs them together.
  ///
  /// Returns a [PairedCapture] object with both screen and camera paths.
  /// Returns null if either capture fails.
  static Future<PairedCapture?> captureScreenAndCamera() async {
    try {
      final captureTime = DateTime.now();

      // Capture screen and camera concurrently
      final results = await Future.wait([
        captureSilentScreenshot(),
        captureFromCamera(),
      ]);

      final screenPath = results[0];
      final cameraPath = results[1];

      if (screenPath == null || cameraPath == null) {
        debugPrint('[PairedCapture] One or both captures failed');
        return null;
      }

      return PairedCapture(
        screenPath: screenPath,
        cameraPath: cameraPath,
        captureTime: captureTime,
      );
    } catch (e) {
      debugPrint('[PairedCapture] Error: $e');
      return null;
    }
  }
}

/// Represents a paired screen and camera capture.
class PairedCapture {
  final String screenPath;
  final String cameraPath;
  final DateTime captureTime;

  PairedCapture({
    required this.screenPath,
    required this.cameraPath,
    required this.captureTime,
  });

  String get screenFileName => p.basename(screenPath);
  String get cameraFileName => p.basename(cameraPath);
}

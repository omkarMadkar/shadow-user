import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Camera service for webcam capture and face verification.
///
/// Provides:
/// - Real webcam streaming when available
/// - Periodic frame capture for face verification
/// - Base64 encoding for API communication
/// - Graceful fallback when camera unavailable
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isCameraAvailable = false;
  bool get isCameraAvailable => _isCameraAvailable;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Stream for camera frames
  final _frameStreamController = StreamController<CameraFrame>.broadcast();
  Stream<CameraFrame> get frameStream => _frameStreamController.stream;

  // Periodic capture timer
  Timer? _captureTimer;
  Duration _captureInterval = const Duration(seconds: 30);

  CameraController? get controller => _controller;

  /// Initialize the camera service.
  /// Returns true if camera is available and initialized.
  Future<bool> initialize() async {
    if (_isInitialized) return _isCameraAvailable;

    try {
      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        _errorMessage = 'No cameras found on this device';
        _isCameraAvailable = false;
        _isInitialized = true;
        debugPrint('[CameraService] No cameras available');
        return false;
      }

      // Find front-facing camera (preferred for face verification)
      CameraDescription? selectedCamera;
      for (final camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      // Fall back to first available camera
      selectedCamera ??= _cameras!.first;

      debugPrint('[CameraService] Using camera: ${selectedCamera.name}');

      // Initialize controller
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      _isCameraAvailable = true;
      _isInitialized = true;
      _errorMessage = null;

      debugPrint('[CameraService] Camera initialized successfully');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to initialize camera: $e';
      _isCameraAvailable = false;
      _isInitialized = true;
      debugPrint('[CameraService] Initialization error: $e');
      return false;
    }
  }

  /// Start periodic frame capture for face verification.
  void startPeriodicCapture({Duration? interval}) {
    if (interval != null) {
      _captureInterval = interval;
    }

    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(_captureInterval, (_) {
      captureFrame();
    });

    debugPrint(
      '[CameraService] Periodic capture started (${_captureInterval.inSeconds}s interval)',
    );
  }

  /// Stop periodic frame capture.
  void stopPeriodicCapture() {
    _captureTimer?.cancel();
    _captureTimer = null;
    debugPrint('[CameraService] Periodic capture stopped');
  }

  /// Capture a single frame from the camera.
  /// Returns a CameraFrame with the image data, or null if failed.
  Future<CameraFrame?> captureFrame() async {
    if (!_isCameraAvailable ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      debugPrint('[CameraService] Cannot capture: camera not available');
      return null;
    }

    try {
      final XFile imageFile = await _controller!.takePicture();
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final frame = CameraFrame(
        imageBytes: bytes,
        base64Image: base64Image,
        timestamp: DateTime.now(),
        width: _controller!.value.previewSize?.width.toInt() ?? 640,
        height: _controller!.value.previewSize?.height.toInt() ?? 480,
      );

      // Emit to stream
      _frameStreamController.add(frame);

      debugPrint('[CameraService] Frame captured: ${bytes.length} bytes');
      return frame;
    } catch (e) {
      debugPrint('[CameraService] Capture error: $e');
      return null;
    }
  }

  /// Get the camera preview widget.
  /// Returns a CameraPreview widget if camera is available.
  Widget? getPreviewWidget() {
    if (!_isCameraAvailable ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return null;
    }
    return CameraPreview(controller: _controller!);
  }

  /// Pause the camera preview.
  Future<void> pausePreview() async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.pausePreview();
    }
  }

  /// Resume the camera preview.
  Future<void> resumePreview() async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.resumePreview();
    }
  }

  /// Dispose of camera resources.
  Future<void> dispose() async {
    stopPeriodicCapture();
    await _frameStreamController.close();
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _isCameraAvailable = false;
    debugPrint('[CameraService] Disposed');
  }
}

/// Represents a captured camera frame.
class CameraFrame {
  final Uint8List imageBytes;
  final String base64Image;
  final DateTime timestamp;
  final int width;
  final int height;

  const CameraFrame({
    required this.imageBytes,
    required this.base64Image,
    required this.timestamp,
    required this.width,
    required this.height,
  });
}

/// Widget to display camera preview.
class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  final double? borderRadius;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? 12),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: controller.buildPreview(),
      ),
    );
  }
}

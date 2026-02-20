import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/screen_capture_service.dart';
import '../theme/sentinel_theme.dart';

/// Test screen to verify ScreenCaptureService is working correctly.
class ScreenCaptureTestScreen extends StatefulWidget {
  const ScreenCaptureTestScreen({super.key});

  @override
  State<ScreenCaptureTestScreen> createState() =>
      _ScreenCaptureTestScreenState();
}

class _ScreenCaptureTestScreenState extends State<ScreenCaptureTestScreen> {
  String _status = '🟢 Ready to test - Select an option below';
  String? _lastFilePath;
  DateTime? _lastCaptureTime;
  bool _isLoading = false;
  final List<Map<String, dynamic>> _captureHistory = [];

  String _formatTime(DateTime time) {
    return DateFormat('yyyy-MM-dd hh:mm:ss a').format(time);
  }

  Future<void> _testCapture() async {
    setState(() {
      _isLoading = true;
      _status = '⏳ Capturing screen...';
    });
    
    try {
      final captureTime = DateTime.now();
      final result = await ScreenCaptureService.captureSilentScreenshot();
      
      if (result != null) {
        final formattedTime = _formatTime(captureTime);
        setState(() {
          _lastFilePath = result;
          _lastCaptureTime = captureTime;
          _status = '✅ Screen capture successful!\n⏰ Time: $formattedTime\n📁 File: ${File(result).path.split(Platform.pathSeparator).last}';
          _captureHistory.insert(0, {
            'path': result,
            'time': formattedTime,
            'type': 'Screen',
          });
        });
      } else {
        setState(() => _status = '❌ Capture failed - returned null');
      }
    } catch (e) {
      setState(() => _status = '❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testCaptureBytes() async {
    setState(() {
      _isLoading = true;
      _status = '⏳ Capturing to bytes...';
    });
    
    try {
      final captureTime = DateTime.now();
      final result = await ScreenCaptureService.captureScreenshotBytes();
      
      if (result != null) {
        final formattedTime = _formatTime(captureTime);
        setState(() {
          _lastCaptureTime = captureTime;
          _status =
              '✅ Bytes capture successful!\n⏰ Time: $formattedTime\n📊 Size: ${(result.lengthInBytes / 1024 / 1024).toStringAsFixed(2)} MB';
          _captureHistory.insert(0, {
            'path': 'Memory Buffer',
            'time': formattedTime,
            'type': 'Bytes',
            'size': result.lengthInBytes,
          });
        });
      } else {
        setState(() => _status = '❌ Bytes capture failed - returned null');
      }
    } catch (e) {
      setState(() => _status = '❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testCaptureScreenAndCamera() async {
    setState(() {
      _isLoading = true;
      _status = '⏳ Capturing screen and camera...';
    });
    
    try {
      final result = await ScreenCaptureService.captureScreenAndCamera();
      
      if (result != null) {
        final formattedTime = _formatTime(result.captureTime);
        setState(() {
          _lastFilePath = result.screenPath;
          _lastCaptureTime = result.captureTime;
          _status =
              '✅ Paired capture successful!\n⏰ Time: $formattedTime\n📸 Screen: ${result.screenFileName}\n📷 Camera: ${result.cameraFileName}';
          _captureHistory.insert(0, {
            'path': 'Paired: ${result.screenFileName} + ${result.cameraFileName}',
            'time': formattedTime,
            'type': 'Paired (Screen + Camera)',
            'screenPath': result.screenPath,
            'cameraPath': result.cameraPath,
          });
        });
      } else {
        setState(() => _status = '❌ Paired capture failed\n⚠️ Check console for camera details');
      }
    } catch (e) {
      setState(() => _status = '❌ Error: $e');
      debugPrint('📷 Camera capture error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openCapturedImage() {
    if (_lastFilePath != null) {
      final file = File(_lastFilePath!);
      if (file.existsSync()) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Captured Screenshot',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_lastCaptureTime != null)
                        Text(
                          'Captured at: ${_formatTime(_lastCaptureTime!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Image.file(file, fit: BoxFit.contain),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _lastFilePath!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File no longer exists')),
        );
      }
    }
  }

  void _openPairedCaptures() {
    // Find the last paired capture in history
    final pairedCapture = _captureHistory.firstWhere(
      (c) => c['type'] == 'Paired (Screen + Camera)',
      orElse: () => <String, dynamic>{},
    );

    if (pairedCapture.isEmpty ||
        pairedCapture['screenPath'] == null ||
        pairedCapture['cameraPath'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No paired captures found')),
      );
      return;
    }

    final screenFile = File(pairedCapture['screenPath']);
    final cameraFile = File(pairedCapture['cameraPath']);

    if (!screenFile.existsSync() || !cameraFile.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('One or both files no longer exist')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Paired Capture - Screen & Camera',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Captured at: ${pairedCapture['time']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Screen Capture',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.file(screenFile, fit: BoxFit.contain),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Camera Capture',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.file(cameraFile, fit: BoxFit.contain),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentinelTheme.bg,
      appBar: AppBar(
        title: const Text('Screen Capture Test'),
        backgroundColor: SentinelTheme.surface,
        foregroundColor: SentinelTheme.cyberBlue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Status Container - High Visibility
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SentinelTheme.surfaceAlt,
                  border: Border.all(
                    color: SentinelTheme.cyberBlue,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: SentinelTheme.cyberBlue.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  _status,
                  style: SentinelTheme.mono.copyWith(
                    color: SentinelTheme.cyberBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),

              // Buttons Section
              Column(
                spacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testCapture,
                    icon: const Icon(Icons.screenshot, size: 18),
                    label: const Text('📸 Capture Screen Only'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SentinelTheme.cyberBlue,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testCaptureBytes,
                    icon: const Icon(Icons.image, size: 18),
                    label: const Text('🎨 Capture to Bytes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SentinelTheme.alertGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testCaptureScreenAndCamera,
                    icon: const Icon(Icons.camera, size: 18),
                    label: const Text('📸+📷 Capture Both (Screen + Camera)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  if (_lastFilePath != null)
                    ElevatedButton.icon(
                      onPressed: _openCapturedImage,
                      icon: const Icon(Icons.preview, size: 18),
                      label: const Text('👁️ View Last Capture'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SentinelTheme.cyberCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  if (_captureHistory.any(
                      (c) => c['type'] == 'Paired (Screen + Camera)'))
                    ElevatedButton.icon(
                      onPressed: _openPairedCaptures,
                      icon: const Icon(Icons.compare, size: 18),
                      label: const Text('🔀 View Paired Capture'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SentinelTheme.alertAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SentinelTheme.surfaceAlt,
                  border: Border.all(color: SentinelTheme.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📖 How to Use:',
                      style: SentinelTheme.mono.copyWith(
                        color: SentinelTheme.cyberBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...const [
                      '1️⃣ Try "Capture Screen Only" first to test basic functionality',
                      '2️⃣ Try "Capture Both (Screen + Camera)" for the face + screen combo',
                      '3️⃣ Check the status message for timestamps and file info',
                      '4️⃣ Use the preview buttons to see captured images',
                      '5️⃣ Scroll down to see capture history',
                    ]
                        .map((text) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            text,
                            style: SentinelTheme.sans.copyWith(
                              color: SentinelTheme.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Capture History
              if (_captureHistory.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SentinelTheme.surfaceAlt,
                    border: Border.all(
                      color: SentinelTheme.alertGreen,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📋 Capture History (${_captureHistory.length})',
                        style: SentinelTheme.mono.copyWith(
                          color: SentinelTheme.alertGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _captureHistory.length,
                        separatorBuilder: (_, __) => Divider(
                          color: SentinelTheme.border,
                          height: 16,
                        ),
                        itemBuilder: (context, index) {
                          final capture = _captureHistory[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${capture['type']} • ${capture['time']}',
                                style: SentinelTheme.mono.copyWith(
                                  color: SentinelTheme.cyberBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                capture['path'],
                                style: SentinelTheme.sans.copyWith(
                                  color: SentinelTheme.textMuted,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (capture['size'] != null)
                                Text(
                                  '📊 Size: ${(capture['size'] / 1024 / 1024).toStringAsFixed(2)} MB',
                                  style: SentinelTheme.sans.copyWith(
                                    color: SentinelTheme.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

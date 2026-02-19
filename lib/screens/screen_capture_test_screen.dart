import 'dart:io';
import 'package:flutter/material.dart';
import '../services/screen_capture_service.dart';

/// Test screen to verify ScreenCaptureService is working correctly.
class ScreenCaptureTestScreen extends StatefulWidget {
  const ScreenCaptureTestScreen({super.key});

  @override
  State<ScreenCaptureTestScreen> createState() =>
      _ScreenCaptureTestScreenState();
}

class _ScreenCaptureTestScreenState extends State<ScreenCaptureTestScreen> {
  String _status = 'Ready to test';
  String? _lastFilePath;
  bool _isLoading = false;

  Future<void> _testCapture() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ScreenCaptureService.captureSilentScreenshot();
      
      if (result != null) {
        setState(() {
          _lastFilePath = result;
          _status = '✅ Capture successful!\nFile: $result';
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
    setState(() => _isLoading = true);
    
    try {
      final result = await ScreenCaptureService.captureScreenshotBytes();
      
      if (result != null) {
        setState(() => _status =
            '✅ Bytes capture successful!\nSize: ${result.lengthInBytes} bytes');
      } else {
        setState(() => _status = '❌ Bytes capture failed - returned null');
      }
    } catch (e) {
      setState(() => _status = '❌ Error: $e');
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
                  child: Text(
                    'Captured Screenshot',
                    style: Theme.of(context).textTheme.titleLarge,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen Capture Test')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              Column(
                spacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testCapture,
                    icon: const Icon(Icons.screenshot),
                    label: const Text('Test: Capture to File'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testCaptureBytes,
                    icon: const Icon(Icons.image),
                    label: const Text('Test: Capture to Bytes'),
                  ),
                  if (_lastFilePath != null)
                    ElevatedButton.icon(
                      onPressed: _openCapturedImage,
                      icon: const Icon(Icons.preview),
                      label: const Text('View Last Capture'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'How to Test:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Tap "Test: Capture to File" - should save PNG to Documents',
                    ),
                    Text(
                      '2. Check status message for file path',
                    ),
                    Text(
                      '3. Tap "View Last Capture" to see the screenshot',
                    ),
                    Text(
                      '4. Check app console for debug messages',
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

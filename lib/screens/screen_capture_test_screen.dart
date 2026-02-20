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
          _status =
              '✅ Screen capture successful!\n⏰ Time: $formattedTime\n📁 File: ${File(result).path.split(Platform.pathSeparator).last}';
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
            'path':
                'Paired: ${result.screenFileName} + ${result.cameraFileName}',
            'time': formattedTime,
            'type': 'Paired (Screen + Camera)',
            'screenPath': result.screenPath,
            'cameraPath': result.cameraPath,
          });
        });
      } else {
        setState(
          () => _status =
              '❌ Paired capture failed\n⚠️ Check console for camera details',
        );
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
                Expanded(child: Image.file(file, fit: BoxFit.contain)),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File no longer exists')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No paired captures found')));
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Card ────────────────────────────────
          _CaptureHeaderCard(
            status: _status,
            isLoading: _isLoading,
            captureCount: _captureHistory.length,
          ),
          const SizedBox(height: 16),

          // ── Main Content ──────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 900;

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column — actions
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          _CaptureActionsCard(
                            isLoading: _isLoading,
                            onCaptureScreen: _testCapture,
                            onCaptureBytes: _testCaptureBytes,
                            onCaptureBoth: _testCaptureScreenAndCamera,
                            onViewLast: _lastFilePath != null
                                ? _openCapturedImage
                                : null,
                            onViewPaired:
                                _captureHistory.any(
                                  (c) =>
                                      c['type'] == 'Paired (Screen + Camera)',
                                )
                                ? _openPairedCaptures
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _InstructionsCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right column — history
                    Expanded(
                      flex: 4,
                      child: _CaptureHistoryCard(
                        captureHistory: _captureHistory,
                      ),
                    ),
                  ],
                );
              }

              // Narrow layout
              return Column(
                children: [
                  _CaptureActionsCard(
                    isLoading: _isLoading,
                    onCaptureScreen: _testCapture,
                    onCaptureBytes: _testCaptureBytes,
                    onCaptureBoth: _testCaptureScreenAndCamera,
                    onViewLast: _lastFilePath != null
                        ? _openCapturedImage
                        : null,
                    onViewPaired:
                        _captureHistory.any(
                          (c) => c['type'] == 'Paired (Screen + Camera)',
                        )
                        ? _openPairedCaptures
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _InstructionsCard(),
                  const SizedBox(height: 16),
                  _CaptureHistoryCard(captureHistory: _captureHistory),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Header Card ──────────────────────────────────────────────

class _CaptureHeaderCard extends StatelessWidget {
  final String status;
  final bool isLoading;
  final int captureCount;

  const _CaptureHeaderCard({
    required this.status,
    required this.isLoading,
    required this.captureCount,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status.contains('✅')
        ? SentinelTheme.alertGreen
        : status.contains('❌')
        ? SentinelTheme.alertRed
        : status.contains('⏳')
        ? SentinelTheme.alertAmber
        : SentinelTheme.cyberBlue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: SentinelTheme.glassCard(glowColor: statusColor),
      child: Row(
        children: [
          // Icon with glow
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.15),
                  SentinelTheme.cyberBlue.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              boxShadow: isLoading
                  ? [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: statusColor,
                    ),
                  )
                : Icon(Icons.screenshot_monitor, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),

          // Title & status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCREEN CAPTURE SYSTEM',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: SentinelTheme.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Silent Screenshot & Camera Capture',
                  style: SentinelTheme.sans.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status.replaceAll('\n', ' • '),
                  style: SentinelTheme.sans.copyWith(
                    fontSize: 11,
                    color: SentinelTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Capture count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'CAPTURES',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  color: SentinelTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$captureCount',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: captureCount > 0
                      ? SentinelTheme.alertGreen
                      : SentinelTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Capture Actions Card ─────────────────────────────────────

class _CaptureActionsCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onCaptureScreen;
  final VoidCallback onCaptureBytes;
  final VoidCallback onCaptureBoth;
  final VoidCallback? onViewLast;
  final VoidCallback? onViewPaired;

  const _CaptureActionsCard({
    required this.isLoading,
    required this.onCaptureScreen,
    required this.onCaptureBytes,
    required this.onCaptureBoth,
    this.onViewLast,
    this.onViewPaired,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SentinelTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt, color: SentinelTheme.cyberBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                'CAPTURE ACTIONS',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.cyberBlue,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Buttons
          _ActionButton(
            icon: Icons.screenshot,
            label: 'Capture Screen Only',
            color: SentinelTheme.cyberBlue,
            onTap: isLoading ? null : onCaptureScreen,
          ),
          const SizedBox(height: 10),
          _ActionButton(
            icon: Icons.image,
            label: 'Capture to Bytes',
            color: SentinelTheme.alertGreen,
            onTap: isLoading ? null : onCaptureBytes,
          ),
          const SizedBox(height: 10),
          _ActionButton(
            icon: Icons.camera,
            label: 'Capture Both (Screen + Camera)',
            color: const Color(0xFF8B5CF6),
            onTap: isLoading ? null : onCaptureBoth,
          ),
          if (onViewLast != null) ...[
            const SizedBox(height: 10),
            _ActionButton(
              icon: Icons.preview,
              label: 'View Last Capture',
              color: SentinelTheme.cyberCyan,
              onTap: onViewLast,
            ),
          ],
          if (onViewPaired != null) ...[
            const SizedBox(height: 10),
            _ActionButton(
              icon: Icons.compare,
              label: 'View Paired Capture',
              color: SentinelTheme.alertAmber,
              onTap: onViewPaired,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final effectiveColor = disabled ? color.withValues(alpha: 0.4) : color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: effectiveColor.withValues(alpha: 0.3)),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Row(
          children: [
            Icon(icon, color: effectiveColor, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: SentinelTheme.sans.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: effectiveColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: effectiveColor.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Instructions Card ────────────────────────────────────────

class _InstructionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SentinelTheme.glassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: SentinelTheme.cyberCyan,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'USAGE GUIDE',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.cyberCyan,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[
            'Try "Capture Screen Only" first to test basic functionality',
            'Try "Capture Both" for the face + screen combo',
            'Check the status message for timestamps and file info',
            'Use the preview buttons to see captured images',
            'Scroll down to see capture history',
          ].asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: SentinelTheme.cyberCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: SentinelTheme.cyberCyan.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: SentinelTheme.cyberCyan,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: SentinelTheme.sans.copyWith(
                        color: SentinelTheme.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Capture History Card ─────────────────────────────────────

class _CaptureHistoryCard extends StatelessWidget {
  final List<Map<String, dynamic>> captureHistory;

  const _CaptureHistoryCard({required this.captureHistory});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SentinelTheme.glassCard(
        glowColor: captureHistory.isNotEmpty ? SentinelTheme.alertGreen : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: SentinelTheme.alertGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                'CAPTURE HISTORY',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.alertGreen,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: SentinelTheme.alertGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: SentinelTheme.alertGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${captureHistory.length} total',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    color: SentinelTheme.alertGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (captureHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_camera_back_outlined,
                      size: 28,
                      color: SentinelTheme.textMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No captures yet',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 11,
                        color: SentinelTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: captureHistory.length,
              separatorBuilder: (_, __) =>
                  Divider(color: SentinelTheme.border, height: 16),
              itemBuilder: (context, index) {
                final capture = captureHistory[index];
                final typeColor = capture['type'] == 'Screen'
                    ? SentinelTheme.cyberBlue
                    : capture['type'] == 'Bytes'
                    ? SentinelTheme.alertGreen
                    : const Color(0xFF8B5CF6);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Icon(
                        capture['type'] == 'Screen'
                            ? Icons.screenshot
                            : capture['type'] == 'Bytes'
                            ? Icons.image
                            : Icons.camera,
                        color: typeColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${capture['type']} • ${capture['time']}',
                            style: SentinelTheme.mono.copyWith(
                              color: typeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            capture['path'],
                            style: SentinelTheme.sans.copyWith(
                              color: SentinelTheme.textMuted,
                              fontSize: 10,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (capture['size'] != null)
                            Text(
                              'Size: ${(capture['size'] / 1024 / 1024).toStringAsFixed(2)} MB',
                              style: SentinelTheme.sans.copyWith(
                                color: SentinelTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

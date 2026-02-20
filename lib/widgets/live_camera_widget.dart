import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../theme/sentinel_theme.dart';
import '../providers/sentinel_provider.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';

/// Live camera widget with face verification integration.
/// 
/// Displays real webcam feed when available, falls back to animated
/// placeholder when camera is unavailable.
/// 
/// Periodically captures frames and sends to face verification API.
class LiveCameraWidget extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onCapture;
  
  const LiveCameraWidget({
    super.key,
    this.isActive = true,
    this.onCapture,
  });

  @override
  State<LiveCameraWidget> createState() => _LiveCameraWidgetState();
}

class _LiveCameraWidgetState extends State<LiveCameraWidget>
    with TickerProviderStateMixin {
  final CameraService _cameraService = CameraService();
  final ApiService _apiService = ApiService();
  
  bool _isInitializing = true;
  bool _cameraReady = false;
  String? _error;
  
  // Animation controllers for overlay effects
  late AnimationController _pulseController;
  late AnimationController _scanController;
  
  // Verification state
  bool _isVerifying = false;
  double _lastConfidence = 0;
  bool _lastMatched = false;
  DateTime? _lastVerification;
  
  // Capture timer
  Timer? _captureTimer;
  int _countdown = 30;
  static const int _captureIntervalSeconds = 30;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    setState(() => _isInitializing = true);
    
    try {
      final success = await _cameraService.initialize();
      
      setState(() {
        _cameraReady = success;
        _isInitializing = false;
        _error = success ? null : _cameraService.errorMessage;
      });
      
      if (success && widget.isActive) {
        _startCaptureTimer();
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _cameraReady = false;
        _error = 'Camera initialization failed: $e';
      });
    }
  }
  
  void _startCaptureTimer() {
    _countdown = _captureIntervalSeconds;
    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _countdown--;
      });
      
      if (_countdown <= 0) {
        _captureAndVerify();
        _countdown = _captureIntervalSeconds;
      }
    });
  }
  
  void _stopCaptureTimer() {
    _captureTimer?.cancel();
    _captureTimer = null;
  }
  
  Future<void> _captureAndVerify() async {
    if (!_cameraReady || _isVerifying) return;
    
    setState(() => _isVerifying = true);
    widget.onCapture?.call();
    
    try {
      // Capture frame
      final frame = await _cameraService.captureFrame();
      
      if (frame != null) {
        // Send to API for verification
        final result = await _apiService.verifyFace(
          userId: 'current_user',
          imageBase64: frame.base64Image,
          demoMode: false, // Use real verification
        );
        
        setState(() {
          _lastConfidence = result.confidence;
          _lastMatched = result.matched;
          _lastVerification = DateTime.now();
        });
        
        // Update the sentinel provider with results
        if (mounted) {
          final provider = context.read<SentinelProvider>();
          provider.updateFaceConfidence(
            result.confidence,
            matched: result.matched,
            spoofing: result.spoofingDetected,
          );
        }
      }
    } catch (e) {
      debugPrint('[LiveCamera] Verification error: $e');
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }
  
  @override
  void didUpdateWidget(LiveCameraWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive && !oldWidget.isActive) {
      _cameraService.resumePreview();
      _startCaptureTimer();
    } else if (!widget.isActive && oldWidget.isActive) {
      _cameraService.pausePreview();
      _stopCaptureTimer();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    _stopCaptureTimer();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: SentinelTheme.glassCard(
        glowColor: _lastMatched ? SentinelTheme.alertGreen : SentinelTheme.cyberCyan,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 12),
          
          // Camera preview area
          AspectRatio(
            aspectRatio: 4 / 3,
            child: _buildCameraArea(),
          ),
          
          const SizedBox(height: 12),
          
          // Status & metrics
          _buildStatusBar(),
          
          const SizedBox(height: 8),
          
          // Manual capture button
          _buildCaptureButton(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.videocam, size: 16, color: SentinelTheme.cyberCyan),
        const SizedBox(width: 8),
        Text(
          'LIVE CAMERA',
          style: SentinelTheme.mono.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: SentinelTheme.cyberCyan,
            letterSpacing: 1,
          ),
        ),
        const Spacer(),
        // Camera status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (_cameraReady ? SentinelTheme.alertGreen : SentinelTheme.alertAmber)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (_cameraReady ? SentinelTheme.alertGreen : SentinelTheme.alertAmber)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _cameraReady ? SentinelTheme.alertGreen : SentinelTheme.alertAmber,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _cameraReady ? 'LIVE' : 'DEMO',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: _cameraReady ? SentinelTheme.alertGreen : SentinelTheme.alertAmber,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCameraArea() {
    if (_isInitializing) {
      return _buildPlaceholder('Initializing camera...');
    }
    
    if (!_cameraReady) {
      return _buildAnimatedPlaceholder();
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _cameraService.controller != null && _cameraService.controller!.value.isInitialized
              ? _cameraService.controller!.buildPreview()
              : _buildAnimatedPlaceholder(),
        ),
        
        // Scan overlay
        if (widget.isActive)
          AnimatedBuilder(
            animation: _scanController,
            builder: (context, _) {
              return CustomPaint(
                painter: _ScanOverlayPainter(
                  progress: _scanController.value,
                  color: _lastMatched ? SentinelTheme.alertGreen : SentinelTheme.cyberCyan,
                ),
              );
            },
          ),
        
        // Verifying indicator
        if (_isVerifying)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: SentinelTheme.cyberCyan,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'VERIFYING...',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 10,
                      color: SentinelTheme.cyberCyan,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Countdown overlay
        Positioned(
          right: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Next scan: ${_countdown}s',
              style: SentinelTheme.mono.copyWith(
                fontSize: 9,
                color: SentinelTheme.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPlaceholder(String message) {
    return Container(
      decoration: BoxDecoration(
        color: SentinelTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SentinelTheme.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: SentinelTheme.cyberBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: SentinelTheme.mono.copyWith(
                fontSize: 10,
                color: SentinelTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnimatedPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: SentinelTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SentinelTheme.border),
      ),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          return CustomPaint(
            painter: _PlaceholderPainter(
              pulse: _pulseController.value,
              color: SentinelTheme.cyberCyan,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.face,
                    size: 48,
                    color: SentinelTheme.cyberCyan.withValues(
                      alpha: 0.3 + _pulseController.value * 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error ?? 'Camera unavailable\nUsing simulation mode',
                    textAlign: TextAlign.center,
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 9,
                      color: SentinelTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildStatusBar() {
    final statusColor = _lastMatched ? SentinelTheme.alertGreen : SentinelTheme.alertAmber;
    
    return Row(
      children: [
        _StatusChip(
          label: 'CONFIDENCE',
          value: '${_lastConfidence.toStringAsFixed(1)}%',
          color: statusColor,
        ),
        const SizedBox(width: 8),
        _StatusChip(
          label: 'STATUS',
          value: _lastMatched ? 'MATCHED' : 'PENDING',
          color: statusColor,
        ),
        const SizedBox(width: 8),
        _StatusChip(
          label: 'LAST SCAN',
          value: _lastVerification != null
              ? '${DateTime.now().difference(_lastVerification!).inSeconds}s ago'
              : 'Never',
          color: SentinelTheme.cyberBlue,
        ),
      ],
    );
  }
  
  Widget _buildCaptureButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _isVerifying ? null : _captureAndVerify,
        icon: Icon(
          Icons.camera_alt,
          size: 16,
          color: _isVerifying ? SentinelTheme.textMuted : SentinelTheme.cyberCyan,
        ),
        label: Text(
          _isVerifying ? 'VERIFYING...' : 'MANUAL CAPTURE',
          style: SentinelTheme.mono.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _isVerifying ? SentinelTheme.textMuted : SentinelTheme.cyberCyan,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: SentinelTheme.cyberCyan.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  
  const _StatusChip({
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: SentinelTheme.mono.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: SentinelTheme.mono.copyWith(
                fontSize: 7,
                color: SentinelTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  _ScanOverlayPainter({required this.progress, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Scanning line
    final lineY = size.height * progress;
    canvas.drawLine(
      Offset(0, lineY),
      Offset(size.width, lineY),
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    
    // Corner brackets
    final bracketLen = 20.0;
    final margin = 16.0;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(margin, margin + bracketLen)
        ..lineTo(margin, margin)
        ..lineTo(margin + bracketLen, margin),
      paint,
    );
    
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - bracketLen, margin)
        ..lineTo(size.width - margin, margin)
        ..lineTo(size.width - margin, margin + bracketLen),
      paint,
    );
    
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(margin, size.height - margin - bracketLen)
        ..lineTo(margin, size.height - margin)
        ..lineTo(margin + bracketLen, size.height - margin),
      paint,
    );
    
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - margin - bracketLen, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin)
        ..lineTo(size.width - margin, size.height - margin - bracketLen),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) => 
      oldDelegate.progress != progress;
}

class _PlaceholderPainter extends CustomPainter {
  final double pulse;
  final Color color;
  
  _PlaceholderPainter({required this.pulse, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Pulsing circles
    for (int i = 0; i < 3; i++) {
      final radius = 30.0 + i * 20 + pulse * 10;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: 0.1 - i * 0.03)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant _PlaceholderPainter oldDelegate) => 
      oldDelegate.pulse != pulse;
}

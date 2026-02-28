import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sentinel_provider.dart';
import '../theme/sentinel_theme.dart';

/// Full-screen face enrollment shown once after login.
/// Captures the user's face as a reference for ongoing verification.
class FaceEnrollmentScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const FaceEnrollmentScreen({super.key, required this.onComplete});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen>
    with SingleTickerProviderStateMixin {
  String _status = 'Position your face in front of the camera';
  bool _isCapturing = false;
  bool _captured = false;
  String? _capturedPath;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _captureReference() async {
    final provider = context.read<SentinelProvider>();

    setState(() {
      _isCapturing = true;
      _status = 'Capturing face... Please hold still';
    });

    final path = await provider.captureReferenceFace();

    if (path != null) {
      setState(() {
        _captured = true;
        _capturedPath = path;
        _status = 'Face captured successfully!';
      });
    } else {
      setState(() {
        _isCapturing = false;
        _status =
            'Capture failed. Make sure your camera is connected and try again.';
      });
    }
  }

  void _proceed() {
    final provider = context.read<SentinelProvider>();
    // Start periodic face verification (every 30 seconds)
    provider.startRealVerification(intervalSeconds: 30);
    widget.onComplete();
  }

  void _skip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentinelTheme.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) {
                    final pulse = _pulseController.value;
                    final color = _captured
                        ? SentinelTheme.alertGreen
                        : SentinelTheme.cyberCyan;
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: color.withValues(alpha: 0.3 + pulse * 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.1 + pulse * 0.1),
                            blurRadius: 20 + pulse * 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        _captured
                            ? Icons.check_circle
                            : Icons.face_retouching_natural,
                        size: 40,
                        color: color,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'NEURAL FACE ENROLLMENT',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 10,
                    color: SentinelTheme.textMuted,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _captured
                      ? 'Identity Baseline Captured'
                      : 'Capture Your Face',
                  style: SentinelTheme.sans.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: SentinelTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _captured
                      ? 'Your face will be verified periodically during your session '
                            'to ensure continuous identity authentication.'
                      : 'Shadow Sentinel uses your webcam to verify your identity '
                            'throughout your session. Capture a reference face now.',
                  textAlign: TextAlign.center,
                  style: SentinelTheme.sans.copyWith(
                    fontSize: 13,
                    color: SentinelTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Face capture card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: SentinelTheme.glassCard(
                    glowColor: _captured
                        ? SentinelTheme.alertGreen
                        : SentinelTheme.cyberCyan,
                  ),
                  child: Column(
                    children: [
                      // Preview or placeholder
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: SentinelTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _captured
                                ? SentinelTheme.alertGreen.withValues(
                                    alpha: 0.3,
                                  )
                                : SentinelTheme.border,
                          ),
                        ),
                        child: _captured && _capturedPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.file(
                                  File(_capturedPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _facePlaceholder(),
                                ),
                              )
                            : _facePlaceholder(),
                      ),
                      const SizedBox(height: 16),

                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _captured
                              ? SentinelTheme.alertGreen.withValues(alpha: 0.08)
                              : SentinelTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _captured
                                ? SentinelTheme.alertGreen.withValues(
                                    alpha: 0.2,
                                  )
                                : SentinelTheme.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isCapturing && !_captured)
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: SentinelTheme.cyberCyan,
                                ),
                              )
                            else
                              Icon(
                                _captured
                                    ? Icons.check_circle
                                    : Icons.info_outline,
                                size: 14,
                                color: _captured
                                    ? SentinelTheme.alertGreen
                                    : SentinelTheme.textMuted,
                              ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _status,
                                style: SentinelTheme.mono.copyWith(
                                  fontSize: 11,
                                  color: _captured
                                      ? SentinelTheme.alertGreen
                                      : SentinelTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Buttons
                      if (!_captured) ...[
                        SizedBox(
                          width: double.infinity,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isCapturing ? null : _captureReference,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      SentinelTheme.cyberCyan,
                                      SentinelTheme.cyberBlue,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: SentinelTheme.cyberCyan.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isCapturing
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.camera_alt,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'CAPTURE FACE',
                                              style: SentinelTheme.mono
                                                  .copyWith(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                    letterSpacing: 1.5,
                                                  ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _skip,
                          child: Text(
                            'Skip for now',
                            style: SentinelTheme.sans.copyWith(
                              fontSize: 12,
                              color: SentinelTheme.textMuted,
                            ),
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _proceed,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      SentinelTheme.alertGreen,
                                      SentinelTheme.cyberCyan,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: SentinelTheme.alertGreen
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_forward,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'CONTINUE TO DASHBOARD',
                                        style: SentinelTheme.mono.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _captured = false;
                              _isCapturing = false;
                              _capturedPath = null;
                              _status =
                                  'Position your face in front of the camera';
                            });
                          },
                          child: Text(
                            'Retake photo',
                            style: SentinelTheme.sans.copyWith(
                              fontSize: 12,
                              color: SentinelTheme.cyberBlue,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SentinelTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SentinelTheme.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield,
                        size: 16,
                        color: SentinelTheme.cyberBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your face data is stored locally and never leaves this device. '
                          'It is used solely for real-time identity verification.',
                          style: SentinelTheme.sans.copyWith(
                            fontSize: 10,
                            color: SentinelTheme.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _facePlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.face,
            size: 64,
            color: SentinelTheme.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'No capture yet',
            style: SentinelTheme.mono.copyWith(
              fontSize: 10,
              color: SentinelTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

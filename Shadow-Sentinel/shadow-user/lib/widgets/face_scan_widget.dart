import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/sentinel_theme.dart';

/// Animated face scan visualization with scanning radar effect,
/// face outline, confidence overlay, and glowing scan lines.
class FaceScanWidget extends StatefulWidget {
  final double confidence;
  final double livenessScore;
  final bool matched;
  final bool spoofingAttempt;
  final String scanMode;
  final bool isActive;

  const FaceScanWidget({
    super.key,
    required this.confidence,
    required this.livenessScore,
    required this.matched,
    required this.spoofingAttempt,
    required this.scanMode,
    required this.isActive,
  });

  @override
  State<FaceScanWidget> createState() => _FaceScanWidgetState();
}

class _FaceScanWidgetState extends State<FaceScanWidget>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _pulseController;
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.spoofingAttempt
        ? SentinelTheme.alertRed
        : widget.matched
            ? SentinelTheme.alertGreen
            : SentinelTheme.alertAmber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SentinelTheme.glassCard(glowColor: statusColor),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.face_retouching_natural, size: 16, color: SentinelTheme.cyberCyan),
              const SizedBox(width: 8),
              Text(
                'NEURAL FACE SCAN',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.cyberCyan,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  widget.scanMode,
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Scan visualization
          SizedBox(
            height: 220,
            child: AnimatedBuilder(
              animation: Listenable.merge([_radarController, _pulseController, _scanLineController]),
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(220, 220),
                  painter: _FaceScanPainter(
                    radarAngle: _radarController.value * 2 * pi,
                    pulseValue: _pulseController.value,
                    scanLineY: _scanLineController.value,
                    confidence: widget.confidence,
                    isActive: widget.isActive,
                    isSpoofing: widget.spoofingAttempt,
                    statusColor: statusColor,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Status text
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Text(
                widget.spoofingAttempt
                    ? '⚠ SPOOFING DETECTED — IDENTITY MISMATCH'
                    : widget.matched
                        ? '✓ IDENTITY VERIFIED — FACE MATCHED'
                        : '◉ SCANNING — ANALYZING FACE GEOMETRY',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor.withValues(alpha: 0.6 + _pulseController.value * 0.4),
                  letterSpacing: 0.5,
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Metrics row
          Row(
            children: [
              _MetricBox('CONFIDENCE', '${widget.confidence.toStringAsFixed(1)}%', statusColor),
              const SizedBox(width: 8),
              _MetricBox('LIVENESS', '${widget.livenessScore.toStringAsFixed(1)}%',
                  widget.livenessScore > 80 ? SentinelTheme.alertGreen : SentinelTheme.alertRed),
              const SizedBox(width: 8),
              _MetricBox('STATUS', widget.matched ? 'MATCH' : 'NO MATCH',
                  widget.matched ? SentinelTheme.alertGreen : SentinelTheme.alertRed),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: SentinelTheme.mono.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: SentinelTheme.mono.copyWith(
                fontSize: 8,
                color: SentinelTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceScanPainter extends CustomPainter {
  final double radarAngle;
  final double pulseValue;
  final double scanLineY;
  final double confidence;
  final bool isActive;
  final bool isSpoofing;
  final Color statusColor;

  _FaceScanPainter({
    required this.radarAngle,
    required this.pulseValue,
    required this.scanLineY,
    required this.confidence,
    required this.isActive,
    required this.isSpoofing,
    required this.statusColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Outer circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = SentinelTheme.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Inner circles (radar rings)
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        radius * (i / 3),
        Paint()
          ..color = SentinelTheme.border.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Cross lines
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      Paint()
        ..color = SentinelTheme.border.withValues(alpha: 0.2)
        ..strokeWidth = 0.5,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      Paint()
        ..color = SentinelTheme.border.withValues(alpha: 0.2)
        ..strokeWidth = 0.5,
    );

    if (isActive) {
      // Radar sweep
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: radarAngle - 0.5,
          endAngle: radarAngle,
          colors: [
            statusColor.withValues(alpha: 0),
            statusColor.withValues(alpha: 0.3),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(center, radius - 1, sweepPaint);

      // Scan line (horizontal moving down)
      final lineY = center.dy - radius + scanLineY * radius * 2;
      canvas.drawLine(
        Offset(center.dx - radius * 0.6, lineY),
        Offset(center.dx + radius * 0.6, lineY),
        Paint()
          ..color = statusColor.withValues(alpha: 0.4 + pulseValue * 0.3)
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Pulsing glow ring
      canvas.drawCircle(
        center,
        radius * (0.85 + pulseValue * 0.1),
        Paint()
          ..color = statusColor.withValues(alpha: 0.08 + pulseValue * 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }

    // Face oval outline
    final faceRect = Rect.fromCenter(
      center: center,
      width: radius * 0.7,
      height: radius * 0.95,
    );
    canvas.drawOval(
      faceRect,
      Paint()
        ..color = statusColor.withValues(alpha: 0.3 + pulseValue * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Eye positions (dots)
    final eyeY = center.dy - radius * 0.1;
    final eyeSpacing = radius * 0.15;
    for (final dx in [-eyeSpacing, eyeSpacing]) {
      canvas.drawCircle(
        Offset(center.dx + dx, eyeY),
        3,
        Paint()..color = statusColor.withValues(alpha: 0.5 + pulseValue * 0.3),
      );
    }

    // Nose line
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.02),
      Offset(center.dx, center.dy + radius * 0.12),
      Paint()
        ..color = statusColor.withValues(alpha: 0.2)
        ..strokeWidth = 1,
    );

    // Mouth arc
    final mouthRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.22),
      width: radius * 0.2,
      height: radius * 0.08,
    );
    canvas.drawArc(
      mouthRect,
      0,
      pi,
      false,
      Paint()
        ..color = statusColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Corner brackets
    final bracketLen = radius * 0.15;
    final corners = [
      Offset(center.dx - radius * 0.35, center.dy - radius * 0.48),
      Offset(center.dx + radius * 0.35, center.dy - radius * 0.48),
      Offset(center.dx - radius * 0.35, center.dy + radius * 0.48),
      Offset(center.dx + radius * 0.35, center.dy + radius * 0.48),
    ];

    final bracketPaint = Paint()
      ..color = statusColor.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Top-left bracket
    canvas.drawLine(corners[0], Offset(corners[0].dx + bracketLen, corners[0].dy), bracketPaint);
    canvas.drawLine(corners[0], Offset(corners[0].dx, corners[0].dy + bracketLen), bracketPaint);

    // Top-right bracket
    canvas.drawLine(corners[1], Offset(corners[1].dx - bracketLen, corners[1].dy), bracketPaint);
    canvas.drawLine(corners[1], Offset(corners[1].dx, corners[1].dy + bracketLen), bracketPaint);

    // Bottom-left bracket
    canvas.drawLine(corners[2], Offset(corners[2].dx + bracketLen, corners[2].dy), bracketPaint);
    canvas.drawLine(corners[2], Offset(corners[2].dx, corners[2].dy - bracketLen), bracketPaint);

    // Bottom-right bracket
    canvas.drawLine(corners[3], Offset(corners[3].dx - bracketLen, corners[3].dy), bracketPaint);
    canvas.drawLine(corners[3], Offset(corners[3].dx, corners[3].dy - bracketLen), bracketPaint);

    // Spoofing warning overlay
    if (isSpoofing) {
      canvas.drawCircle(
        center,
        radius * 0.9,
        Paint()
          ..color = SentinelTheme.alertRed.withValues(alpha: 0.1 + pulseValue * 0.1)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FaceScanPainter oldDelegate) => true;
}

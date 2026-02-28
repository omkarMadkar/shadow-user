import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sentinel_provider.dart';
import '../theme/sentinel_theme.dart';

/// Animated radial trust score gauge using CustomPaint.
class TrustGaugeWidget extends StatelessWidget {
  const TrustGaugeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: SentinelTheme.glassCard(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Consumer<SentinelProvider>(
                builder: (_, p, __) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SentinelTheme.trustColor(p.trustScore),
                    boxShadow: [
                      BoxShadow(
                        color: SentinelTheme.trustColor(p.trustScore).withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'IDENTITY CONFIDENCE',
                style: SentinelTheme.sans.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SentinelTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Gauge
          SizedBox(
            width: 180,
            height: 180,
            child: Consumer<SentinelProvider>(
              builder: (_, provider, __) {
                return CustomPaint(
                  painter: _TrustGaugePainter(
                    trust: provider.trustScore,
                    color: SentinelTheme.trustColor(provider.trustScore),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          provider.trustScore.round().toString(),
                          style: SentinelTheme.mono.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: SentinelTheme.trustColor(provider.trustScore),
                          ),
                        ),
                        Text(
                          'TRUST SCORE',
                          style: SentinelTheme.sans.copyWith(
                            fontSize: 9,
                            color: SentinelTheme.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Status Badge
          Consumer<SentinelProvider>(
            builder: (_, p, __) {
              final color = SentinelTheme.trustColor(p.trustScore);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  SentinelTheme.trustLabel(p.trustScore),
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrustGaugePainter extends CustomPainter {
  final double trust;
  final Color color;

  _TrustGaugePainter({required this.trust, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const startAngle = 135 * pi / 180;
    const sweepTotal = 270 * pi / 180;
    final sweepProgress = sweepTotal * (trust / 100.0);

    // Background track
    final bgPaint = Paint()
      ..color = SentinelTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    // Glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepProgress,
      false,
      glowPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepProgress,
      false,
      progressPaint,
    );

    // Tick marks
    for (int i = 0; i <= 10; i++) {
      final angle = (225 - (i / 10) * 270) * pi / 180;
      final isMajor = i % 2 == 0;
      final innerR = isMajor ? radius - 18 : radius - 14;
      final outerR = radius - 8;

      final p1 = Offset(center.dx + cos(angle) * innerR, center.dy - sin(angle) * innerR);
      final p2 = Offset(center.dx + cos(angle) * outerR, center.dy - sin(angle) * outerR);

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = isMajor ? const Color(0xFF475569) : const Color(0xFF334155)
          ..strokeWidth = isMajor ? 2 : 1,
      );

      if (isMajor) {
        final textR = radius - 28;
        final tp = TextPainter(
          text: TextSpan(
            text: '${i * 10}',
            style: TextStyle(
              color: SentinelTheme.textMuted,
              fontSize: 8,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        final tOffset = Offset(
          center.dx + cos(angle) * textR - tp.width / 2,
          center.dy - sin(angle) * textR - tp.height / 2,
        );
        tp.paint(canvas, tOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrustGaugePainter oldDelegate) =>
      oldDelegate.trust != trust || oldDelegate.color != color;
}

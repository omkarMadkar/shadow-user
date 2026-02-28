import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_sentinel_provider.dart';
import '../theme/sentinel_theme.dart';

/// Live audio waveform visualizer with animated bars.
class VoiceWaveformWidget extends StatelessWidget {
  const VoiceWaveformWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceSentinelProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: SentinelTheme.glassCard(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.graphic_eq,
                    color: SentinelTheme.cyberBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE AUDIO WAVEFORM',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: SentinelTheme.cyberBlue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  // Volume indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _volumeColor(
                        provider.currentVolume,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _volumeColor(
                          provider.currentVolume,
                        ).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${provider.currentVolume.toStringAsFixed(1)} dB',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _volumeColor(provider.currentVolume),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Waveform visualization
              SizedBox(
                height: 120,
                child: provider.waveformSamples.isEmpty
                    ? Center(
                        child: Text(
                          provider.micActive
                              ? 'Initializing audio stream...'
                              : 'Mic is OFF — tap to start monitoring',
                          style: SentinelTheme.mono.copyWith(
                            fontSize: 11,
                            color: SentinelTheme.textMuted,
                          ),
                        ),
                      )
                    : CustomPaint(
                        size: const Size(double.infinity, 120),
                        painter: _WaveformPainter(
                          samples: provider.waveformSamples,
                          micActive: provider.micActive,
                        ),
                      ),
              ),

              const SizedBox(height: 8),
              // Session info bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoChip(
                    icon: Icons.timer,
                    label: 'Session',
                    value: provider.formattedDuration,
                  ),
                  _InfoChip(
                    icon: Icons.storage,
                    label: 'Chunks',
                    value: '${provider.totalChunksRecorded}',
                  ),
                  _InfoChip(
                    icon: Icons.show_chart,
                    label: 'Avg Vol',
                    value: '${provider.avgVolume.toStringAsFixed(1)}',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _volumeColor(double vol) {
    if (vol > 80) return SentinelTheme.alertRed;
    if (vol > 50) return SentinelTheme.alertAmber;
    return SentinelTheme.alertGreen;
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: SentinelTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: SentinelTheme.mono.copyWith(
            fontSize: 9,
            color: SentinelTheme.textMuted,
          ),
        ),
        Text(
          value,
          style: SentinelTheme.mono.copyWith(
            fontSize: 9,
            color: SentinelTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the waveform bars.
class _WaveformPainter extends CustomPainter {
  final List<dynamic> samples;
  final bool micActive;

  _WaveformPainter({required this.samples, required this.micActive});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final barWidth = size.width / samples.length;
    final midY = size.height / 2;

    for (int i = 0; i < samples.length; i++) {
      final sample = samples[i];
      final amplitude = sample.amplitude as double;
      final isFlagged = sample.isFlagged as bool;

      final barHeight = amplitude * size.height * 0.8;
      final x = i * barWidth;

      // Gradient color based on amplitude
      Color barColor;
      if (isFlagged) {
        barColor = SentinelTheme.alertRed.withValues(alpha: 0.8);
      } else if (amplitude > 0.6) {
        barColor = SentinelTheme.alertAmber.withValues(alpha: 0.7);
      } else {
        barColor = SentinelTheme.cyberBlue.withValues(alpha: 0.6);
      }

      final paint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      // Draw mirrored bar
      final rect = Rect.fromCenter(
        center: Offset(x + barWidth / 2, midY),
        width: barWidth * 0.7,
        height: barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1)),
        paint,
      );

      // Glow effect for flagged
      if (isFlagged) {
        final glowPaint = Paint()
          ..color = SentinelTheme.alertRed.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1)),
          glowPaint,
        );
      }
    }

    // Center line
    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      Paint()
        ..color = SentinelTheme.border
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}

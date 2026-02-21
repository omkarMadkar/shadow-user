import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/keystroke_provider.dart';
import '../theme/sentinel_theme.dart';

/// Real-time typing rhythm waveform — alternating dwell (blue) and flight (cyan) bars.
class KeystrokeWaveformWidget extends StatelessWidget {
  const KeystrokeWaveformWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: SentinelTheme.glassCard(glowColor: SentinelTheme.cyberBlue),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.graphic_eq, size: 16, color: SentinelTheme.cyberBlue),
              const SizedBox(width: 8),
              Text(
                'TYPING RHYTHM WAVEFORM',
                style: SentinelTheme.sans.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SentinelTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Consumer<KeystrokeProvider>(
                builder: (_, p, __) => Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: SentinelTheme.cyberBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Dwell',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 9,
                        color: SentinelTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: SentinelTheme.cyberCyan,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Flight',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 9,
                        color: SentinelTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Waveform
          Expanded(
            child: Consumer<KeystrokeProvider>(
              builder: (_, p, __) {
                final dwells = p.dwellWaveform;
                final flights = p.flightWaveform;
                final count = dwells.length > flights.length
                    ? dwells.length
                    : flights.length;

                if (count == 0) {
                  return Center(
                    child: Text(
                      'Start typing to see rhythm waveform…',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 11,
                        color: SentinelTheme.textMuted,
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _WaveformPainter(
                        dwells: dwells,
                        flights: flights,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> dwells;
  final List<double> flights;

  _WaveformPainter({required this.dwells, required this.flights});

  @override
  void paint(Canvas canvas, Size size) {
    if (dwells.isEmpty && flights.isEmpty) return;

    final maxBars = dwells.length + flights.length;
    if (maxBars == 0) return;

    final barWidth = (size.width / (maxBars + 2)).clamp(2.0, 8.0);
    final gap = 1.5;
    final midY = size.height / 2;

    // Find max value for normalization
    double maxVal = 200;
    for (final d in dwells) {
      if (d > maxVal) maxVal = d;
    }
    for (final f in flights) {
      if (f > maxVal) maxVal = f;
    }

    final dwellPaint = Paint()
      ..color = SentinelTheme.cyberBlue.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final flightPaint = Paint()
      ..color = SentinelTheme.cyberCyan.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    double x = 4;
    final minLen = dwells.length < flights.length
        ? dwells.length
        : flights.length;

    for (int i = 0; i < minLen; i++) {
      // Dwell bar (goes up)
      final dwellH = (dwells[i] / maxVal) * (midY - 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, midY - dwellH, barWidth, dwellH),
          const Radius.circular(1.5),
        ),
        dwellPaint,
      );
      x += barWidth + gap;

      // Flight bar (goes down)
      final flightH = (flights[i] / maxVal) * (midY - 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, midY, barWidth, flightH),
          const Radius.circular(1.5),
        ),
        flightPaint,
      );
      x += barWidth + gap;

      if (x > size.width - barWidth) break;
    }

    // Center line
    final linePaint = Paint()
      ..color = SentinelTheme.border
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), linePaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) => true;
}

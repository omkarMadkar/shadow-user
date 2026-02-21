import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/keystroke_provider.dart';
import '../theme/sentinel_theme.dart';

/// Line chart showing anomaly score over time with green/amber/red zones.
class KeystrokePatternChart extends StatelessWidget {
  const KeystrokePatternChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: SentinelTheme.glassCard(glowColor: SentinelTheme.cyberCyan),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, size: 16, color: SentinelTheme.cyberCyan),
              const SizedBox(width: 8),
              Text(
                'ANOMALY SCORE TIMELINE',
                style: SentinelTheme.sans.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SentinelTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              // Zone legend
              _ZoneDot(color: SentinelTheme.alertGreen, label: 'Safe'),
              const SizedBox(width: 8),
              _ZoneDot(color: SentinelTheme.alertAmber, label: 'Warning'),
              const SizedBox(width: 8),
              _ZoneDot(color: SentinelTheme.alertRed, label: 'Critical'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Consumer<KeystrokeProvider>(
              builder: (_, p, __) {
                final data = p.history;
                if (data.isEmpty) {
                  return Center(
                    child: Text(
                      'Anomaly spikes appear when threats are detected…',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 11,
                        color: SentinelTheme.textMuted,
                      ),
                    ),
                  );
                }

                final spots = <FlSpot>[];
                for (int i = 0; i < data.length; i++) {
                  spots.add(FlSpot(i.toDouble(), data[i].anomalyScore * 100));
                }

                return LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 100,
                    clipData: const FlClipData.all(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 30,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: SentinelTheme.border, strokeWidth: 0.5),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 30,
                          getTitlesWidget: (value, _) => Text(
                            '${value.round()}%',
                            style: SentinelTheme.mono.copyWith(
                              fontSize: 8,
                              color: SentinelTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    // Zone backgrounds
                    rangeAnnotations: RangeAnnotations(
                      horizontalRangeAnnotations: [
                        HorizontalRangeAnnotation(
                          y1: 0,
                          y2: 30,
                          color: SentinelTheme.alertGreen.withValues(
                            alpha: 0.05,
                          ),
                        ),
                        HorizontalRangeAnnotation(
                          y1: 30,
                          y2: 60,
                          color: SentinelTheme.alertAmber.withValues(
                            alpha: 0.05,
                          ),
                        ),
                        HorizontalRangeAnnotation(
                          y1: 60,
                          y2: 100,
                          color: SentinelTheme.alertRed.withValues(alpha: 0.05),
                        ),
                      ],
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        preventCurveOverShooting: true,
                        color: SentinelTheme.cyberCyan,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              SentinelTheme.cyberCyan.withValues(alpha: 0.2),
                              SentinelTheme.cyberCyan.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) => spots.map((s) {
                          return LineTooltipItem(
                            'Anomaly: ${s.y.round()}%',
                            SentinelTheme.mono.copyWith(
                              fontSize: 10,
                              color: SentinelTheme.textPrimary,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneDot extends StatelessWidget {
  final Color color;
  final String label;
  const _ZoneDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: SentinelTheme.mono.copyWith(
            fontSize: 8,
            color: SentinelTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

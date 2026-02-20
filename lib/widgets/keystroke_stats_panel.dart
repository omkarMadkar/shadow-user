import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/keystroke_provider.dart';
import '../theme/sentinel_theme.dart';

/// Four metric cards: WPM, Avg Dwell, Avg Flight, Anomaly Score.
class KeystrokeStatsPanel extends StatelessWidget {
  const KeystrokeStatsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<KeystrokeProvider>(
      builder: (_, p, __) {
        return Container(
          decoration: SentinelTheme.glassCard(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.speed, size: 16, color: SentinelTheme.cyberBlue),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE METRICS',
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
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'WPM',
                      value: p.currentWpm.round().toString(),
                      icon: Icons.text_fields,
                      color: SentinelTheme.cyberBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      label: 'DWELL',
                      value: '${p.currentDwellMs.round()}ms',
                      icon: Icons.timer_outlined,
                      color: SentinelTheme.cyberCyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'FLIGHT',
                      value: '${p.currentFlightMs.round()}ms',
                      icon: Icons.flight,
                      color: SentinelTheme.alertGreen,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      label: 'ANOMALY',
                      value: '${(p.anomalyScore * 100).round()}%',
                      icon: Icons.warning_amber_rounded,
                      color: _anomalyColor(p.anomalyScore),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Match score bar
              _MatchScoreBar(score: p.keystrokeMatchScore),
            ],
          ),
        );
      },
    );
  }

  static Color _anomalyColor(double score) {
    if (score < 0.3) return SentinelTheme.alertGreen;
    if (score < 0.6) return SentinelTheme.alertAmber;
    return SentinelTheme.alertRed;
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SentinelTheme.bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: SentinelTheme.sans.copyWith(
                  fontSize: 9,
                  color: SentinelTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: SentinelTheme.mono.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchScoreBar extends StatelessWidget {
  final double score;
  const _MatchScoreBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = SentinelTheme.trustColor(score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'KEYSTROKE MATCH',
              style: SentinelTheme.sans.copyWith(
                fontSize: 9,
                color: SentinelTheme.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${score.round()}%',
              style: SentinelTheme.mono.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 6,
            backgroundColor: SentinelTheme.border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

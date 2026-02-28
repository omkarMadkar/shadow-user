import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/voice_sentinel_provider.dart';
import '../theme/sentinel_theme.dart';

/// Voice monitoring statistics panel with alert breakdown.
class VoiceStatsPanel extends StatelessWidget {
  const VoiceStatsPanel({super.key});

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
                    Icons.analytics,
                    color: SentinelTheme.cyberCyan,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'VOICE ANALYTICS',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: SentinelTheme.cyberCyan,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Stat boxes row
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      icon: Icons.storage,
                      value: '${provider.totalChunksRecorded}',
                      label: 'CHUNKS RECORDED',
                      color: SentinelTheme.cyberBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatBox(
                      icon: Icons.warning_amber,
                      value: '${provider.totalAlertsCount}',
                      label: 'ALERTS TRIGGERED',
                      color: SentinelTheme.alertRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      icon: Icons.check_circle,
                      value: '${provider.cleanRatio.toStringAsFixed(1)}%',
                      label: 'CLEAN RATIO',
                      color: SentinelTheme.alertGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatBox(
                      icon: Icons.multitrack_audio,
                      value: '${provider.sessionsCount}',
                      label: 'TOTAL SESSIONS',
                      color: SentinelTheme.cyberCyan,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Alert breakdown
              Text(
                'ALERT BREAKDOWN',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              ..._buildBreakdownBars(provider),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildBreakdownBars(VoiceSentinelProvider provider) {
    final breakdown = provider.alertBreakdown;
    final maxVal = breakdown.values.fold<int>(
      1,
      (max, val) => val > max ? val : max,
    );

    return LanguageAlertType.values.map((type) {
      final count = breakdown[type] ?? 0;
      final ratio = count / maxVal;
      final color = _alertTypeColor(type);
      final label = type.name.toUpperCase();

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  color: SentinelTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: SentinelTheme.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: ratio.clamp(0.0, 1.0),
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.6), color],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 24,
              child: Text(
                '$count',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _alertTypeColor(LanguageAlertType type) {
    switch (type) {
      case LanguageAlertType.profanity:
        return SentinelTheme.alertAmber;
      case LanguageAlertType.hostility:
        return SentinelTheme.alertRed;
      case LanguageAlertType.threat:
        return const Color(0xFFDC2626);
      case LanguageAlertType.harassment:
        return const Color(0xFFF97316);
      case LanguageAlertType.toxic:
        return const Color(0xFF8B5CF6);
    }
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SentinelTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SentinelTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 8,
                    color: SentinelTheme.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

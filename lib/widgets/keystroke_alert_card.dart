import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/keystroke_provider.dart';
import '../models/models.dart';
import '../theme/sentinel_theme.dart';

/// Alert cards for keystroke anomalies.
class KeystrokeAlertCard extends StatelessWidget {
  const KeystrokeAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: SentinelTheme.glassCard(glowColor: SentinelTheme.alertRed),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notification_important,
                size: 16,
                color: SentinelTheme.alertRed,
              ),
              const SizedBox(width: 8),
              Text(
                'KEYSTROKE ALERTS',
                style: SentinelTheme.sans.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SentinelTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Consumer<KeystrokeProvider>(
                builder: (_, p, __) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: SentinelTheme.alertRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: SentinelTheme.alertRed.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '${p.alerts.length}',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: SentinelTheme.alertRed,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Consumer<KeystrokeProvider>(
              builder: (_, p, __) {
                if (p.alerts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 28,
                          color: SentinelTheme.alertGreen.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No anomalies detected',
                          style: SentinelTheme.mono.copyWith(
                            fontSize: 11,
                            color: SentinelTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: p.alerts.length > 10 ? 10 : p.alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _AlertTile(alert: p.alerts[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final KeystrokeAlert alert;
  const _AlertTile({required this.alert});

  Color get _severityColor {
    switch (alert.severity) {
      case ThreatSeverity.critical:
        return SentinelTheme.alertRed;
      case ThreatSeverity.high:
        return const Color(0xFFF97316);
      case ThreatSeverity.medium:
        return SentinelTheme.alertAmber;
      case ThreatSeverity.low:
        return SentinelTheme.alertGreen;
    }
  }

  IconData get _alertIcon {
    switch (alert.alertType) {
      case KeystrokeAlertType.possibleSwitch:
        return Icons.person_off;
      case KeystrokeAlertType.patternDrift:
        return Icons.trending_up;
      case KeystrokeAlertType.anomalySpike:
        return Icons.bolt;
      case KeystrokeAlertType.enrollmentComplete:
        return Icons.verified;
      case KeystrokeAlertType.baselineReset:
        return Icons.restart_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = alert.timestamp;
    final timeStr =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _severityColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _severityColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _severityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(_alertIcon, size: 14, color: _severityColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.message,
                  style: SentinelTheme.sans.copyWith(
                    fontSize: 11,
                    color: SentinelTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
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
    );
  }
}

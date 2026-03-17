import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/sentinel_provider.dart';
import '../theme/sentinel_theme.dart';

/// Aggregate email scanning statistics panel with animated counters
/// and threat category breakdown.
class EmailStatsPanel extends StatelessWidget {
  const EmailStatsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SentinelProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: SentinelTheme.glassCard(glowColor: SentinelTheme.cyberBlue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.analytics, size: 16, color: SentinelTheme.cyberBlue),
                  const SizedBox(width: 8),
                  Text(
                    'SCAN ANALYTICS',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: SentinelTheme.cyberBlue,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: provider.emailScanActive
                          ? SentinelTheme.alertGreen.withValues(alpha: 0.1)
                          : SentinelTheme.alertRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: provider.emailScanActive
                            ? SentinelTheme.alertGreen.withValues(alpha: 0.3)
                            : SentinelTheme.alertRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: provider.emailScanActive
                                ? SentinelTheme.alertGreen
                                : SentinelTheme.alertRed,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          provider.emailScanActive ? 'SCANNING' : 'PAUSED',
                          style: SentinelTheme.mono.copyWith(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: provider.emailScanActive
                                ? SentinelTheme.alertGreen
                                : SentinelTheme.alertRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Main stats row
              Row(
                children: [
                  _StatBox(
                    label: 'SCANNED',
                    value: '${provider.totalScanned}',
                    color: SentinelTheme.cyberBlue,
                    icon: Icons.email,
                  ),
                  const SizedBox(width: 8),
                  _StatBox(
                    label: 'BLOCKED',
                    value: '${provider.threatsBlocked}',
                    color: SentinelTheme.alertRed,
                    icon: Icons.block,
                  ),
                  const SizedBox(width: 8),
                  _StatBox(
                    label: 'SAFE',
                    value: '${provider.safeEmailsCount}',
                    color: SentinelTheme.alertGreen,
                    icon: Icons.verified_user,
                  ),
                  const SizedBox(width: 8),
                  _StatBox(
                    label: 'QUARANTINE',
                    value: '${provider.quarantinedCount}',
                    color: SentinelTheme.alertAmber,
                    icon: Icons.warning_amber,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Threat breakdown
              Text(
                'THREAT BREAKDOWN',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),

              ...provider.threatBreakdown.entries.map((entry) {
                final total =
                    provider.threatBreakdown.values.fold<int>(0, (s, v) => s + v);
                final ratio = total > 0 ? entry.value / total : 0.0;
                return _ThreatBar(
                  label: _threatLabel(entry.key),
                  count: entry.value,
                  ratio: ratio,
                  color: _threatBarColor(entry.key),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _threatLabel(EmailThreatType type) {
    switch (type) {
      case EmailThreatType.phishing:
        return 'Phishing';
      case EmailThreatType.malware:
        return 'Malware';
      case EmailThreatType.spoofing:
        return 'Spoofing';
      case EmailThreatType.spam:
        return 'Spam';
      case EmailThreatType.suspicious:
        return 'Suspicious';
      case EmailThreatType.safe:
        return 'Safe';
    }
  }

  Color _threatBarColor(EmailThreatType type) {
    switch (type) {
      case EmailThreatType.phishing:
        return SentinelTheme.alertRed;
      case EmailThreatType.malware:
        return const Color(0xFFDC2626);
      case EmailThreatType.spoofing:
        return const Color(0xFFF97316);
      case EmailThreatType.spam:
        return SentinelTheme.alertAmber;
      case EmailThreatType.suspicious:
        return SentinelTheme.cyberBlue;
      case EmailThreatType.safe:
        return SentinelTheme.alertGreen;
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: SentinelTheme.mono.copyWith(
                fontSize: 18,
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

class _ThreatBar extends StatelessWidget {
  final String label;
  final int count;
  final double ratio;
  final Color color;

  const _ThreatBar({
    required this.label,
    required this.count,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: SentinelTheme.sans.copyWith(
                fontSize: 10,
                color: SentinelTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: SentinelTheme.border,
                color: color,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: SentinelTheme.mono.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

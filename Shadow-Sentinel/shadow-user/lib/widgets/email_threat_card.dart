import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/sentinel_theme.dart';

/// Individual email threat display card with severity coloring,
/// risk score bar, threat type badge, and analysis indicators.
class EmailThreatCard extends StatelessWidget {
  final EmailThreat threat;

  const EmailThreatCard({super.key, required this.threat});

  Color _threatColor() {
    switch (threat.threatType) {
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

  IconData _threatIcon() {
    switch (threat.threatType) {
      case EmailThreatType.phishing:
        return Icons.phishing;
      case EmailThreatType.malware:
        return Icons.bug_report;
      case EmailThreatType.spoofing:
        return Icons.person_off;
      case EmailThreatType.spam:
        return Icons.mark_email_unread;
      case EmailThreatType.suspicious:
        return Icons.help_outline;
      case EmailThreatType.safe:
        return Icons.check_circle;
    }
  }

  String _statusLabel() {
    switch (threat.status) {
      case EmailThreatStatus.blocked:
        return 'BLOCKED';
      case EmailThreatStatus.quarantined:
        return 'QUARANTINED';
      case EmailThreatStatus.flagged:
        return 'FLAGGED';
      case EmailThreatStatus.delivered:
        return 'DELIVERED';
    }
  }

  String _typeLabel() {
    switch (threat.threatType) {
      case EmailThreatType.phishing:
        return 'PHISHING';
      case EmailThreatType.malware:
        return 'MALWARE';
      case EmailThreatType.spoofing:
        return 'SPOOFING';
      case EmailThreatType.spam:
        return 'SPAM';
      case EmailThreatType.suspicious:
        return 'SUSPICIOUS';
      case EmailThreatType.safe:
        return 'SAFE';
    }
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(threat.timestamp);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = _threatColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withValues(alpha: 0.06),
            SentinelTheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon, sender, time, status badge
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_threatIcon(), size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      threat.sender,
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      threat.senderDomain,
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 9,
                        color: SentinelTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _typeLabel(),
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: SentinelTheme.alertRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel(),
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: SentinelTheme.alertRed,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Subject
          Text(
            threat.subject,
            style: SentinelTheme.sans.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: SentinelTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          // Analysis detail
          Text(
            threat.analysisDetail,
            style: SentinelTheme.sans.copyWith(
              fontSize: 10,
              color: SentinelTheme.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Risk bar + indicators
          Row(
            children: [
              // Risk score bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Risk Score',
                          style: SentinelTheme.mono.copyWith(
                            fontSize: 9,
                            color: SentinelTheme.textMuted,
                          ),
                        ),
                        Text(
                          '${(threat.riskScore * 100).toInt()}%',
                          style: SentinelTheme.mono.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: threat.riskScore,
                        backgroundColor: SentinelTheme.border,
                        color: color,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Time
              Text(
                _timeAgo(),
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  color: SentinelTheme.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Indicator tags
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: threat.indicators.map((ind) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.12)),
                ),
                child: Text(
                  ind,
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 8,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

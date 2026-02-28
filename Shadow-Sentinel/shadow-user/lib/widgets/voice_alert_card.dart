import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/sentinel_theme.dart';

/// Card displaying a single voice language alert.
class VoiceAlertCard extends StatelessWidget {
  final VoiceLanguageAlert alert;

  const VoiceAlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(alert.severity);
    final elapsed = DateTime.now().difference(alert.timestamp);
    final timeAgo = _formatElapsed(elapsed);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: SentinelTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: alert type + severity + timestamp
            Row(
              children: [
                // Alert type icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _alertIcon(alert.alertType),
                    size: 14,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.flaggedPhrase.toUpperCase(),
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.context,
                        style: SentinelTheme.sans.copyWith(
                          fontSize: 10,
                          color: SentinelTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeAgo,
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    color: SentinelTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Bottom row: badges
            Row(
              children: [
                _Badge(label: _alertTypeLabel(alert.alertType), color: color),
                const SizedBox(width: 6),
                _Badge(label: alert.severity.name.toUpperCase(), color: color),
                const Spacer(),
                // Confidence bar
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Confidence ${alert.confidenceScore.toStringAsFixed(1)}%',
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 8,
                          color: SentinelTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: alert.confidenceScore / 100,
                          backgroundColor: SentinelTheme.border,
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(VoiceSeverity severity) {
    switch (severity) {
      case VoiceSeverity.severe:
        return SentinelTheme.alertRed;
      case VoiceSeverity.moderate:
        return SentinelTheme.alertAmber;
      case VoiceSeverity.mild:
        return const Color(0xFFF97316); // orange
      case VoiceSeverity.clean:
        return SentinelTheme.alertGreen;
    }
  }

  IconData _alertIcon(LanguageAlertType type) {
    switch (type) {
      case LanguageAlertType.profanity:
        return Icons.warning_amber;
      case LanguageAlertType.hostility:
        return Icons.flash_on;
      case LanguageAlertType.threat:
        return Icons.gpp_bad;
      case LanguageAlertType.harassment:
        return Icons.person_off;
      case LanguageAlertType.toxic:
        return Icons.dangerous;
    }
  }

  String _alertTypeLabel(LanguageAlertType type) {
    switch (type) {
      case LanguageAlertType.profanity:
        return 'PROFANITY';
      case LanguageAlertType.hostility:
        return 'HOSTILITY';
      case LanguageAlertType.threat:
        return 'THREAT';
      case LanguageAlertType.harassment:
        return 'HARASSMENT';
      case LanguageAlertType.toxic:
        return 'TOXIC';
    }
  }

  String _formatElapsed(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: SentinelTheme.mono.copyWith(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

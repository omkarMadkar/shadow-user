import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/sentinel_theme.dart';

/// Camera detection history timeline showing past scan results
/// with confidence, liveness, and alert indicators.
class CameraLogWidget extends StatelessWidget {
  final List<CameraSessionLog> logs;

  const CameraLogWidget({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SentinelTheme.glassCard(glowColor: SentinelTheme.cyberBlue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.history, size: 16, color: SentinelTheme.cyberBlue),
              const SizedBox(width: 8),
              Text(
                'DETECTION LOG',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.cyberBlue,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${logs.length} entries',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  color: SentinelTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Log entries
          Expanded(
            child: ListView.builder(
              itemCount: logs.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _LogEntry(log: log);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  final CameraSessionLog log;

  const _LogEntry({required this.log});

  String _timeAgo() {
    final diff = DateTime.now().difference(log.timestamp);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final isAlert = log.spoofingAttempt;
    final color = isAlert
        ? SentinelTheme.alertRed
        : log.matched
            ? SentinelTheme.alertGreen
            : SentinelTheme.alertAmber;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                  border: Border.all(color: color, width: 1.5),
                ),
              ),
              Container(
                width: 1,
                height: 35,
                color: SentinelTheme.border.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isAlert
                    ? SentinelTheme.alertRed.withValues(alpha: 0.04)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isAlert
                      ? SentinelTheme.alertRed.withValues(alpha: 0.1)
                      : SentinelTheme.border.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isAlert ? Icons.warning_amber : Icons.check_circle_outline,
                        size: 12,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          log.detail,
                          style: SentinelTheme.sans.copyWith(
                            fontSize: 10,
                            color: isAlert
                                ? SentinelTheme.alertRed
                                : SentinelTheme.textSecondary,
                            fontWeight: isAlert ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Conf: ${log.confidence.toStringAsFixed(1)}%',
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 8,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live: ${log.livenessScore.toStringAsFixed(1)}%',
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 8,
                          color: SentinelTheme.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(),
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 8,
                          color: SentinelTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

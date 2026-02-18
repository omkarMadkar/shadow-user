import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sentinel_provider.dart';
import '../models/models.dart';
import '../theme/sentinel_theme.dart';

/// Threat overview panel + online users list.
class ThreatOverviewPanel extends StatelessWidget {
  const ThreatOverviewPanel({super.key});

  Color _severityColor(ThreatSeverity sev) {
    switch (sev) {
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

  Color _statusColor(UserVerificationStatus status) {
    switch (status) {
      case UserVerificationStatus.verified:
        return SentinelTheme.alertGreen;
      case UserVerificationStatus.monitoring:
        return SentinelTheme.alertAmber;
      case UserVerificationStatus.flagged:
        return SentinelTheme.alertRed;
      case UserVerificationStatus.locked:
        return SentinelTheme.alertRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Active Threats ──
        Container(
          decoration: SentinelTheme.glassCard(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: SentinelTheme.alertRed),
                      const SizedBox(width: 8),
                      Text(
                        'ACTIVE THREATS',
                        style: SentinelTheme.sans.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: SentinelTheme.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Consumer<SentinelProvider>(
                    builder: (_, p, __) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: SentinelTheme.alertRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: SentinelTheme.alertRed.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '${p.totalThreats} ACTIVE',
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: SentinelTheme.alertRed,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Consumer<SentinelProvider>(
                builder: (_, provider, __) {
                  return Column(
                    children: provider.threats.map((t) {
                      final color = _severityColor(t.severity);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: SentinelTheme.bg.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: SentinelTheme.border.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  t.label,
                                  style: SentinelTheme.sans.copyWith(
                                    fontSize: 13,
                                    color: SentinelTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  '${t.count}',
                                  style: SentinelTheme.mono.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  t.trend == 'up' ? '▲' : t.trend == 'down' ? '▼' : '—',
                                  style: SentinelTheme.sans.copyWith(
                                    fontSize: 9,
                                    color: SentinelTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Users Online ──
        Container(
          decoration: SentinelTheme.glassCard(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 16, color: SentinelTheme.cyberBlue),
                      const SizedBox(width: 8),
                      Text(
                        'USERS ONLINE',
                        style: SentinelTheme.sans.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: SentinelTheme.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Consumer<SentinelProvider>(
                    builder: (_, p, __) => Text(
                      '${p.onlineUsers.length} active',
                      style: SentinelTheme.sans.copyWith(
                        fontSize: 11,
                        color: SentinelTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Consumer<SentinelProvider>(
                builder: (_, provider, __) {
                  return Column(
                    children: provider.onlineUsers.map((u) {
                      final initials = u.name.split(' ').map((n) => n[0]).join('');
                      final statusColor = _statusColor(u.status);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: SentinelTheme.surfaceAlt,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: SentinelTheme.border),
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: SentinelTheme.sans.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: SentinelTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Name & dept
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u.name,
                                    style: SentinelTheme.sans.copyWith(
                                      fontSize: 13,
                                      color: SentinelTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    u.department,
                                    style: SentinelTheme.sans.copyWith(
                                      fontSize: 10,
                                      color: SentinelTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Score
                            Text(
                              '${u.trustScore.round()}%',
                              style: SentinelTheme.mono.copyWith(
                                fontSize: 12,
                                color: SentinelTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Status
                            Text(
                              u.status.name.toUpperCase(),
                              style: SentinelTheme.mono.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

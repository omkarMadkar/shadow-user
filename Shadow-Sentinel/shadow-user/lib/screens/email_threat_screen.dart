import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sentinel_provider.dart';
import '../theme/sentinel_theme.dart';
import '../widgets/email_threat_card.dart';
import '../widgets/email_stats_panel.dart';

/// Full email fraud detection dashboard screen.
class EmailThreatScreen extends StatelessWidget {
  const EmailThreatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SentinelProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Email Identity Card ──────────────────────
              _EmailIdentityCard(provider: provider),

              const SizedBox(height: 16),

              // ── Layout ──────────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return _wideLayout(provider);
                  }
                  return _narrowLayout(provider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _wideLayout(SentinelProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Stats panel
        SizedBox(
          width: 340,
          child: const EmailStatsPanel(),
        ),
        const SizedBox(width: 16),
        // Right: Threat feed
        Expanded(
          child: _ThreatFeed(provider: provider),
        ),
      ],
    );
  }

  Widget _narrowLayout(SentinelProvider provider) {
    return Column(
      children: [
        const EmailStatsPanel(),
        const SizedBox(height: 16),
        _ThreatFeed(provider: provider),
      ],
    );
  }
}

// ─── Email Identity Card ──────────────────────────────────────

class _EmailIdentityCard extends StatelessWidget {
  final SentinelProvider provider;

  const _EmailIdentityCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final safeRatio = provider.totalScanned > 0
        ? (provider.safeEmailsCount / provider.totalScanned * 100)
        : 100.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SentinelTheme.glassCard(glowColor: SentinelTheme.cyberCyan),
      child: Row(
        children: [
          // Email icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SentinelTheme.cyberBlue.withValues(alpha: 0.15),
                  SentinelTheme.cyberCyan.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SentinelTheme.cyberBlue.withValues(alpha: 0.2)),
            ),
            child: Icon(Icons.email, color: SentinelTheme.cyberBlue, size: 24),
          ),
          const SizedBox(width: 14),

          // Email info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MONITORED INBOX',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    color: SentinelTheme.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  SentinelProvider.userEmail,
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SentinelTheme.cyberCyan,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gmail • IMAP Scanning • Real-time Protection',
                  style: SentinelTheme.sans.copyWith(
                    fontSize: 10,
                    color: SentinelTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Protection score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PROTECTION',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 8,
                  color: SentinelTheme.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${safeRatio.toStringAsFixed(1)}%',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: safeRatio > 85
                      ? SentinelTheme.alertGreen
                      : safeRatio > 70
                          ? SentinelTheme.alertAmber
                          : SentinelTheme.alertRed,
                ),
              ),
              Text(
                'Safe Ratio',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 8,
                  color: SentinelTheme.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Scan toggle
          GestureDetector(
            onTap: provider.toggleEmailScan,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: provider.emailScanActive
                    ? SentinelTheme.alertGreen.withValues(alpha: 0.1)
                    : SentinelTheme.alertRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: provider.emailScanActive
                      ? SentinelTheme.alertGreen.withValues(alpha: 0.3)
                      : SentinelTheme.alertRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    provider.emailScanActive ? Icons.shield : Icons.shield_outlined,
                    size: 14,
                    color: provider.emailScanActive
                        ? SentinelTheme.alertGreen
                        : SentinelTheme.alertRed,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    provider.emailScanActive ? 'ACTIVE' : 'PAUSED',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: provider.emailScanActive
                          ? SentinelTheme.alertGreen
                          : SentinelTheme.alertRed,
                    ),
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

// ─── Threat Feed ──────────────────────────────────────────────

class _ThreatFeed extends StatelessWidget {
  final SentinelProvider provider;

  const _ThreatFeed({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SentinelTheme.glassCard(glowColor: SentinelTheme.alertRed),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.warning_amber, size: 16, color: SentinelTheme.alertRed),
              const SizedBox(width: 8),
              Text(
                'LIVE THREAT FEED',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.alertRed,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: provider.emailScanActive
                      ? SentinelTheme.alertRed
                      : SentinelTheme.textMuted,
                  boxShadow: provider.emailScanActive
                      ? [
                          BoxShadow(
                            color: SentinelTheme.alertRed.withValues(alpha: 0.5),
                            blurRadius: 6,
                          )
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${provider.emailThreats.length} threats detected',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  color: SentinelTheme.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Threat cards
          ...provider.emailThreats.take(10).map(
                (threat) => EmailThreatCard(threat: threat),
              ),

          if (provider.emailThreats.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 40, color: SentinelTheme.alertGreen),
                    const SizedBox(height: 12),
                    Text(
                      'No threats detected',
                      style: SentinelTheme.sans.copyWith(
                        fontSize: 14,
                        color: SentinelTheme.alertGreen,
                      ),
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

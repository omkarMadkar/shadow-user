import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_sentinel_provider.dart';
import '../theme/sentinel_theme.dart';
import '../widgets/voice_waveform_widget.dart';
import '../widgets/voice_alert_card.dart';
import '../widgets/voice_stats_panel.dart';
import '../widgets/voice_log_widget.dart';

/// Voice Sentinel tab — mic monitoring, language analysis, alert feed.
class VoiceSentinelScreen extends StatelessWidget {
  const VoiceSentinelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceSentinelProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Header Card ──────────────────────────────
              _VoiceHeaderCard(provider: provider),
              const SizedBox(height: 16),

              // ── Main Content ─────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 900;

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              const VoiceWaveformWidget(),
                              const SizedBox(height: 16),
                              _AlertFeed(alerts: provider.recentAlerts),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right column
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              const VoiceStatsPanel(),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 400,
                                child: const VoiceLogWidget(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // Narrow layout
                  return Column(
                    children: [
                      const VoiceWaveformWidget(),
                      const SizedBox(height: 16),
                      const VoiceStatsPanel(),
                      const SizedBox(height: 16),
                      _AlertFeed(alerts: provider.recentAlerts),
                      const SizedBox(height: 16),
                      SizedBox(height: 350, child: const VoiceLogWidget()),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Header Card ─────────────────────────────────────────────

class _VoiceHeaderCard extends StatelessWidget {
  final VoiceSentinelProvider provider;

  const _VoiceHeaderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isActive = provider.micActive;
    final statusColor = isActive
        ? SentinelTheme.alertGreen
        : SentinelTheme.textMuted;

    return Container(
      decoration: SentinelTheme.glassCard(),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Mic icon with pulse
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isActive ? Icons.mic : Icons.mic_off,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Title & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VOICE SENTINEL SYSTEM',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: SentinelTheme.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real-Time Language Monitoring',
                  style: SentinelTheme.sans.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SentinelTheme.cyberBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Speech Analysis • Harsh Language Detection • Audio Chunking',
                  style: SentinelTheme.sans.copyWith(
                    fontSize: 11,
                    color: SentinelTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Clean ratio display
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'CLEAN RATIO',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  color: SentinelTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${provider.cleanRatio.toStringAsFixed(1)}%',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _cleanRatioColor(provider.cleanRatio),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Mic toggle button
          _MicToggleButton(
            isActive: isActive,
            onTap: () => provider.toggleMic(),
          ),
        ],
      ),
    );
  }

  Color _cleanRatioColor(double ratio) {
    if (ratio >= 90) return SentinelTheme.alertGreen;
    if (ratio >= 70) return SentinelTheme.cyberBlue;
    if (ratio >= 50) return SentinelTheme.alertAmber;
    return SentinelTheme.alertRed;
  }
}

// ─── Mic Toggle Button ───────────────────────────────────────

class _MicToggleButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _MicToggleButton({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? SentinelTheme.alertGreen : SentinelTheme.cyberBlue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.stop_circle : Icons.play_circle,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              isActive ? 'STOP' : 'START',
              style: SentinelTheme.mono.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Alert Feed ──────────────────────────────────────────────

class _AlertFeed extends StatelessWidget {
  final List<dynamic> alerts;

  const _AlertFeed({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: SentinelTheme.glassCard(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notification_important,
                color: SentinelTheme.alertRed,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'LANGUAGE ALERTS',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.alertRed,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: SentinelTheme.alertRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: SentinelTheme.alertRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${alerts.length} active',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    color: SentinelTheme.alertRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 28,
                      color: SentinelTheme.alertGreen,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No language violations detected',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 11,
                        color: SentinelTheme.alertGreen,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...alerts.take(10).map((alert) => VoiceAlertCard(alert: alert)),
        ],
      ),
    );
  }
}

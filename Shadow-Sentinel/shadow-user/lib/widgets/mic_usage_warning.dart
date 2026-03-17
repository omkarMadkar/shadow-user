import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voice_sentinel_provider.dart';
import '../theme/sentinel_theme.dart';

/// Warning banner displayed when external applications are detected
/// using the microphone at the OS level.
class MicUsageWarning extends StatefulWidget {
  const MicUsageWarning({super.key});

  @override
  State<MicUsageWarning> createState() => _MicUsageWarningState();
}

class _MicUsageWarningState extends State<MicUsageWarning>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceSentinelProvider>(
      builder: (context, provider, _) {
        final apps = provider.externalMicApps;
        if (apps.isEmpty) return const SizedBox.shrink();

        return AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) {
            final glowAlpha = 0.15 + _pulseCtrl.value * 0.15;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: SentinelTheme.alertRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: SentinelTheme.alertRed.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: SentinelTheme.alertRed.withValues(alpha: glowAlpha),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Row ──────────────────────────
                    Row(
                      children: [
                        // Pulsing alert icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SentinelTheme.alertRed.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: SentinelTheme.alertRed.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.warning_rounded,
                            color: SentinelTheme.alertRed,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MICROPHONE ACCESS DETECTED',
                                style: SentinelTheme.mono.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: SentinelTheme.alertRed,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${apps.length} application${apps.length > 1 ? 's' : ''} currently accessing your microphone',
                                style: SentinelTheme.sans.copyWith(
                                  fontSize: 11,
                                  color: SentinelTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Shield icon
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: provider.micActive
                                ? SentinelTheme.alertGreen.withValues(
                                    alpha: 0.15,
                                  )
                                : SentinelTheme.alertAmber.withValues(
                                    alpha: 0.15,
                                  ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            provider.micActive
                                ? Icons.shield
                                : Icons.shield_outlined,
                            color: provider.micActive
                                ? SentinelTheme.alertGreen
                                : SentinelTheme.alertAmber,
                            size: 18,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── App List ────────────────────────────
                    ...apps.map((app) => _AppUsageRow(app: app)),

                    const SizedBox(height: 10),

                    // ── Status Bar ──────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: provider.micActive
                            ? SentinelTheme.alertGreen.withValues(alpha: 0.08)
                            : SentinelTheme.alertAmber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: provider.micActive
                              ? SentinelTheme.alertGreen.withValues(alpha: 0.25)
                              : SentinelTheme.alertAmber.withValues(
                                  alpha: 0.25,
                                ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            provider.micActive
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 12,
                            color: provider.micActive
                                ? SentinelTheme.alertGreen
                                : SentinelTheme.alertAmber,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            provider.micActive
                                ? 'Voice Sentinel ACTIVE — Recording & analyzing all audio'
                                : 'Voice Sentinel STANDBY — Tap START to begin protection',
                            style: SentinelTheme.mono.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: provider.micActive
                                  ? SentinelTheme.alertGreen
                                  : SentinelTheme.alertAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── App Usage Row ───────────────────────────────────────────

class _AppUsageRow extends StatelessWidget {
  final dynamic app;

  const _AppUsageRow({required this.app});

  @override
  Widget build(BuildContext context) {
    final name = app.appName as String;
    final detectedAt = app.detectedAt as DateTime;
    final timeStr =
        '${detectedAt.hour.toString().padLeft(2, '0')}:${detectedAt.minute.toString().padLeft(2, '0')}:${detectedAt.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: SentinelTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: SentinelTheme.alertRed.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.apps, size: 16, color: SentinelTheme.alertRed),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: SentinelTheme.textPrimary,
                  ),
                ),
                Text(
                  'Detected at $timeStr',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    color: SentinelTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: SentinelTheme.alertRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'USING MIC',
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
    );
  }
}

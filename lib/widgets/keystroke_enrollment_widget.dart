import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/keystroke_provider.dart';
import '../theme/sentinel_theme.dart';

/// Typing sample capture panel for baseline enrollment.
class KeystrokeEnrollmentWidget extends StatelessWidget {
  const KeystrokeEnrollmentWidget({super.key});

  static const String _sampleText =
      'The quick brown fox jumps over the lazy dog. '
      'Pack my box with five dozen liquor jugs. '
      'How vexingly quick daft zebras jump.';

  @override
  Widget build(BuildContext context) {
    return Consumer<KeystrokeProvider>(
      builder: (_, p, __) {
        return Container(
          decoration: SentinelTheme.glassCard(
            glowColor: p.isEnrolled
                ? SentinelTheme.alertGreen
                : SentinelTheme.cyberBlue,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    p.isEnrolled ? Icons.verified : Icons.fingerprint,
                    size: 16,
                    color: p.isEnrolled
                        ? SentinelTheme.alertGreen
                        : SentinelTheme.cyberBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    p.isEnrolled ? 'PROFILE ENROLLED' : 'ENROLLMENT',
                    style: SentinelTheme.sans.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: SentinelTheme.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  if (p.isEnrolled)
                    _ActionButton(
                      label: 'RE-ENROLL',
                      icon: Icons.refresh,
                      color: SentinelTheme.alertAmber,
                      onTap: () => p.resetBaseline(),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (p.isEnrolled) ...[
                // Enrolled info
                _BaselineInfo(baseline: p.baseline!),
              ] else if (p.mode == KeystrokeMode.enrolling) ...[
                // Active enrollment
                Text(
                  'Type the text below naturally:',
                  style: SentinelTheme.sans.copyWith(
                    fontSize: 11,
                    color: SentinelTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SentinelTheme.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SentinelTheme.cyberBlue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    _sampleText,
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 12,
                      color: SentinelTheme.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: p.enrollmentPercent,
                          minHeight: 8,
                          backgroundColor: SentinelTheme.border,
                          valueColor: AlwaysStoppedAnimation(
                            SentinelTheme.cyberBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${p.enrollmentProgress}/${KeystrokeProvider.enrollmentTarget}',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 11,
                        color: SentinelTheme.cyberBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Idle — prompt to start
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.keyboard_alt_outlined,
                        size: 32,
                        color: SentinelTheme.textMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Capture your typing signature',
                        style: SentinelTheme.sans.copyWith(
                          fontSize: 12,
                          color: SentinelTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionButton(
                        label: 'START ENROLLMENT',
                        icon: Icons.play_arrow,
                        color: SentinelTheme.cyberBlue,
                        onTap: () => p.startEnrollment(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BaselineInfo extends StatelessWidget {
  final dynamic baseline; // KeystrokeBaseline
  const _BaselineInfo({required this.baseline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SentinelTheme.alertGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SentinelTheme.alertGreen.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          _InfoItem('Dwell', '${(baseline.meanDwellMs as double).round()}ms'),
          _InfoItem('Flight', '${(baseline.meanFlightMs as double).round()}ms'),
          _InfoItem('WPM', '${(baseline.meanWpm as double).round()}'),
          _InfoItem('Samples', '${baseline.totalSamples}'),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: SentinelTheme.sans.copyWith(
              fontSize: 9,
              color: SentinelTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: SentinelTheme.mono.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: SentinelTheme.alertGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(6),
            color: color.withValues(alpha: 0.1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: SentinelTheme.mono.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

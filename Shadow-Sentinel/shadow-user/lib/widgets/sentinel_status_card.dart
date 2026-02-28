import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sentinel_provider.dart';
import '../models/models.dart';
import '../theme/sentinel_theme.dart';

/// Sentinel module status cards — Keystroke Monitor + Neural Image Detection.
class SentinelStatusCard extends StatelessWidget {
  const SentinelStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: SentinelTheme.glassCard(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: SentinelTheme.cyberBlue),
              const SizedBox(width: 8),
              Text(
                'SENTINEL MODULES',
                style: SentinelTheme.sans.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SentinelTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Keystroke Module
          Consumer<SentinelProvider>(
            builder: (_, p, __) => _ModuleCard(
              icon: Icons.keyboard_alt_outlined,
              label: 'Keystroke Monitor',
              state: p.keystrokeState,
              color: SentinelTheme.cyberBlue,
              metrics: [
                _Metric('Cadence', '${p.keystrokeMetrics.cadenceWpm.round()} WPM'),
                _Metric('Pattern', 'Nominal'),
                _Metric('Drift', '${(p.keystrokeMetrics.patternDrift * 100).toStringAsFixed(1)}%'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Camera Module
          Consumer<SentinelProvider>(
            builder: (_, p, __) => _ModuleCard(
              icon: Icons.visibility_outlined,
              label: 'Neural Image Detection',
              state: p.cameraState,
              color: SentinelTheme.cyberCyan,
              metrics: [
                _Metric('Next Scan', '${p.cameraCountdown}s'),
                _Metric('Last Match', p.lastCapture),
                _Metric('Confidence', '${p.cameraConfidence.toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric {
  final String label;
  final String value;
  const _Metric(this.label, this.value);
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final SentinelModuleState state;
  final Color color;
  final List<_Metric> metrics;

  const _ModuleCard({
    required this.icon,
    required this.label,
    required this.state,
    required this.color,
    required this.metrics,
  });

  String get _statusLabel {
    switch (state) {
      case SentinelModuleState.active:
        return 'ACTIVE';
      case SentinelModuleState.capturing:
        return 'SCANNING';
      case SentinelModuleState.paused:
        return 'PAUSED';
      case SentinelModuleState.error:
        return 'ERROR';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SentinelTheme.bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: SentinelTheme.sans.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: SentinelTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _PulsingDot(color: color, isPinging: state == SentinelModuleState.capturing),
                  const SizedBox(width: 6),
                  Text(
                    _statusLabel,
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Metrics row
          Row(
            children: metrics.map((m) {
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      m.label.toUpperCase(),
                      style: SentinelTheme.sans.copyWith(
                        fontSize: 9,
                        color: SentinelTheme.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      m.value,
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: SentinelTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// A small dot that pulses or pings depending on state.
class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool isPinging;

  const _PulsingDot({required this.color, required this.isPinging});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final opacity = widget.isPinging
            ? (0.3 + 0.7 * (1 - _controller.value))
            : (0.5 + 0.5 * (0.5 + 0.5 * (1 - (2 * _controller.value - 1).abs())));
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: opacity),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: opacity * 0.4),
                blurRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }
}

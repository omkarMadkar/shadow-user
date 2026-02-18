import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sentinel_provider.dart';
import '../theme/sentinel_theme.dart';
import '../widgets/face_scan_widget.dart';
import '../widgets/camera_log_widget.dart';

/// Neural camera detection dashboard screen.
class NeuralCameraScreen extends StatelessWidget {
  const NeuralCameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SentinelProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Neural Camera Header ────────────────────
              _NeuralCameraHeader(provider: provider),

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
    return Column(
      children: [
        // Top row: Face scan + Stats
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Face scan widget
              SizedBox(
                width: 420,
                child: FaceScanWidget(
                  confidence: provider.currentFrame.confidence,
                  livenessScore: provider.currentFrame.livenessScore,
                  matched: provider.currentFrame.matched,
                  spoofingAttempt: provider.currentFrame.spoofingAttempt,
                  scanMode: provider.currentFrame.scanMode,
                  isActive: provider.neuralScanActive,
                ),
              ),
              const SizedBox(width: 16),
              // Stats panel
              Expanded(
                child: _NeuralStatsPanel(provider: provider),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Camera log
        SizedBox(
          height: 400,
          child: CameraLogWidget(logs: provider.cameraLogs),
        ),
      ],
    );
  }

  Widget _narrowLayout(SentinelProvider provider) {
    return Column(
      children: [
        FaceScanWidget(
          confidence: provider.currentFrame.confidence,
          livenessScore: provider.currentFrame.livenessScore,
          matched: provider.currentFrame.matched,
          spoofingAttempt: provider.currentFrame.spoofingAttempt,
          scanMode: provider.currentFrame.scanMode,
          isActive: provider.neuralScanActive,
        ),
        const SizedBox(height: 16),
        _NeuralStatsPanel(provider: provider),
        const SizedBox(height: 16),
        SizedBox(
          height: 400,
          child: CameraLogWidget(logs: provider.cameraLogs),
        ),
      ],
    );
  }
}

// ─── Neural Camera Header ─────────────────────────────────────

class _NeuralCameraHeader extends StatelessWidget {
  final SentinelProvider provider;

  const _NeuralCameraHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SentinelTheme.glassCard(glowColor: SentinelTheme.cyberCyan),
      child: Row(
        children: [
          // Camera icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  SentinelTheme.cyberCyan.withValues(alpha: 0.15),
                  SentinelTheme.cyberBlue.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SentinelTheme.cyberCyan.withValues(alpha: 0.2)),
            ),
            child: Icon(Icons.videocam, color: SentinelTheme.cyberCyan, size: 24),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEURAL CAMERA SYSTEM',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    color: SentinelTheme.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Continuous Identity Verification',
                  style: SentinelTheme.sans.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: SentinelTheme.cyberCyan,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Deep Learning Face Recognition • Anti-Spoofing • Liveness Detection',
                  style: SentinelTheme.sans.copyWith(
                    fontSize: 10,
                    color: SentinelTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Avg confidence
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'AVG CONFIDENCE',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 8,
                  color: SentinelTheme.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${provider.avgConfidence.toStringAsFixed(1)}%',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: provider.avgConfidence > 90
                      ? SentinelTheme.alertGreen
                      : provider.avgConfidence > 70
                          ? SentinelTheme.alertAmber
                          : SentinelTheme.alertRed,
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Toggle
          GestureDetector(
            onTap: provider.toggleNeuralScan,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: provider.neuralScanActive
                    ? SentinelTheme.alertGreen.withValues(alpha: 0.1)
                    : SentinelTheme.alertRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: provider.neuralScanActive
                      ? SentinelTheme.alertGreen.withValues(alpha: 0.3)
                      : SentinelTheme.alertRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    provider.neuralScanActive ? Icons.visibility : Icons.visibility_off,
                    size: 14,
                    color: provider.neuralScanActive
                        ? SentinelTheme.alertGreen
                        : SentinelTheme.alertRed,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    provider.neuralScanActive ? 'ACTIVE' : 'PAUSED',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: provider.neuralScanActive
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

// ─── Neural Stats Panel ───────────────────────────────────────

class _NeuralStatsPanel extends StatelessWidget {
  final SentinelProvider provider;

  const _NeuralStatsPanel({required this.provider});

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
              Icon(Icons.insights, size: 16, color: SentinelTheme.cyberBlue),
              const SizedBox(width: 8),
              Text(
                'SESSION ANALYTICS',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.cyberBlue,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats grid
          Row(
            children: [
              _StatTile(
                label: 'FRAMES ANALYZED',
                value: '${provider.totalFramesAnalyzed}',
                icon: Icons.burst_mode,
                color: SentinelTheme.cyberBlue,
              ),
              const SizedBox(width: 8),
              _StatTile(
                label: 'SPOOFING ALERTS',
                value: '${provider.spoofingAttempts}',
                icon: Icons.report_problem,
                color: SentinelTheme.alertRed,
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              _StatTile(
                label: 'AVG CONFIDENCE',
                value: '${provider.avgConfidence.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: SentinelTheme.alertGreen,
              ),
              const SizedBox(width: 8),
              _StatTile(
                label: 'CURRENT LIVENESS',
                value: '${provider.currentFrame.livenessScore.toStringAsFixed(1)}%',
                icon: Icons.favorite,
                color: SentinelTheme.cyberCyan,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Detection modes
          Text(
            'DETECTION CAPABILITIES',
            style: SentinelTheme.mono.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: SentinelTheme.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),

          _CapabilityRow('Face Geometry Matching', true, SentinelTheme.alertGreen),
          _CapabilityRow('Liveness Detection', true, SentinelTheme.alertGreen),
          _CapabilityRow('Anti-Spoofing (Photo/Mask)', true, SentinelTheme.alertGreen),
          _CapabilityRow('Infrared Depth Mapping', true, SentinelTheme.cyberBlue),
          _CapabilityRow('Micro-Expression Analysis', true, SentinelTheme.cyberCyan),
          _CapabilityRow('Multi-Face Detection', true, SentinelTheme.alertAmber),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 8,
                      color: SentinelTheme.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;

  const _CapabilityRow(this.label, this.active, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(
              active ? Icons.check : Icons.close,
              size: 10,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: SentinelTheme.sans.copyWith(
              fontSize: 11,
              color: SentinelTheme.textSecondary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              active ? 'ONLINE' : 'OFFLINE',
              style: SentinelTheme.mono.copyWith(
                fontSize: 7,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

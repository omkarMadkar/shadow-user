import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/sentinel_provider.dart';
import '../theme/sentinel_theme.dart';
import '../widgets/face_scan_widget.dart';
import '../widgets/camera_log_widget.dart';
import '../widgets/live_camera_widget.dart';

/// Neural camera detection dashboard screen.
class NeuralCameraScreen extends StatefulWidget {
  const NeuralCameraScreen({super.key});

  @override
  State<NeuralCameraScreen> createState() => _NeuralCameraScreenState();
}

class _NeuralCameraScreenState extends State<NeuralCameraScreen> {
  bool _useLiveCamera = false;

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
              _NeuralCameraHeader(
                provider: provider,
                useLiveCamera: _useLiveCamera,
                onToggleLiveCamera: () {
                  setState(() => _useLiveCamera = !_useLiveCamera);
                },
              ),

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
        // Top row: Face scan + Face preview + Stats
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Face scan widget or Live camera
              SizedBox(
                width: 420,
                child: _useLiveCamera
                    ? LiveCameraWidget(isActive: provider.neuralScanActive)
                    : FaceScanWidget(
                        confidence: provider.currentFrame.confidence,
                        livenessScore: provider.currentFrame.livenessScore,
                        matched: provider.currentFrame.matched,
                        spoofingAttempt: provider.currentFrame.spoofingAttempt,
                        scanMode: provider.currentFrame.scanMode,
                        isActive: provider.neuralScanActive,
                      ),
              ),
              const SizedBox(width: 16),
              // Face image preview card
              SizedBox(width: 260, child: _FacePreviewCard(provider: provider)),
              const SizedBox(width: 16),
              // Stats panel
              Expanded(child: _NeuralStatsPanel(provider: provider)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Camera log
        SizedBox(
          height: 400,
          child: CameraLogWidget(logs: provider.cameraLogs),
        ),
        // Keystroke-triggered captures
        if (provider.keystrokeTriggers.isNotEmpty) ...[
          const SizedBox(height: 16),
          _KeystrokeTriggerPanel(triggers: provider.keystrokeTriggers),
        ],
      ],
    );
  }

  Widget _narrowLayout(SentinelProvider provider) {
    return Column(
      children: [
        _useLiveCamera
            ? LiveCameraWidget(isActive: provider.neuralScanActive)
            : FaceScanWidget(
                confidence: provider.currentFrame.confidence,
                livenessScore: provider.currentFrame.livenessScore,
                matched: provider.currentFrame.matched,
                spoofingAttempt: provider.currentFrame.spoofingAttempt,
                scanMode: provider.currentFrame.scanMode,
                isActive: provider.neuralScanActive,
              ),
        const SizedBox(height: 16),
        _FacePreviewCard(provider: provider),
        const SizedBox(height: 16),
        _NeuralStatsPanel(provider: provider),
        const SizedBox(height: 16),
        if (provider.keystrokeTriggers.isNotEmpty) ...[
          _KeystrokeTriggerPanel(triggers: provider.keystrokeTriggers),
          const SizedBox(height: 16),
        ],
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
  final bool useLiveCamera;
  final VoidCallback onToggleLiveCamera;

  const _NeuralCameraHeader({
    required this.provider,
    required this.useLiveCamera,
    required this.onToggleLiveCamera,
  });

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
              border: Border.all(
                color: SentinelTheme.cyberCyan.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              Icons.videocam,
              color: SentinelTheme.cyberCyan,
              size: 24,
            ),
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

          // Verify Now button — re-captures reference face, then verifies
          GestureDetector(
            onTap: provider.isVerifying
                ? null
                : () => provider.runSingleVerification(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: provider.isVerifying
                    ? SentinelTheme.cyberCyan.withValues(alpha: 0.05)
                    : SentinelTheme.cyberCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: SentinelTheme.cyberCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.isVerifying)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: SentinelTheme.cyberCyan,
                      ),
                    )
                  else
                    Icon(
                      Icons.center_focus_strong,
                      size: 14,
                      color: SentinelTheme.cyberCyan,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    provider.isVerifying ? 'VERIFYING…' : 'VERIFY NOW',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: SentinelTheme.cyberCyan,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Live camera toggle
          GestureDetector(
            onTap: onToggleLiveCamera,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: useLiveCamera
                    ? SentinelTheme.cyberCyan.withValues(alpha: 0.1)
                    : SentinelTheme.textMuted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: useLiveCamera
                      ? SentinelTheme.cyberCyan.withValues(alpha: 0.3)
                      : SentinelTheme.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    useLiveCamera ? Icons.videocam : Icons.videocam_off,
                    size: 14,
                    color: useLiveCamera
                        ? SentinelTheme.cyberCyan
                        : SentinelTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    useLiveCamera ? 'LIVE' : 'SIM',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: useLiveCamera
                          ? SentinelTheme.cyberCyan
                          : SentinelTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Active/Paused toggle
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
                    provider.neuralScanActive
                        ? Icons.visibility
                        : Icons.visibility_off,
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
                value:
                    '${provider.currentFrame.livenessScore.toStringAsFixed(1)}%',
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

          _CapabilityRow(
            'Face Geometry Matching',
            true,
            SentinelTheme.alertGreen,
          ),
          _CapabilityRow('Liveness Detection', true, SentinelTheme.alertGreen),
          _CapabilityRow(
            'Anti-Spoofing (Photo/Mask)',
            true,
            SentinelTheme.alertGreen,
          ),
          _CapabilityRow(
            'Infrared Depth Mapping',
            true,
            SentinelTheme.cyberBlue,
          ),
          _CapabilityRow(
            'Micro-Expression Analysis',
            true,
            SentinelTheme.cyberCyan,
          ),
          _CapabilityRow(
            'Multi-Face Detection',
            true,
            SentinelTheme.alertAmber,
          ),
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

// ─── Face Preview Card ────────────────────────────────────────

class _FacePreviewCard extends StatelessWidget {
  final SentinelProvider provider;

  const _FacePreviewCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: SentinelTheme.glassCard(
        glowColor: provider.hasReferenceFace
            ? SentinelTheme.alertGreen
            : SentinelTheme.alertAmber,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.face, size: 16, color: SentinelTheme.cyberCyan),
              const SizedBox(width: 8),
              Text(
                'IDENTITY SNAPSHOTS',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.cyberCyan,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Reference face
          Text(
            'ENROLLED FACE',
            style: SentinelTheme.mono.copyWith(
              fontSize: 8,
              color: SentinelTheme.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          _buildImageTile(
            imagePath: provider.referenceFacePath,
            placeholder: 'No reference enrolled',
            borderColor: SentinelTheme.alertGreen,
          ),
          const SizedBox(height: 12),

          // Last verification capture
          Text(
            'LAST VERIFICATION',
            style: SentinelTheme.mono.copyWith(
              fontSize: 8,
              color: SentinelTheme.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          _buildImageTile(
            imagePath: provider.lastVerificationImagePath,
            placeholder: 'No verification yet',
            borderColor: SentinelTheme.cyberBlue,
          ),

          const SizedBox(height: 14),

          // Status line
          if (!provider.hasReferenceFace)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SentinelTheme.alertAmber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: SentinelTheme.alertAmber.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: SentinelTheme.alertAmber,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'No reference face enrolled. Capture a face during login to enable verification.',
                      style: SentinelTheme.sans.copyWith(
                        fontSize: 9,
                        color: SentinelTheme.alertAmber,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: SentinelTheme.alertGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: SentinelTheme.alertGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    size: 14,
                    color: SentinelTheme.alertGreen,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      provider.neuralScanActive
                          ? 'Real-time verification active'
                          : 'Reference enrolled • Paused',
                      style: SentinelTheme.sans.copyWith(
                        fontSize: 9,
                        color: SentinelTheme.alertGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageTile({
    required String? imagePath,
    required String placeholder,
    required Color borderColor,
  }) {
    final file = imagePath != null ? File(imagePath) : null;
    final exists = file != null && file.existsSync();

    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: SentinelTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: exists
          ? Image.file(
              file,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              // Bypass Flutter image cache so re-captured reference shows immediately
              key: ValueKey(
                '$imagePath-${file.lastModifiedSync().millisecondsSinceEpoch}',
              ),
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.no_photography,
                    size: 22,
                    color: SentinelTheme.textMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    placeholder,
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 8,
                      color: SentinelTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─── Keystroke Trigger Panel ──────────────────────────────────

/// Shows recent camera captures triggered by keystroke bad-word detection.
class _KeystrokeTriggerPanel extends StatelessWidget {
  final List<KeystrokeCameraTrigger> triggers;

  const _KeystrokeTriggerPanel({required this.triggers});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: SentinelTheme.glassCard(glowColor: SentinelTheme.alertRed),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: SentinelTheme.alertRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SentinelTheme.alertRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.keyboard_alt_outlined,
                    size: 14,
                    color: SentinelTheme.alertRed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KEYSTROKE-TRIGGERED CAPTURES',
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: SentinelTheme.alertRed,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Camera auto-captured when bad words detected in typing',
                        style: SentinelTheme.sans.copyWith(
                          fontSize: 10,
                          color: SentinelTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: SentinelTheme.alertRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: SentinelTheme.alertRed.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${triggers.length} CAPTURES',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: SentinelTheme.alertRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Trigger list
          ...triggers.take(5).map((t) => _buildTriggerCard(t)),
        ],
      ),
    );
  }

  Widget _buildTriggerCard(KeystrokeCameraTrigger trigger) {
    final ts = trigger.timestamp;
    final time =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}';

    final Color verifyColor;
    final String verifyLabel;
    final IconData verifyIcon;
    if (trigger.faceVerified == true) {
      verifyColor = SentinelTheme.alertGreen;
      verifyLabel = 'SAME PERSON';
      verifyIcon = Icons.verified_user;
    } else if (trigger.faceVerified == false) {
      verifyColor = SentinelTheme.alertRed;
      verifyLabel = 'MISMATCH';
      verifyIcon = Icons.gpp_bad_outlined;
    } else {
      verifyColor = SentinelTheme.textMuted;
      verifyLabel = 'NO CAMERA';
      verifyIcon = Icons.videocam_off;
    }

    final alertColor = trigger.alertType == 'backspaceCoverUp'
        ? SentinelTheme.alertRed
        : trigger.alertType == 'sentThreatening'
            ? const Color(0xFFFF6B6B)
            : SentinelTheme.alertAmber;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SentinelTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: alertColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Alert type + time + face result
          Row(
            children: [
              _triggerBadge(
                trigger.alertType == 'backspaceCoverUp'
                    ? 'COVER-UP'
                    : trigger.alertType == 'sentThreatening'
                        ? 'SENT'
                        : 'LIVE',
                alertColor,
              ),
              const SizedBox(width: 6),
              Icon(verifyIcon, size: 12, color: verifyColor),
              const SizedBox(width: 4),
              Text(
                verifyLabel,
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: verifyColor,
                ),
              ),
              if (trigger.faceConfidence > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '${trigger.faceConfidence.toStringAsFixed(1)}%',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    color: SentinelTheme.textMuted,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                time,
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  color: SentinelTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Flagged words
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children: trigger.flaggedWords
                .take(5)
                .map(
                  (w) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: SentinelTheme.alertRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: SentinelTheme.alertRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '"$w"',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 9,
                        color: SentinelTheme.alertRed,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          // Row 3: Evidence thumbnails
          if (trigger.screenshotPath != null ||
              trigger.facePhotoPath != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (trigger.screenshotPath != null)
                  _evidenceThumb(trigger.screenshotPath!, 'SCREEN'),
                if (trigger.screenshotPath != null &&
                    trigger.facePhotoPath != null)
                  const SizedBox(width: 8),
                if (trigger.facePhotoPath != null)
                  _evidenceThumb(trigger.facePhotoPath!, 'FACE'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _triggerBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

  Widget _evidenceThumb(String path, String label) {
    final file = File(path);
    final exists = file.existsSync();
    return Column(
      children: [
        Container(
          width: 60,
          height: 45,
          decoration: BoxDecoration(
            color: SentinelTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: SentinelTheme.border.withValues(alpha: 0.3),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: exists
              ? Image.file(file, fit: BoxFit.cover)
              : Icon(
                  Icons.image_not_supported,
                  size: 16,
                  color: SentinelTheme.textMuted,
                ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: SentinelTheme.mono.copyWith(
            fontSize: 7,
            color: SentinelTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

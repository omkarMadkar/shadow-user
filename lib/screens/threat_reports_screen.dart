import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/voice_sentinel_provider.dart';
import '../theme/sentinel_theme.dart';

/// Displays all threat reports generated when Voice Sentinel
/// flags bad words / aggression. Each report bundles the
/// screenshot, face photo, audio chunk, and transcript.
class ThreatReportsScreen extends StatelessWidget {
  const ThreatReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VoiceSentinelProvider>();
    final reports = provider.threatReports;

    return Scaffold(
      backgroundColor: SentinelTheme.bg,
      body: Column(
        children: [
          _Header(reportCount: reports.length),
          Expanded(
            child: reports.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      return _ReportCard(
                        report: reports[index],
                        provider: provider,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int reportCount;
  const _Header({required this.reportCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: SentinelTheme.surface,
        border: Border(bottom: BorderSide(color: SentinelTheme.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: SentinelTheme.alertRed, size: 20),
          const SizedBox(width: 10),
          Text(
            'THREAT REPORTS',
            style: SentinelTheme.mono.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SentinelTheme.textPrimary,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          if (reportCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SentinelTheme.alertRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: SentinelTheme.alertRed.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '$reportCount REPORTS',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.alertRed,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 56,
            color: SentinelTheme.alertGreen,
          ),
          const SizedBox(height: 16),
          Text(
            'NO THREATS DETECTED',
            style: SentinelTheme.mono.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SentinelTheme.textPrimary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Voice Sentinel is monitoring.\nReports appear here when bad words or aggression are detected.',
            textAlign: TextAlign.center,
            style: SentinelTheme.sans.copyWith(
              fontSize: 12,
              color: SentinelTheme.textMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Report Card ──────────────────────────────────────────────

class _ReportCard extends StatefulWidget {
  final ThreatReport report;
  final VoiceSentinelProvider provider;

  const _ReportCard({required this.report, required this.provider});

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  bool _expanded = false;

  Color get _severityColor {
    switch (widget.report.severity) {
      case VoiceSeverity.severe:
        return SentinelTheme.alertRed;
      case VoiceSeverity.moderate:
        return const Color(0xFFFF8C00);
      case VoiceSeverity.mild:
        return const Color(0xFFFFD700);
      case VoiceSeverity.clean:
        return SentinelTheme.alertGreen;
    }
  }

  Color get _alertColor {
    switch (widget.report.alertType) {
      case 'threat':
        return SentinelTheme.alertRed;
      case 'harassment':
        return const Color(0xFFFF4500);
      case 'profanity':
        return const Color(0xFFFF6B35);
      case 'hostility':
        return const Color(0xFFFF8C00);
      case 'negative':
        return const Color(0xFFFFD700);
      default:
        return SentinelTheme.cyberBlue;
    }
  }

  IconData get _alertIcon {
    switch (widget.report.alertType) {
      case 'threat':
        return Icons.warning_amber_rounded;
      case 'harassment':
        return Icons.block;
      case 'profanity':
        return Icons.volume_off;
      case 'hostility':
        return Icons.local_fire_department;
      case 'negative':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.flag;
    }
  }

  String get _formattedTime {
    final t = widget.report.timestamp;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    final d =
        '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';
    return '$d  $h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final isPlayingThis =
        widget.provider.playingChunkPath == report.audioChunkPath &&
        widget.provider.isPlaying;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SentinelTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _alertColor.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Severity stripe
              Container(width: 4, color: _severityColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top row: badge + timestamp + audio ──
                      Row(
                        children: [
                          _AlertBadge(
                            icon: _alertIcon,
                            label: report.alertType.toUpperCase(),
                            color: _alertColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formattedTime,
                            style: SentinelTheme.mono.copyWith(
                              fontSize: 10,
                              color: SentinelTheme.textMuted,
                            ),
                          ),
                          const Spacer(),
                          // Audio play button
                          GestureDetector(
                            onTap: () {
                              if (isPlayingThis) {
                                widget.provider.stopPlayback();
                              } else {
                                widget.provider.playChunk(
                                  report.audioChunkPath,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: SentinelTheme.cyberBlue.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: SentinelTheme.cyberBlue.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Icon(
                                isPlayingThis
                                    ? Icons.stop_circle_outlined
                                    : Icons.play_circle_outline,
                                size: 16,
                                color: SentinelTheme.cyberBlue,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ── Flagged words chips ──
                      if (report.flaggedWords.isNotEmpty) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: report.flaggedWords
                              .take(6)
                              .map((w) => _FlagChip(word: w))
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // ── Evidence thumbnails ──
                      _EvidenceRow(report: report),
                      const SizedBox(height: 10),

                      // ── Transcript (expandable) ──
                      GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.mic_none,
                                  size: 12,
                                  color: SentinelTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'TRANSCRIPT',
                                  style: SentinelTheme.mono.copyWith(
                                    fontSize: 9,
                                    color: SentinelTheme.textMuted,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  _expanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 14,
                                  color: SentinelTheme.textMuted,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 200),
                              firstChild: Text(
                                report.transcript.isNotEmpty
                                    ? report.transcript
                                    : '(No transcript available)',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: SentinelTheme.sans.copyWith(
                                  fontSize: 11,
                                  color: SentinelTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              secondChild: Text(
                                report.transcript.isNotEmpty
                                    ? report.transcript
                                    : '(No transcript available)',
                                style: SentinelTheme.sans.copyWith(
                                  fontSize: 11,
                                  color: SentinelTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              crossFadeState: _expanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Evidence Row ─────────────────────────────────────────────

class _EvidenceRow extends StatelessWidget {
  final ThreatReport report;
  const _EvidenceRow({required this.report});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _EvidenceThumb(
          path: report.screenshotPath,
          label: 'SCREEN',
          icon: Icons.screenshot_monitor,
          color: SentinelTheme.cyberBlue,
        ),
        const SizedBox(width: 8),
        _EvidenceThumb(
          path: report.facePhotoPath,
          label: 'FACE',
          icon: Icons.face_retouching_natural,
          color: SentinelTheme.cyberCyan,
        ),
      ],
    );
  }
}

class _EvidenceThumb extends StatelessWidget {
  final String? path;
  final String label;
  final IconData icon;
  final Color color;

  const _EvidenceThumb({
    required this.path,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasFile = path != null && File(path!).existsSync();

    return GestureDetector(
      onTap: hasFile ? () => _showFullscreen(context, path!) : null,
      child: Container(
        width: 90,
        height: 60,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: hasFile
                ? color.withValues(alpha: 0.4)
                : SentinelTheme.border,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: hasFile
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(path!), fit: BoxFit.cover),
                    // Label overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: SentinelTheme.mono.copyWith(
                            fontSize: 7,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    // Tap hint
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.open_in_full,
                        size: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: SentinelTheme.textMuted),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 7,
                        color: SentinelTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      path != null ? 'FILE MISSING' : 'UNAVAILABLE',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 6,
                        color: SentinelTheme.textMuted.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showFullscreen(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alert Badge ──────────────────────────────────────────────

class _AlertBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _AlertBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: SentinelTheme.mono.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flagged Word Chip ────────────────────────────────────────

class _FlagChip extends StatelessWidget {
  final String word;
  const _FlagChip({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: SentinelTheme.alertRed.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SentinelTheme.alertRed.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '"$word"',
        style: SentinelTheme.mono.copyWith(
          fontSize: 9,
          color: SentinelTheme.alertRed,
        ),
      ),
    );
  }
}

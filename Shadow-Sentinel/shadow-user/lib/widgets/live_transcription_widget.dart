import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/voice_sentinel_provider.dart';
import '../theme/sentinel_theme.dart';

/// Live Translation widget — shows summarised translations of captured speech
/// in grouped time-windowed cards with topic, tone, key points, and alerts.
class LiveTranscriptionWidget extends StatelessWidget {
  const LiveTranscriptionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceSentinelProvider>(
      builder: (context, provider, _) {
        final summaries = provider.translationSummaries;
        final liveBuffer = provider.liveTranscriptBuffer;
        final isTranscribing = provider.isTranscribing;

        return Container(
          decoration: SentinelTheme.glassCard(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.translate,
                    color: SentinelTheme.cyberCyan,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE TRANSLATION',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: SentinelTheme.cyberCyan,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isTranscribing) _PulsingDot(),
                  const Spacer(),
                  // Summary count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: SentinelTheme.cyberCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: SentinelTheme.cyberCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${summaries.length} summaries',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 9,
                        color: SentinelTheme.cyberCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Clear button
                  if (summaries.isNotEmpty)
                    GestureDetector(
                      onTap: () => provider.clearTranscript(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: SentinelTheme.alertRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: SentinelTheme.alertRed.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          'CLEAR',
                          style: SentinelTheme.mono.copyWith(
                            fontSize: 9,
                            color: SentinelTheme.alertRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Live Buffer (current sentence being captured) ──
              if (liveBuffer.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: SentinelTheme.cyberCyan.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: SentinelTheme.cyberCyan.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.keyboard_voice,
                        size: 14,
                        color: SentinelTheme.cyberCyan,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: liveBuffer,
                                style: SentinelTheme.sans.copyWith(
                                  fontSize: 13,
                                  color: SentinelTheme.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                              WidgetSpan(child: _BlinkingCursor()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Summary Log ─────────────────────────────
              SizedBox(
                height: 320,
                child: summaries.isEmpty && liveBuffer.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.summarize_outlined,
                              size: 32,
                              color: SentinelTheme.textMuted,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              provider.micActive
                                  ? 'Capturing speech... summaries will appear shortly'
                                  : 'Start monitoring to see live translation summaries',
                              style: SentinelTheme.mono.copyWith(
                                fontSize: 11,
                                color: SentinelTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: summaries.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          return _SummaryCard(summary: summaries[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Summary Card ────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final TranslationSummary summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isFlagged = summary.hasFlaggedContent;
    final accentColor = isFlagged
        ? SentinelTheme.alertRed
        : SentinelTheme.cyberBlue;
    final toneColor = _toneColor(summary.tone);

    final startStr = _formatTime(summary.startTime);
    final endStr = _formatTime(summary.endTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isFlagged
            ? SentinelTheme.alertRed.withValues(alpha: 0.03)
            : SentinelTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Row: Topic + Tone + Time ──────────
            Row(
              children: [
                // Topic icon
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isFlagged ? Icons.warning_rounded : Icons.topic,
                    size: 14,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 8),
                // Topic title
                Expanded(
                  child: Text(
                    summary.topic.toUpperCase(),
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Tone badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: toneColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: toneColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    summary.tone.toUpperCase(),
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: toneColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Time range
                Text(
                  '$startStr\u2013$endStr',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    color: SentinelTheme.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Summary Text ─────────────────────────
            Text(
              summary.summary,
              style: SentinelTheme.sans.copyWith(
                fontSize: 12,
                color: SentinelTheme.textPrimary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 8),

            // ── Key Points ───────────────────────────
            Column(
              children: summary.keyPoints.map((point) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: SentinelTheme.cyberCyan.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: SentinelTheme.cyberCyan.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.arrow_right,
                          size: 12,
                          color: SentinelTheme.cyberCyan,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            point,
                            style: SentinelTheme.sans.copyWith(
                              fontSize: 10,
                              color: SentinelTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            // ── Flagged Words (if any) ───────────────
            if (isFlagged && summary.flaggedWords.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: SentinelTheme.alertRed.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: SentinelTheme.alertRed.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 12, color: SentinelTheme.alertRed),
                    const SizedBox(width: 6),
                    Text(
                      'Flagged: ',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: SentinelTheme.alertRed,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        summary.flaggedWords.join(', '),
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 9,
                          color: SentinelTheme.alertRed.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 6),

            // ── Footer: Segments + Confidence ────────
            Row(
              children: [
                Icon(
                  Icons.multitrack_audio,
                  size: 11,
                  color: SentinelTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${summary.segmentCount} segments captured',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    color: SentinelTheme.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(summary.avgConfidence * 100).toStringAsFixed(0)}% confidence',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    color: SentinelTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}';
  }

  Color _toneColor(String tone) {
    switch (tone.toLowerCase()) {
      case 'professional':
      case 'focused':
      case 'technical':
        return SentinelTheme.cyberBlue;
      case 'positive':
      case 'collaborative':
      case 'creative':
        return SentinelTheme.alertGreen;
      case 'casual':
      case 'relaxed':
      case 'transcribed':
      case 'neutral':
        return SentinelTheme.cyberCyan;
      case 'hostile':
      case 'threatening':
      case 'offensive':
      case 'aggressive':
        return SentinelTheme.alertRed;
      case 'stressed':
      case 'negative':
        return SentinelTheme.alertAmber;
      default:
        return SentinelTheme.alertAmber;
    }
  }
}

// ─── Pulsing Dot ─────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SentinelTheme.alertGreen.withValues(
              alpha: 0.4 + _ctrl.value * 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: SentinelTheme.alertGreen.withValues(
                  alpha: _ctrl.value * 0.4,
                ),
                blurRadius: 6,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Blinking Cursor ─────────────────────────────────────────

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Container(
          width: 2,
          height: 16,
          margin: const EdgeInsets.only(left: 2),
          color: SentinelTheme.cyberCyan.withValues(alpha: _ctrl.value),
        );
      },
    );
  }
}

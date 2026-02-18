import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/voice_sentinel_provider.dart';
import '../theme/sentinel_theme.dart';

/// Scrollable log of recent audio chunks with transcript and status.
class VoiceLogWidget extends StatelessWidget {
  const VoiceLogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceSentinelProvider>(
      builder: (context, provider, _) {
        final chunks = provider.recentChunks;

        return Container(
          decoration: SentinelTheme.glassCard(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.history, color: SentinelTheme.cyberBlue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'AUDIO CHUNK LOG',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: SentinelTheme.cyberBlue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${chunks.length} entries',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 9,
                      color: SentinelTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Chunk list
              Expanded(
                child: chunks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mic_off,
                              size: 32,
                              color: SentinelTheme.textMuted,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No audio chunks recorded yet',
                              style: SentinelTheme.mono.copyWith(
                                fontSize: 11,
                                color: SentinelTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: chunks.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, index) {
                          return _ChunkEntry(chunk: chunks[index]);
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

class _ChunkEntry extends StatelessWidget {
  final VoiceAudioChunk chunk;

  const _ChunkEntry({required this.chunk});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VoiceSentinelProvider>();
    final color = _severityColor(chunk.severity);
    final elapsed = DateTime.now().difference(chunk.timestamp);
    final timeAgo = _formatElapsed(elapsed);
    final isCurrentlyPlaying =
        provider.isPlaying && provider.playingChunkPath == chunk.filePath;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot
          Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: SentinelTheme.border),
            ],
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Severity badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        chunk.severity.name.toUpperCase(),
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${chunk.duration.inSeconds}s chunk',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 9,
                        color: SentinelTheme.textMuted,
                      ),
                    ),
                    const Spacer(),
                    // Play/Stop button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (isCurrentlyPlaying) {
                            provider.stopPlayback();
                          } else {
                            provider.playChunk(chunk.filePath);
                          }
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isCurrentlyPlaying
                                ? SentinelTheme.cyberBlue.withValues(alpha: 0.15)
                                : SentinelTheme.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isCurrentlyPlaying
                                  ? SentinelTheme.cyberBlue.withValues(alpha: 0.4)
                                  : SentinelTheme.border,
                            ),
                          ),
                          child: Icon(
                            isCurrentlyPlaying
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            size: 14,
                            color: isCurrentlyPlaying
                                ? SentinelTheme.cyberBlue
                                : SentinelTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeAgo,
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 9,
                        color: SentinelTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  chunk.transcript ?? 'Processing...',
                  style: SentinelTheme.sans.copyWith(
                    fontSize: 10,
                    color: chunk.severity == VoiceSeverity.clean
                        ? SentinelTheme.textSecondary
                        : color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (chunk.flaggedWords.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 4,
                    children: chunk.flaggedWords.map((w) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: SentinelTheme.alertRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          w,
                          style: SentinelTheme.mono.copyWith(
                            fontSize: 8,
                            color: SentinelTheme.alertRed,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(VoiceSeverity severity) {
    switch (severity) {
      case VoiceSeverity.severe:
        return SentinelTheme.alertRed;
      case VoiceSeverity.moderate:
        return SentinelTheme.alertAmber;
      case VoiceSeverity.mild:
        return const Color(0xFFF97316);
      case VoiceSeverity.clean:
        return SentinelTheme.alertGreen;
    }
  }

  String _formatElapsed(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }
}

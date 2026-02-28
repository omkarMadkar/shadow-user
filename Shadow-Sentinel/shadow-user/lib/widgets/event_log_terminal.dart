import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sentinel_provider.dart';
import '../models/models.dart';
import '../theme/sentinel_theme.dart';
import 'package:intl/intl.dart';

/// Terminal-style scrolling event log.
class EventLogTerminal extends StatelessWidget {
  const EventLogTerminal({super.key});

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SentinelTheme.alertGreen,
                      boxShadow: [
                        BoxShadow(
                          color: SentinelTheme.alertGreen.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE EVENT STREAM',
                    style: SentinelTheme.sans.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: SentinelTheme.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Consumer<SentinelProvider>(
                builder: (_, p, __) => Text(
                  '${p.events.length} events',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 10,
                    color: SentinelTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Log entries
          Expanded(
            child: Consumer<SentinelProvider>(
              builder: (_, provider, __) {
                return ListView.builder(
                  itemCount: provider.events.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final evt = provider.events[index];
                    return _LogEntry(event: evt);
                  },
                );
              },
            ),
          ),

          // Bottom scanline
          Container(
            height: 1,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  SentinelTheme.cyberBlue.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  final SecurityEvent event;

  const _LogEntry({required this.event});

  String get _badge {
    switch (event.severity) {
      case ThreatSeverity.critical:
        return 'CRIT';
      case ThreatSeverity.high:
        return 'WARN';
      case ThreatSeverity.low:
        return ' OK ';
      default:
        return 'INFO';
    }
  }

  Color get _color {
    switch (event.severity) {
      case ThreatSeverity.critical:
        return SentinelTheme.alertRed;
      case ThreatSeverity.high:
        return SentinelTheme.alertAmber;
      case ThreatSeverity.low:
        return SentinelTheme.alertGreen;
      default:
        return SentinelTheme.cyberCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = DateFormat('HH:mm:ss.SSS').format(event.timestamp);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          Text(
            ts,
            style: SentinelTheme.mono.copyWith(
              fontSize: 10,
              color: SentinelTheme.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _color.withValues(alpha: 0.25)),
            ),
            child: Text(
              _badge,
              style: SentinelTheme.mono.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Message
          Expanded(
            child: Text(
              event.message,
              style: SentinelTheme.mono.copyWith(
                fontSize: 11,
                color: _color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

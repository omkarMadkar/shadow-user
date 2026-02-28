import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/keystroke_provider.dart';
import '../theme/sentinel_theme.dart';

/// Terminal-style scrolling log for keystroke events.
class KeystrokeLogWidget extends StatelessWidget {
  const KeystrokeLogWidget({super.key});

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
              Icon(Icons.terminal, size: 16, color: SentinelTheme.cyberBlue),
              const SizedBox(width: 8),
              Text(
                'KEYSTROKE EVENT LOG',
                style: SentinelTheme.sans.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SentinelTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SentinelTheme.alertGreen,
                  boxShadow: [
                    BoxShadow(
                      color: SentinelTheme.alertGreen.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.alertGreen,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF050810),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SentinelTheme.border),
              ),
              child: Consumer<KeystrokeProvider>(
                builder: (_, p, __) {
                  if (p.logMessages.isEmpty) {
                    return Center(
                      child: Text(
                        '> Awaiting keystroke events…',
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 11,
                          color: SentinelTheme.textMuted,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: p.logMessages.length,
                    reverse: false,
                    itemBuilder: (_, i) {
                      final msg = p.logMessages[i];
                      Color lineColor = SentinelTheme.textMuted;
                      if (msg.contains('[ENROLL]')) {
                        lineColor = SentinelTheme.cyberBlue;
                      } else if (msg.contains('[MONITOR]')) {
                        lineColor = SentinelTheme.alertGreen;
                      } else if (msg.contains('[DEMO]')) {
                        lineColor = const Color(0xFF8B5CF6);
                      } else if (msg.contains('[RESET]')) {
                        lineColor = SentinelTheme.alertAmber;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          msg,
                          style: SentinelTheme.mono.copyWith(
                            fontSize: 10,
                            color: lineColor,
                            height: 1.4,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

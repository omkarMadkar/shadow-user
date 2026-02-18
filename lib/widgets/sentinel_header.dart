import 'package:flutter/material.dart';
import '../theme/sentinel_theme.dart';

/// Dashboard header bar — brand, clock, session timer, status pills, user avatar.
class SentinelHeader extends StatefulWidget {
  const SentinelHeader({super.key});

  @override
  State<SentinelHeader> createState() => _SentinelHeaderState();
}

class _SentinelHeaderState extends State<SentinelHeader> {
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SentinelTheme.surface.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(color: SentinelTheme.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Logo
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: SentinelTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SentinelTheme.cyberBlue.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: SentinelTheme.cyberBlue.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(Icons.shield, size: 18, color: SentinelTheme.cyberBlue),
          ),
          const SizedBox(width: 12),
          // Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'SHADOW',
                    style: SentinelTheme.sans.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: SentinelTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'SENTINEL',
                    style: SentinelTheme.sans.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: SentinelTheme.cyberBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                'CONTINUOUS AUTHENTICATION PLATFORM',
                style: SentinelTheme.sans.copyWith(
                  fontSize: 8,
                  color: SentinelTheme.textMuted,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Status pills
          _StatusPill('Network', 'Secure', SentinelTheme.alertGreen),
          const SizedBox(width: 8),
          _StatusPill('Encryption', 'AES-256', SentinelTheme.cyberCyan),
          const SizedBox(width: 8),
          _StatusPill('Protocol', 'Zero Trust', SentinelTheme.cyberBlue),

          const SizedBox(width: 20),

          // Clock & session
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (_, __) {
              final now = DateTime.now();
              final session = now.difference(_startTime);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 12,
                      color: SentinelTheme.textSecondary,
                    ),
                  ),
                  Text(
                    'Session: ${_formatDuration(session)}',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 10,
                      color: SentinelTheme.textMuted,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(width: 16),
          Container(width: 1, height: 30, color: SentinelTheme.border),
          const SizedBox(width: 16),

          // User avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: SentinelTheme.cyberBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SentinelTheme.cyberBlue.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                'PR',
                style: SentinelTheme.sans.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.cyberBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Admin',
                style: SentinelTheme.sans.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: SentinelTheme.textPrimary,
                ),
              ),
              Text(
                'pruthvirajrajput353@gmail.com',
                style: SentinelTheme.sans.copyWith(
                  fontSize: 10,
                  color: SentinelTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusPill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: SentinelTheme.mono.copyWith(
              fontSize: 9,
              color: SentinelTheme.textMuted,
            ),
          ),
          Text(
            value,
            style: SentinelTheme.mono.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

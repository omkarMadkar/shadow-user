import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/keystroke_provider.dart';
import '../services/global_keystroke_monitor_service.dart';
import '../theme/sentinel_theme.dart';

/// Widget showing the OS-level global keystroke monitor status,
/// content threat alerts, and live typed-text preview.
class ContentThreatPanel extends StatelessWidget {
  const ContentThreatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: SentinelTheme.glassCard(glowColor: const Color(0xFFEF4444)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _PanelHeader(),
          const SizedBox(height: 12),
          // Content
          Expanded(
            child: Consumer<KeystrokeProvider>(
              builder: (_, kp, __) {
                if (!kp.globalMonitorActive) {
                  return _InactiveState();
                }
                return _ActiveMonitorView();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<KeystrokeProvider>(
      builder: (_, kp, __) => Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 16,
            color: kp.globalMonitorActive
                ? SentinelTheme.alertRed
                : SentinelTheme.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'CONTENT THREAT MONITOR',
              style: SentinelTheme.sans.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SentinelTheme.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          // Threat count badge
          if (kp.contentThreats.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: SentinelTheme.alertRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: SentinelTheme.alertRed.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${kp.contentThreats.length} THREATS',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.alertRed,
                ),
              ),
            ),
          // Backspace cover-up count
          if (kp.backspaceCoverUpCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${kp.backspaceCoverUpCount} COVER-UPS',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ),
          // Toggle button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                if (kp.globalMonitorActive) {
                  kp.stopGlobalMonitor();
                } else {
                  kp.startGlobalMonitor();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: kp.globalMonitorActive
                        ? SentinelTheme.alertRed.withValues(alpha: 0.4)
                        : SentinelTheme.alertGreen.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(6),
                  color: kp.globalMonitorActive
                      ? SentinelTheme.alertRed.withValues(alpha: 0.1)
                      : SentinelTheme.alertGreen.withValues(alpha: 0.1),
                ),
                child: Text(
                  kp.globalMonitorActive ? 'STOP' : 'START',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kp.globalMonitorActive
                        ? SentinelTheme.alertRed
                        : SentinelTheme.alertGreen,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InactiveState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.keyboard_hide,
            size: 32,
            color: SentinelTheme.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 10),
          Text(
            'Global Keystroke Monitor is initializing...',
            style: SentinelTheme.sans.copyWith(
              fontSize: 12,
              color: SentinelTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Monitoring will start automatically',
            style: SentinelTheme.mono.copyWith(
              fontSize: 10,
              color: SentinelTheme.textMuted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveMonitorView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<KeystrokeProvider>(
      builder: (_, kp, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current app & live text
            _LiveTypingPreview(
              currentText: kp.currentTypedText,
              foregroundApp: kp.currentForegroundApp,
            ),
            const SizedBox(height: 10),
            // Threat alerts list
            Expanded(
              child: kp.contentThreats.isEmpty
                  ? Center(
                      child: Text(
                        'No content threats detected — monitoring...',
                        style: SentinelTheme.mono.copyWith(
                          fontSize: 10,
                          color: SentinelTheme.alertGreen.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: kp.contentThreats.length > 10
                          ? 10
                          : kp.contentThreats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) =>
                          _ThreatTile(alert: kp.contentThreats[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _LiveTypingPreview extends StatelessWidget {
  final String currentText;
  final String foregroundApp;

  const _LiveTypingPreview({
    required this.currentText,
    required this.foregroundApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SentinelTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SentinelTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_outlined,
                size: 12,
                color: SentinelTheme.cyberBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  foregroundApp.isNotEmpty ? foregroundApp : 'No active window',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    color: SentinelTheme.cyberBlue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 6,
                height: 6,
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
            ],
          ),
          const SizedBox(height: 6),
          Text(
            currentText.isNotEmpty ? currentText : '...',
            style: SentinelTheme.mono.copyWith(
              fontSize: 11,
              color: currentText.isNotEmpty
                  ? SentinelTheme.textPrimary
                  : SentinelTheme.textMuted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ThreatTile extends StatelessWidget {
  final ContentThreatAlert alert;

  const _ThreatTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = _threatColor(alert.threatType);
    final icon = _threatIcon(alert.threatType);
    final timeStr =
        '${alert.timestamp.hour.toString().padLeft(2, '0')}:'
        '${alert.timestamp.minute.toString().padLeft(2, '0')}:'
        '${alert.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                _threatLabel(alert.threatType),
                style: SentinelTheme.sans.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                timeStr,
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  color: SentinelTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Show the flagged content
          if (alert.wasDeletedAfterTyping) ...[
            Text(
              'DELETED: "${_truncate(alert.deletedText, 60)}"',
              style: SentinelTheme.mono.copyWith(
                fontSize: 10,
                color: const Color(0xFFF59E0B),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 2),
          ],
          if (alert.typedText.isNotEmpty)
            Text(
              '"${_truncate(alert.typedText, 80)}"',
              style: SentinelTheme.mono.copyWith(
                fontSize: 10,
                color: SentinelTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Severity: ${alert.analysis.severity}%',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'App: ${_truncate(alert.foregroundApp, 25)}',
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    color: SentinelTheme.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _threatColor(ContentThreatType type) {
    switch (type) {
      case ContentThreatType.backspaceCoverUp:
        return const Color(0xFFF59E0B); // amber
      case ContentThreatType.sentThreatening:
        return SentinelTheme.alertRed;
      case ContentThreatType.liveTyping:
        return const Color(0xFFF97316); // orange
    }
  }

  IconData _threatIcon(ContentThreatType type) {
    switch (type) {
      case ContentThreatType.backspaceCoverUp:
        return Icons.backspace_outlined;
      case ContentThreatType.sentThreatening:
        return Icons.send_outlined;
      case ContentThreatType.liveTyping:
        return Icons.keyboard_outlined;
    }
  }

  String _threatLabel(ContentThreatType type) {
    switch (type) {
      case ContentThreatType.backspaceCoverUp:
        return 'BACKSPACE COVER-UP';
      case ContentThreatType.sentThreatening:
        return 'SENT THREATENING';
      case ContentThreatType.liveTyping:
        return 'LIVE THREAT DETECTED';
    }
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }
}

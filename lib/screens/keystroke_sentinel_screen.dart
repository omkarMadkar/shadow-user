import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/keystroke_provider.dart';
import '../theme/sentinel_theme.dart';
import '../widgets/keystroke_waveform_widget.dart';
import '../widgets/keystroke_stats_panel.dart';
import '../widgets/keystroke_pattern_chart.dart';
import '../widgets/keystroke_alert_card.dart';
import '../widgets/keystroke_log_widget.dart';
import '../widgets/content_threat_panel.dart';

/// Full Keystroke Sentinel screen with real-time key capture.
class KeystrokeSentinelScreen extends StatefulWidget {
  const KeystrokeSentinelScreen({super.key});

  @override
  State<KeystrokeSentinelScreen> createState() =>
      _KeystrokeSentinelScreenState();
}

class _KeystrokeSentinelScreenState extends State<KeystrokeSentinelScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus and auto-start global keystroke monitor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      // Auto-start global OS-level keystroke monitor
      final kp = context.read<KeystrokeProvider>();
      if (!kp.globalMonitorActive) {
        kp.startGlobalMonitor();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    final kp = context.read<KeystrokeProvider>();

    // Feed into the dynamics service and process every keystroke
    kp.service.handleKeyEvent(event);
    kp.processLiveKey();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              if (isWide) {
                return _wideLayout();
              } else {
                return _narrowLayout();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _wideLayout() {
    return Column(
      children: [
        // Title bar + Demo toggle
        _ScreenHeader(),
        const SizedBox(height: 16),

        // Top row: Stats | Content Threat Monitor
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 5, child: KeystrokeStatsPanel()),
              const SizedBox(width: 16),
              const Expanded(
                flex: 5,
                child: SizedBox(height: 250, child: ContentThreatPanel()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Mid row: Waveform | Pattern chart
        SizedBox(
          height: 260,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 6, child: KeystrokeWaveformWidget()),
              const SizedBox(width: 16),
              const Expanded(flex: 6, child: KeystrokePatternChart()),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bottom row: Alerts | Log
        SizedBox(
          height: 300,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 5, child: KeystrokeAlertCard()),
              const SizedBox(width: 16),
              const Expanded(flex: 5, child: KeystrokeLogWidget()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout() {
    return Column(
      children: [
        _ScreenHeader(),
        const SizedBox(height: 16),
        const KeystrokeStatsPanel(),
        const SizedBox(height: 16),
        const SizedBox(height: 280, child: ContentThreatPanel()),
        const SizedBox(height: 16),
        const SizedBox(height: 220, child: KeystrokeWaveformWidget()),
        const SizedBox(height: 16),
        const SizedBox(height: 220, child: KeystrokePatternChart()),
        const SizedBox(height: 16),
        const SizedBox(height: 280, child: KeystrokeAlertCard()),
        const SizedBox(height: 16),
        const SizedBox(height: 280, child: KeystrokeLogWidget()),
      ],
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<KeystrokeProvider>(
      builder: (_, kp, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: SentinelTheme.glassCard(
            glowColor: kp.demoMode
                ? const Color(0xFF8B5CF6)
                : SentinelTheme.cyberBlue,
          ),
          child: Row(
            children: [
              Icon(
                Icons.keyboard_alt_outlined,
                size: 20,
                color: SentinelTheme.cyberBlue,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KEYSTROKE SENTINEL',
                    style: SentinelTheme.sans.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: SentinelTheme.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Behavioral biometric analysis — typing dynamics',
                    style: SentinelTheme.sans.copyWith(
                      fontSize: 10,
                      color: SentinelTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Mode badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _modeColor(kp.mode).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _modeColor(kp.mode).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _modeLabel(kp.mode),
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _modeColor(kp.mode),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Demo toggle
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => kp.toggleDemoMode(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: kp.demoMode
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                            : SentinelTheme.border,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: kp.demoMode
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          kp.demoMode ? Icons.science : Icons.science_outlined,
                          size: 14,
                          color: kp.demoMode
                              ? const Color(0xFF8B5CF6)
                              : SentinelTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'DEMO',
                          style: SentinelTheme.mono.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: kp.demoMode
                                ? const Color(0xFF8B5CF6)
                                : SentinelTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Color _modeColor(KeystrokeMode mode) {
    switch (mode) {
      case KeystrokeMode.idle:
        return SentinelTheme.textMuted;
      case KeystrokeMode.enrolling:
        return SentinelTheme.cyberBlue;
      case KeystrokeMode.monitoring:
        return SentinelTheme.alertGreen;
    }
  }

  static String _modeLabel(KeystrokeMode mode) {
    switch (mode) {
      case KeystrokeMode.idle:
        return 'IDLE';
      case KeystrokeMode.enrolling:
        return 'ENROLLING';
      case KeystrokeMode.monitoring:
        return 'MONITORING';
    }
  }
}

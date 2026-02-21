import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sentinel_provider.dart';
import '../theme/sentinel_theme.dart';

/// Demo control panel for hackathon demonstrations.
/// 
/// Allows switching between different threat scenarios to showcase
/// the Shadow Sentinel's detection capabilities.
class DemoControlPanel extends StatelessWidget {
  const DemoControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SentinelProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: SentinelTheme.glassCard(
            glowColor: const Color(0xFF8B5CF6),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.science,
                      size: 18,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEMO CONTROL PANEL',
                          style: SentinelTheme.mono.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8B5CF6),
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Simulate threat scenarios',
                          style: SentinelTheme.sans.copyWith(
                            fontSize: 10,
                            color: SentinelTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // API Status indicator
                  _ApiStatusBadge(connected: provider.apiConnected),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Active scenario indicator
              if (provider.activeScenario != null) ...[
                _ActiveScenarioBanner(scenario: provider.activeScenario!),
                const SizedBox(height: 12),
              ],
              
              // Trust Score Components Display
              _TrustComponentsDisplay(provider: provider),
              
              const SizedBox(height: 16),
              
              // Scenario buttons grid
              Text(
                'ACTIVATE SCENARIO',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: SentinelTheme.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ScenarioButton(
                    label: 'IDENTITY\nMISMATCH',
                    icon: Icons.face_retouching_off,
                    scenario: DemoScenario.identityMismatch,
                    color: SentinelTheme.alertRed,
                    isActive: provider.activeScenario == DemoScenario.identityMismatch,
                  ),
                  _ScenarioButton(
                    label: 'SPOOFING\nATTEMPT',
                    icon: Icons.photo_camera_front,
                    scenario: DemoScenario.spoofingAttempt,
                    color: SentinelTheme.alertRed,
                    isActive: provider.activeScenario == DemoScenario.spoofingAttempt,
                  ),
                  _ScenarioButton(
                    label: 'KEYSTROKE\nANOMALY',
                    icon: Icons.keyboard_alt_outlined,
                    scenario: DemoScenario.keystrokeAnomaly,
                    color: SentinelTheme.alertAmber,
                    isActive: provider.activeScenario == DemoScenario.keystrokeAnomaly,
                  ),
                  _ScenarioButton(
                    label: 'PHISHING\nDETECTED',
                    icon: Icons.phishing,
                    scenario: DemoScenario.phishingDetected,
                    color: SentinelTheme.alertAmber,
                    isActive: provider.activeScenario == DemoScenario.phishingDetected,
                  ),
                  _ScenarioButton(
                    label: 'BURNOUT\nRISK',
                    icon: Icons.local_fire_department,
                    scenario: DemoScenario.burnoutRisk,
                    color: const Color(0xFFF97316),
                    isActive: provider.activeScenario == DemoScenario.burnoutRisk,
                  ),
                  _ScenarioButton(
                    label: 'NORMAL\nOPERATION',
                    icon: Icons.check_circle_outline,
                    scenario: DemoScenario.normalOperation,
                    color: SentinelTheme.alertGreen,
                    isActive: provider.activeScenario == DemoScenario.normalOperation,
                  ),
                ],
              ),
              
              // Reset button
              if (provider.activeScenario != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => provider.deactivateScenario(),
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text(
                      'RESET TO NORMAL',
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: SentinelTheme.cyberBlue,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// API connection status badge
class _ApiStatusBadge extends StatelessWidget {
  final bool connected;
  
  const _ApiStatusBadge({required this.connected});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (connected ? SentinelTheme.alertGreen : SentinelTheme.alertAmber)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (connected ? SentinelTheme.alertGreen : SentinelTheme.alertAmber)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? SentinelTheme.alertGreen : SentinelTheme.alertAmber,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'API' : 'DEMO',
            style: SentinelTheme.mono.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: connected ? SentinelTheme.alertGreen : SentinelTheme.alertAmber,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner showing active scenario
class _ActiveScenarioBanner extends StatelessWidget {
  final DemoScenario scenario;
  
  const _ActiveScenarioBanner({required this.scenario});
  
  @override
  Widget build(BuildContext context) {
    final color = _getScenarioColor(scenario);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'SCENARIO ACTIVE: ${_getScenarioName(scenario)}',
              style: SentinelTheme.mono.copyWith(
                fontSize: 10,
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
  
  Color _getScenarioColor(DemoScenario scenario) {
    switch (scenario) {
      case DemoScenario.identityMismatch:
      case DemoScenario.spoofingAttempt:
        return SentinelTheme.alertRed;
      case DemoScenario.keystrokeAnomaly:
      case DemoScenario.phishingDetected:
        return SentinelTheme.alertAmber;
      case DemoScenario.burnoutRisk:
        return const Color(0xFFF97316);
      case DemoScenario.normalOperation:
        return SentinelTheme.alertGreen;
    }
  }
  
  String _getScenarioName(DemoScenario scenario) {
    switch (scenario) {
      case DemoScenario.identityMismatch:
        return 'IDENTITY MISMATCH';
      case DemoScenario.spoofingAttempt:
        return 'SPOOFING ATTEMPT';
      case DemoScenario.keystrokeAnomaly:
        return 'KEYSTROKE ANOMALY';
      case DemoScenario.phishingDetected:
        return 'PHISHING DETECTED';
      case DemoScenario.burnoutRisk:
        return 'BURNOUT RISK';
      case DemoScenario.normalOperation:
        return 'NORMAL OPERATION';
    }
  }
}

/// Trust score components display
class _TrustComponentsDisplay extends StatelessWidget {
  final SentinelProvider provider;
  
  const _TrustComponentsDisplay({required this.provider});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SentinelTheme.bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SentinelTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRUST SCORE COMPONENTS',
            style: SentinelTheme.mono.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: SentinelTheme.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          
          // Face (40%)
          _ComponentBar(
            label: 'FACE MATCH',
            value: provider.faceConfidence,
            weight: '40%',
            color: _getComponentColor(provider.faceConfidence),
          ),
          const SizedBox(height: 6),
          
          // Keystroke (40%)
          _ComponentBar(
            label: 'KEYSTROKE',
            value: provider.keystrokeMatch,
            weight: '40%',
            color: _getComponentColor(provider.keystrokeMatch),
          ),
          const SizedBox(height: 6),
          
          // Activity (20%)
          _ComponentBar(
            label: 'ACTIVITY',
            value: provider.activitySafety,
            weight: '20%',
            color: _getComponentColor(provider.activitySafety),
          ),
          
          const SizedBox(height: 10),
          Divider(color: SentinelTheme.border, height: 1),
          const SizedBox(height: 10),
          
          // Total trust score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TRUST SCORE',
                style: SentinelTheme.mono.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${provider.trustScore.toStringAsFixed(1)}%',
                    style: SentinelTheme.mono.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _getComponentColor(provider.trustScore),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRiskColor(provider.trustRiskLevel).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      provider.trustRiskLevel,
                      style: SentinelTheme.mono.copyWith(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: _getRiskColor(provider.trustRiskLevel),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getComponentColor(double value) {
    if (value >= 80) return SentinelTheme.alertGreen;
    if (value >= 60) return SentinelTheme.cyberBlue;
    if (value >= 40) return SentinelTheme.alertAmber;
    return SentinelTheme.alertRed;
  }
  
  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'LOW':
        return SentinelTheme.alertGreen;
      case 'MEDIUM':
        return SentinelTheme.alertAmber;
      case 'HIGH':
        return const Color(0xFFF97316);
      case 'CRITICAL':
        return SentinelTheme.alertRed;
      default:
        return SentinelTheme.textMuted;
    }
  }
}

/// Individual component progress bar
class _ComponentBar extends StatelessWidget {
  final String label;
  final double value;
  final String weight;
  final Color color;
  
  const _ComponentBar({
    required this.label,
    required this.value,
    required this.weight,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: SentinelTheme.mono.copyWith(
              fontSize: 8,
              color: SentinelTheme.textMuted,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: SentinelTheme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (value / 100).clamp(0, 1),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            '${value.toStringAsFixed(0)}%',
            style: SentinelTheme.mono.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          weight,
          style: SentinelTheme.mono.copyWith(
            fontSize: 8,
            color: SentinelTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Scenario activation button
class _ScenarioButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final DemoScenario scenario;
  final Color color;
  final bool isActive;
  
  const _ScenarioButton({
    required this.label,
    required this.icon,
    required this.scenario,
    required this.color,
    required this.isActive,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final provider = context.read<SentinelProvider>();
          provider.activateScenario(scenario);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.15) : SentinelTheme.bg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? color.withValues(alpha: 0.5) : SentinelTheme.border,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? color : SentinelTheme.textMuted,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: SentinelTheme.mono.copyWith(
                  fontSize: 7,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? color : SentinelTheme.textMuted,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

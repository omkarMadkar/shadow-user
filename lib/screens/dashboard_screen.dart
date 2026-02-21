import 'package:flutter/material.dart';
import '../widgets/trust_gauge.dart';
import '../widgets/sentinel_status_card.dart';
import '../widgets/event_log_terminal.dart';
import '../widgets/productivity_heatmap.dart';
import '../widgets/threat_overview_panel.dart';
import '../widgets/demo_control_panel.dart';

/// Main dashboard screen — assembles all widgets in a responsive grid.
/// Header and footer are now managed by MainShell.
/// 
/// Now includes Demo Control Panel for hackathon demonstrations.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
    );
  }

  Widget _wideLayout() {
    return Column(
      children: [
        // Top row: Trust Gauge | Sentinel Status | Demo Control
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trust Gauge
              SizedBox(
                width: 240,
                child: const TrustGaugeWidget(),
              ),
              const SizedBox(width: 16),
              // Sentinel Modules
              Expanded(
                flex: 5,
                child: const SentinelStatusCard(),
              ),
              const SizedBox(width: 16),
              // Demo Control Panel (replaces Threats in wide layout for demo)
              Expanded(
                flex: 4,
                child: const DemoControlPanel(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Middle row: Threats + Users | Event Log
        SizedBox(
          height: 580,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: const ThreatOverviewPanel(),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 7,
                child: const EventLogTerminal(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Bottom row: Productivity Heatmap (full width)
        const SizedBox(
          height: 380,
          child: ProductivityHeatmapWidget(),
        ),
      ],
    );
  }

  Widget _narrowLayout() {
    return Column(
      children: [
        const TrustGaugeWidget(),
        const SizedBox(height: 16),
        // Demo Control Panel at the top for easy access on mobile
        const DemoControlPanel(),
        const SizedBox(height: 16),
        const SentinelStatusCard(),
        const SizedBox(height: 16),
        const ThreatOverviewPanel(),
        const SizedBox(height: 16),
        const ProductivityHeatmapWidget(),
        const SizedBox(height: 16),
        SizedBox(
          height: 400,
          child: const EventLogTerminal(),
        ),
      ],
    );
  }
}

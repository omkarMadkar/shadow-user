import 'package:flutter/material.dart';
import '../widgets/trust_gauge.dart';
import '../widgets/sentinel_status_card.dart';
import '../widgets/event_log_terminal.dart';
import '../widgets/productivity_heatmap.dart';
import '../widgets/threat_overview_panel.dart';

/// Main dashboard screen — assembles all widgets in a responsive grid.
/// Header and footer are now managed by MainShell.
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
        // Top row: Trust Gauge | Sentinel Status | Threats
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
              // Threats + Users
              Expanded(
                flex: 4,
                child: const ThreatOverviewPanel(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Bottom row: Heatmap | Event Log
        SizedBox(
          height: 420,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: const ProductivityHeatmapWidget(),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: const EventLogTerminal(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout() {
    return Column(
      children: [
        const TrustGaugeWidget(),
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

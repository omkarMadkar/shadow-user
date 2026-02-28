import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sentinel_provider.dart';
import '../models/models.dart';
import '../theme/sentinel_theme.dart';

/// 5-day × 13-hour interactive productivity heatmap.
class ProductivityHeatmapWidget extends StatelessWidget {
  const ProductivityHeatmapWidget({super.key});

  static const _hourLabels = ['6a','7a','8a','9a','10a','11a','12p','1p','2p','3p','4p','5p','6p'];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  Color _stateColor(ProductivityState state) {
    switch (state) {
      case ProductivityState.deepWork:
        return SentinelTheme.cyberBlue;
      case ProductivityState.focused:
        return SentinelTheme.alertGreen;
      case ProductivityState.distracted:
        return SentinelTheme.alertAmber;
      case ProductivityState.burnoutRisk:
        return SentinelTheme.alertRed;
      case ProductivityState.offline:
        return SentinelTheme.border;
    }
  }

  String _stateLabel(ProductivityState state) {
    switch (state) {
      case ProductivityState.deepWork:
        return 'Deep Work';
      case ProductivityState.focused:
        return 'Focused';
      case ProductivityState.distracted:
        return 'Distracted';
      case ProductivityState.burnoutRisk:
        return 'Burnout Risk';
      case ProductivityState.offline:
        return 'Offline';
    }
  }

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
                  Icon(Icons.grid_view_rounded, size: 16, color: SentinelTheme.cyberBlue),
                  const SizedBox(width: 8),
                  Text(
                    'PRODUCTIVITY HEATMAP',
                    style: SentinelTheme.sans.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: SentinelTheme.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Text(
                'This Week',
                style: SentinelTheme.sans.copyWith(
                  fontSize: 11,
                  color: SentinelTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hour headers
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Row(
              children: _hourLabels.map((h) => Expanded(
                child: Text(
                  h,
                  textAlign: TextAlign.center,
                  style: SentinelTheme.mono.copyWith(
                    fontSize: 9,
                    color: SentinelTheme.textMuted,
                  ),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Grid rows
          Consumer<SentinelProvider>(
            builder: (_, provider, __) {
              return Column(
                children: List.generate(5, (dayIdx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text(
                            _dayLabels[dayIdx],
                            textAlign: TextAlign.right,
                            style: SentinelTheme.mono.copyWith(
                              fontSize: 10,
                              color: SentinelTheme.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ...List.generate(13, (hourIdx) {
                          final slot = provider.heatmapData[dayIdx][hourIdx];
                          final color = _stateColor(slot.state);
                          return Expanded(
                            child: Tooltip(
                              message: '${_dayLabels[dayIdx]} ${_hourLabels[hourIdx]} — ${_stateLabel(slot.state)}',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1),
                                child: Container(
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: slot.intensity),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 12),

          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              ProductivityState.deepWork,
              ProductivityState.focused,
              ProductivityState.distracted,
              ProductivityState.burnoutRisk,
            ].map((state) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _stateColor(state),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _stateLabel(state),
                    style: SentinelTheme.sans.copyWith(
                      fontSize: 10,
                      color: SentinelTheme.textMuted,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Stats row
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: SentinelTheme.border)),
            ),
            child: Consumer<SentinelProvider>(
              builder: (_, p, __) {
                final stats = p.productivityStats;
                return Row(
                  children: [
                    _StatTile('Deep Work', '${stats['deepWork']}%', SentinelTheme.cyberBlue),
                    _StatTile('Focused', '${stats['focused']}%', SentinelTheme.alertGreen),
                    _StatTile('Distracted', '${stats['distracted']}%', SentinelTheme.alertAmber),
                    _StatTile('Burnout', '${stats['burnout']}%', SentinelTheme.alertRed),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: SentinelTheme.mono.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: SentinelTheme.sans.copyWith(
              fontSize: 9,
              color: SentinelTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/milstd_theme.dart';
import 'fuel_color_bar.dart';

/// Drone Status Dashboard Panel — displays all drone vitals.
///
/// Shows fuel bar, structural integrity, sensors, COMMS, VIS/RCS,
/// current altitude, and loaded weapons in a compact panel.
class DroneStatusPanel extends StatelessWidget {
  const DroneStatusPanel({
    super.key,
    required this.droneName,
    required this.fuelPercent,
    required this.integrityPercent,
    required this.sensorsDamage,
    required this.maxSensors,
    required this.commsDamage,
    required this.maxComms,
    required this.visRcs,
    required this.altitude,
    required this.loadoutNames,
  });

  final String droneName;
  final double fuelPercent;
  final double integrityPercent;
  final int sensorsDamage;
  final int maxSensors;
  final int commsDamage;
  final int maxComms;
  final int visRcs;
  final String altitude;
  final List<String> loadoutNames;

  Color _damageColor(int current, int max) {
    if (current == 0) return MilstdTheme.statusOk;
    final ratio = current / max;
    if (ratio < 0.33) return MilstdTheme.statusCaution;
    if (ratio < 0.66) return MilstdTheme.statusWarning;
    if (ratio < 1.0) return MilstdTheme.statusCritical;
    return MilstdTheme.statusDestroyed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MilstdTheme.backgroundSecondary,
        borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
        border: Border.all(color: MilstdTheme.borderDefault, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DRONE STATUS',
                style: TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: MilstdTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                droneName,
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: MilstdTheme.accentSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: MilstdTheme.borderSubtle, height: 1),
          const SizedBox(height: 8),

          // Fuel bar
          FuelColorBar(fuelPercent: fuelPercent),
          const SizedBox(height: 12),
          const Divider(color: MilstdTheme.borderSubtle, height: 1),
          const SizedBox(height: 8),

          // Status indicators row
          Row(
            children: [
              Expanded(
                child: _StatusDots(
                  label: 'INTEGRITY',
                  filledCount: (integrityPercent * 10).round(),
                  totalCount: 10,
                  color: _damageColor((10 - (integrityPercent * 10).round()), 10),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatusDots(
                  label: 'SENSORS',
                  filledCount: sensorsDamage,
                  totalCount: maxSensors,
                  color: _damageColor(sensorsDamage, maxSensors),
                  isDamageIndicator: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatusDots(
                  label: 'VIS/RCS',
                  filledCount: visRcs,
                  totalCount: 10,
                  color: _damageColor(visRcs, 10),
                  isDamageIndicator: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatusDots(
                  label: 'COMMS',
                  filledCount: commsDamage,
                  totalCount: maxComms,
                  color: _damageColor(commsDamage, maxComms),
                  isDamageIndicator: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: MilstdTheme.borderSubtle, height: 1),
          const SizedBox(height: 8),

          // Altitude + Loadout
          Row(
            children: [
              const Text(
                'ALT: ',
                style: TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: MilstdTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const Icon(Icons.arrow_upward, size: 14, color: MilstdTheme.accentPrimary),
              const SizedBox(width: 2),
              Text(
                altitude,
                style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MilstdTheme.accentPrimary,
                ),
              ),
              const SizedBox(width: 24),
              const Text(
                'LOADOUT: ',
                style: TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: MilstdTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              ...loadoutNames.map((name) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: MilstdTheme.backgroundTertiary,
                    borderRadius: const BorderRadius.all(MilstdTheme.radiusXs),
                    border: Border.all(color: MilstdTheme.borderDefault, width: 1),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 10,
                      color: MilstdTheme.textPrimary,
                    ),
                  ),
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

/// Row of filled/empty dots representing a stat value.
class _StatusDots extends StatelessWidget {
  const _StatusDots({
    required this.label,
    required this.filledCount,
    required this.totalCount,
    required this.color,
    this.isDamageIndicator = false,
  });

  final String label;
  final int filledCount;
  final int totalCount;
  final Color color;
  final bool isDamageIndicator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: MilstdTheme.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(totalCount, (i) {
            final isFilled = isDamageIndicator ? i < filledCount : i < filledCount;
            return Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? color : Colors.transparent,
                  border: Border.all(
                    color: isFilled ? color : MilstdTheme.textMuted,
                    width: 1,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

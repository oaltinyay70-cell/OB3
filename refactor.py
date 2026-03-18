import os

path = '/Users/ozgur/Documents/OB3/lib/features/drone_selection/drone_selection_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

# Replace layout
old_layout = '''        // === MAIN HUD AREA: left panel | center drone | right panel ===
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LeftContinuousPanel(drone: drone),
                Expanded(child: _CenterHudArea(drone: drone)),
                _RightContinuousPanel(altText: _altText, stations: drone.stations ?? 0, rangeText: _rangeText),
              ],
            ),
          ),
        ),'''
new_layout = '''        // === TOP DRONE PROFILE & STATS ===
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 11,
                  child: _DroneSideProfile(drone: drone),
                ),
                const SizedBox(height: 16),
                Expanded(
                  flex: 9,
                  child: _DroneStatsPanel(drone: drone),
                ),
              ],
            ),
          ),
        ),'''
code = code.replace(old_layout, new_layout)

panels_start = code.find('// =============================================================================\n// PANELS')
history_start = code.find('// =============================================================================\n// MISSION HISTORY')

if panels_start != -1 and history_start != -1:
    new_classes = '''// =============================================================================
// DRONE PROFILE & STATS
// =============================================================================

class _DroneSideProfile extends StatelessWidget {
  const _DroneSideProfile({required this.drone});
  final Drone drone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1218),
        border: Border.all(color: const Color(0xFF1E3A4F), width: 1.5),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 4))],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Image.asset(
            'assets/images/drones/bayraktar_tb2.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _DroneStatsPanel extends StatelessWidget {
  const _DroneStatsPanel({required this.drone});
  final Drone drone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Range Bar Graph
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              border: Border.all(color: const Color(0xFF1E3A4F), width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                 const SizedBox(
                   width: 50,
                   child: Text('RANGE', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8BA992), letterSpacing: 1.0)),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Container(
                     height: 12,
                     decoration: BoxDecoration(color: const Color(0xFF060B10), borderRadius: BorderRadius.circular(2)),
                     child: FractionallySizedBox(
                       alignment: Alignment.centerLeft,
                       widthFactor: 0.75, // Placeholder for dynamic range max
                       child: Container(
                         decoration: BoxDecoration(
                           color: const Color(0xFF00E676), 
                           borderRadius: BorderRadius.circular(2), 
                           boxShadow: [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.5), blurRadius: 4)]
                         ),
                       )
                     )
                   )
                 ),
                 const SizedBox(width: 16),
                 Text('${drone.range ?? 'N/A'}', style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            )
          )
        ),
        const SizedBox(height: 12),
        // Row 2: Structural Integrity | Altitudes
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B2A),
                    border: Border.all(color: const Color(0xFF1E3A4F), width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('INTEGRITY', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8BA992), letterSpacing: 1.0)),
                      const SizedBox(height: 4),
                      Text('${drone.maxStructuralIntegrity} PTS', style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                )
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B2A),
                    border: Border.all(color: const Color(0xFF1E3A4F), width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('ALTITUDES', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8BA992), letterSpacing: 1.0)),
                      const SizedBox(height: 4),
                      Text(_altText(drone.allowedAltitudes), style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center),
                    ],
                  ),
                )
              )
            ]
          )
        )
      ]
    );
  }

  String _altText(List<Altitude> alts) {
    if (alts.isEmpty) return 'N/A';
    return alts.map((a) => switch (a) {
          Altitude.vlow => 'VLOW',
          Altitude.low => 'LOW',
          Altitude.medium => 'MED',
          Altitude.high => 'HIGH',
        }).join('/');
  }
}

'''
    code = code[:panels_start] + new_classes + code[history_start:]
else:
    print('Failed to locate block indices!')

with open(path, 'w', encoding='utf-8') as f:
    f.write(code)

print('Success')

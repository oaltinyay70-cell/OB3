import os

path = '/Users/ozgur/Documents/OB3/lib/features/drone_selection/drone_selection_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

parts = code.split('class _DroneStatsPanel extends StatelessWidget {')
stats_part = parts[1]
end_idx = stats_part.find('// =============================================================================\n// MISSION HISTORY')

new_stats_panel = '''class _DroneStatsPanel extends StatelessWidget {
  const _DroneStatsPanel({required this.drone});
  final Drone drone;

  int _parseMaxRange(String? rangeStr) {
    if (rangeStr == null) return 0;
    final matches = RegExp(r'\\d+').allMatches(rangeStr);
    if (matches.isEmpty) return 0;
    return matches.map((m) => int.parse(m.group(0)!)).reduce(math.max);
  }

  @override
  Widget build(BuildContext context) {
    final maxRange = _parseMaxRange(drone.range);
    final rangeFraction = (maxRange / 3000).clamp(0.0, 1.0); // Assuming 3000km is max scale

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Range Bar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              border: Border.all(color: const Color(0xFF1E3A4F), width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                 Expanded(
                   flex: 3,
                   child: FittedBox(
                     alignment: Alignment.centerLeft,
                     fit: BoxFit.scaleDown,
                     child: const Text('RANGE', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8BA992), letterSpacing: 1.0)),
                   ),
                 ),
                 const SizedBox(width: 8),
                 Expanded(
                   flex: 5,
                   child: Container(
                     height: 12,
                     decoration: BoxDecoration(color: const Color(0xFF060B10), borderRadius: BorderRadius.circular(2)),
                     child: FractionallySizedBox(
                       alignment: Alignment.centerLeft,
                       widthFactor: rangeFraction > 0 ? rangeFraction : 0.05,
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
                 const SizedBox(width: 8),
                 Expanded(
                   flex: 3,
                   child: FittedBox(
                     alignment: Alignment.centerRight,
                     fit: BoxFit.scaleDown,
                     child: Text('${drone.range ?? 'N/A'}', style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                   ),
                 ),
              ],
            )
          ),
          const SizedBox(height: 12),
          // Row 2: Integrity & Altitudes
          Row(
            children: [
              Expanded(child: _StatBox(label: 'INTEGRITY', value: '${drone.maxStructuralIntegrity} PTS')),
              const SizedBox(width: 12),
              Expanded(child: _StatBox(label: 'ALTITUDES', value: _altText(drone.allowedAltitudes))),
            ],
          ),
          const SizedBox(height: 12),
          // Row 3: RCS & VIS
          Row(
            children: [
              Expanded(child: _StatBox(label: 'RCS', value: '${drone.rcs}')),
              const SizedBox(width: 12),
              Expanded(child: _StatBox(label: 'VIS', value: '${drone.vis}')),
            ],
          ),
          const SizedBox(height: 12),
          // Row 4: Built-in Laze
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'BUILT-IN LAZE', 
                  value: drone.hasBuiltinFoLaze ? 'YES' : 'NO', 
                  valueColor: drone.hasBuiltinFoLaze ? const Color(0xFF00E676) : Colors.redAccent
                )
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
          const SizedBox(height: 16),
          // Loadouts Section
          if (drone.loadoutOptions.isNotEmpty) ...[
            Row(
              children: [
                 Expanded(child: Container(margin: const EdgeInsets.only(right: 12), height: 1, color: const Color(0xFF1E3A4F))),
                 const Text('LOADOUT OPTIONS', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF76A2AB), letterSpacing: 1.0)),
                 Expanded(child: Container(margin: const EdgeInsets.only(left: 12), height: 1, color: const Color(0xFF1E3A4F))),
              ],
            ),
            const SizedBox(height: 12),
            ...drone.loadoutOptions.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1218),
                  border: Border.all(color: const Color(0xFF1E3A4F), width: 1.0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A4F),
                        borderRadius: BorderRadius.circular(2)
                      ),
                      child: Text('OPT ${opt.optionNumber}', style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatLoadout(opt),
                        style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF94D3DB)),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ],
      )
    );
  }

  String _formatLoadout(LoadoutOption opt) {
    List<String> weapons = ['${opt.weapon1Qty}x ${opt.weapon1Name}'];
    if (opt.weapon2Name != null && opt.weapon2Qty != null && opt.weapon2Qty! > 0) {
      weapons.add('${opt.weapon2Qty}x ${opt.weapon2Name}');
    }
    return weapons.join(' + ');
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _StatBox({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        border: Border.all(color: const Color(0xFF1E3A4F), width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8BA992), letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontFamily: 'Rajdhani', fontSize: 22, fontWeight: FontWeight.w700, color: valueColor ?? Colors.white), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

'''

new_code = parts[0] + new_stats_panel + stats_part[end_idx:]
with open(path, 'w', encoding='utf-8') as f:
    f.write(new_code)
print('Done!')

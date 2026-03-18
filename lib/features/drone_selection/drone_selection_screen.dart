import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/drone.dart';
import '../../models/game_enums.dart';
import '../../data/database_service.dart';
import '../../data/repositories/drone_repository.dart';

class DroneSelectionScreen extends StatefulWidget {
  const DroneSelectionScreen({
    super.key,
    required this.onDroneAndLoadoutConfirmed,
    this.onBack,
    this.allowedDroneIds = const [],
  });

  final void Function(Drone drone, LoadoutOption loadout) onDroneAndLoadoutConfirmed;
  final VoidCallback? onBack;

  /// When non-empty, only these drone IDs are available for selection.
  /// Empty list = all drones allowed (Quick Game / unrestricted scenario).
  final List<int> allowedDroneIds;

  @override
  State<DroneSelectionScreen> createState() => _DroneSelectionScreenState();
}

class _DroneSelectionScreenState extends State<DroneSelectionScreen> {
  List<Drone>? _allDrones;
  late PageController _pageController;
  int _currentPage = 0;
  int? _selectedLoadoutIndex; // Track selected loadout per-drone

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadDrones();
  }

  Future<void> _loadDrones() async {
    final repo = DroneRepository(DatabaseService.instance);
    var drones = await repo.getAll();

    // Enforce scenario allowed drones restriction
    if (widget.allowedDroneIds.isNotEmpty) {
      final allowed = widget.allowedDroneIds.toSet();
      drones = drones.where((d) => allowed.contains(d.id)).toList();
    }

    if (mounted) setState(() => _allDrones = drones);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int delta) {
    if (_allDrones == null || _allDrones!.isEmpty) return;
    final count = _allDrones!.length;
    final target = (_currentPage + delta) % count; // wrap around
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _confirmSelection(Drone drone, LoadoutOption loadout) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1C2E),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: Color(0xFF1E3A4F)),
        ),
        title: const Text('CONFIRM DEPLOYMENT',
            style: TextStyle(fontFamily: 'Rajdhani', fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF00E676))),
        content: Text('Deploy ${drone.name} with ${loadout.weapon1Name}?',
            style: const TextStyle(fontFamily: 'IBMPlexSans', fontSize: 14, color: Color(0xFF8899A6))),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCEL', style: TextStyle(fontFamily: 'Rajdhani', color: Color(0xFF556677)))),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: const Color(0xFF0A1628)),
            child: const Text('DEPLOY', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) widget.onDroneAndLoadoutConfirmed(drone, loadout);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_allDrones == null) {
      return const Scaffold(backgroundColor: Color(0xFF0A1621), body: Center(child: CircularProgressIndicator(color: Color(0xFF00E676))));
    }
    final drones = _allDrones!;
    final currentDrone = drones.isNotEmpty ? drones[_currentPage] : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0B141E),
      body: SafeArea(
        child: Column(
          children: [
            // === TOP NAV: < BRIEFING > ===
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ArrowBtn(icon: Icons.chevron_left, onTap: () => _goToPage(-1)),
                  if (widget.onBack != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: GestureDetector(
                          onTap: widget.onBack,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(6)),
                              color: const Color(0xFF1E2F3E),
                              border: Border.all(color: const Color(0xFF2B4A5E), width: 1.5),
                            ),
                            child: const Text(
                              'BRIEFING',
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF76A2AB),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  _ArrowBtn(icon: Icons.chevron_right, onTap: () => _goToPage(1)),
                ],
              ),
            ),

            // === PAGES ===
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: drones.length,
                onPageChanged: (i) => setState(() {
                  _currentPage = i;
                  _selectedLoadoutIndex = null; // Reset loadout when switching drone
                }),
                itemBuilder: (_, i) => _DronePage(
                  drone: drones[i],
                  selectedLoadoutIndex: i == _currentPage ? _selectedLoadoutIndex : null,
                  onLoadoutSelected: (idx) => setState(() => _selectedLoadoutIndex = idx),
                ),
              ),
            ),

            // === DOTS + COUNTER ===
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(math.min(drones.length, 12), (i) {
                    final active = i == _currentPage;
                    return Container(
                      width: active ? 10 : 8,
                      height: active ? 10 : 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? const Color(0xFF00E676) : const Color(0xFF3B4D43),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentPage + 1}/${drones.length}',
                    style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, color: Color(0xFF769B82), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // === DEPLOY BUTTON (enabled only when loadout selected) ===
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (currentDrone != null && _selectedLoadoutIndex != null)
                      ? () => _confirmSelection(
                            currentDrone,
                            currentDrone.loadoutOptions[_selectedLoadoutIndex!],
                          )
                      : null,
                  icon: const Icon(Icons.rocket_launch, size: 22),
                  label: Text(
                    _selectedLoadoutIndex != null ? 'DEPLOY' : 'SELECT LOADOUT',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF375439),
                    disabledBackgroundColor: const Color(0xFF1E2F23),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF556655),
                    side: BorderSide(
                      color: _selectedLoadoutIndex != null ? const Color(0xFF5A8954) : const Color(0xFF2B402D),
                      width: 1.5,
                    ),
                    textStyle: const TextStyle(fontFamily: 'Rajdhani', fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  const _ArrowBtn({required this.icon, required this.onTap, this.enabled = true});
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(6)),
          color: enabled ? const Color(0xFF375439) : const Color(0xFF1E2F23),
          border: Border.all(color: enabled ? const Color(0xFF5A8954) : const Color(0xFF2B402D), width: 1.5),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

class _DronePage extends StatelessWidget {
  const _DronePage({
    required this.drone,
    required this.selectedLoadoutIndex,
    required this.onLoadoutSelected,
  });
  final Drone drone;
  final int? selectedLoadoutIndex;
  final ValueChanged<int> onLoadoutSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // === DRONE NAME + CLASS BADGE ===
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    drone.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.0),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF2D4B5E), border: Border.all(color: const Color(0xFF53A1B2), width: 1.5)),
                  alignment: Alignment.center,
                  child: Text(drone.droneClass.name.toUpperCase(), style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF94D3DB))),
                ),
              ],
            ),
          ),

          // === FLAG + CATEGORY ===
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_flagEmoji(drone.country), style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                (drone.category ?? 'COMBAT UCAV').toUpperCase(),
                style: const TextStyle(fontFamily: 'IBMPlexSans', fontSize: 13, color: Color(0xFF88A4A9), fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // === DRONE SIDE PROFILE ===
          _DroneSideProfile(drone: drone),

          const SizedBox(height: 16),

          // === STATS (simplified range + core stats) ===
          _DroneStatsPanel(drone: drone),

          const SizedBox(height: 16),

          // === LOADOUT SELECTION (merged from loadout screen) ===
          if (drone.loadoutOptions.isNotEmpty) ...[
            Row(
              children: [
                Expanded(child: Container(margin: const EdgeInsets.only(right: 12), height: 1, color: const Color(0xFF1E3A4F))),
                const Text('SELECT LOADOUT', style: TextStyle(fontFamily: 'Rajdhani', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF76A2AB), letterSpacing: 1.0)),
                Expanded(child: Container(margin: const EdgeInsets.only(left: 12), height: 1, color: const Color(0xFF1E3A4F))),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(drone.loadoutOptions.length, (i) {
              final opt = drone.loadoutOptions[i];
              final isSelected = selectedLoadoutIndex == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => onLoadoutSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0F2A1A) : const Color(0xFF0A1218),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00E676) : const Color(0xFF1E3A4F),
                        width: isSelected ? 2 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: isSelected
                          ? [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.15), blurRadius: 8)]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00E676) : const Color(0xFF1E3A4F),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'OPT ${opt.optionNumber}',
                            style: TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? const Color(0xFF0A1628) : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatLoadout(opt),
                            style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? const Color(0xFF00E676) : const Color(0xFF94D3DB),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, size: 20, color: Color(0xFF00E676)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatLoadout(LoadoutOption opt) {
    List<String> weapons = ['${opt.weapon1Qty}x ${opt.weapon1Name}'];
    if (opt.weapon2Name != null && opt.weapon2Qty != null && opt.weapon2Qty! > 0) {
      weapons.add('${opt.weapon2Qty}x ${opt.weapon2Name}');
    }
    return weapons.join(' + ');
  }

  String _flagEmoji(String country) {
    final c = country.toLowerCase();
    if (c.contains('turk')) return '🇹🇷';
    if (c.contains('us') || c.contains('united states') || c.contains('america')) return '🇺🇸';
    if (c.contains('uk') || c.contains('united kingdom')) return '🇬🇧';
    if (c.contains('russia')) return '🇷🇺';
    return '🏳️';
  }
}

// =============================================================================
// DRONE PROFILE & STATS
// =============================================================================

class _DroneSideProfile extends StatelessWidget {
  const _DroneSideProfile({required this.drone});
  final Drone drone;

  static const _fallback = 'assets/images/drones/bayraktar_tb2.jpg';

  @override
  Widget build(BuildContext context) {
    // Prefer DB image blob, fall back to asset file
    final Widget imageWidget = drone.image != null
        ? Image.memory(
            drone.image!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          )
        : Image.asset(
            _fallback,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );

    return AspectRatio(
      aspectRatio: 2.0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A1218),
          border: Border.all(color: const Color(0xFF1E3A4F), width: 1.5),
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: imageWidget,
        ),
      ),
    );
  }
}

class _DroneStatsPanel extends StatelessWidget {
  const _DroneStatsPanel({required this.drone});
  final Drone drone;

  int _parseMaxRange(String? rangeStr) {
    if (rangeStr == null) return 0;
    final matches = RegExp(r'\d+').allMatches(rangeStr);
    if (matches.isEmpty) return 0;
    return matches.map((m) => int.parse(m.group(0)!)).reduce(math.max);
  }

  @override
  Widget build(BuildContext context) {
    final maxRange = _parseMaxRange(drone.range);
    final rangeFraction = (maxRange / 3000).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          // Row 1: Range — single horizontal bar with value
          _RangeBar(label: 'RANGE', value: '${maxRange}km', fraction: rangeFraction),
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
      ],
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

/// Simple horizontal bar: LABEL ═══════ VALUE
class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.label, required this.value, required this.fraction});
  final String label;
  final String value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        border: Border.all(color: const Color(0xFF1E3A4F), width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontFamily: 'IBMPlexMono', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8BA992), letterSpacing: 1.0)),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(color: const Color(0xFF060B10), borderRadius: BorderRadius.circular(2)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction > 0 ? fraction : 0.05,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.5), blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(fontFamily: 'Rajdhani', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
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

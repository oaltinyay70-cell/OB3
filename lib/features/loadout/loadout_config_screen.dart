import 'package:flutter/material.dart';
import '../../core/theme/milstd_theme.dart';
import '../../models/drone.dart';

/// Loadout Configuration Screen — matching loadout_config.png mockup.
///
/// Shows "ARMING: DRONE_NAME" header, weapon cards in a horizontal row,
/// slot/payload counter, and "CONFIRM LOADOUT" CTA.
class LoadoutConfigScreen extends StatefulWidget {
  const LoadoutConfigScreen({
    super.key,
    required this.drone,
    required this.onLoadoutConfirmed,
    this.onBack,
  });

  final Drone drone;
  final void Function(LoadoutOption loadout) onLoadoutConfirmed;
  final VoidCallback? onBack;

  @override
  State<LoadoutConfigScreen> createState() => _LoadoutConfigScreenState();
}

class _LoadoutConfigScreenState extends State<LoadoutConfigScreen> {
  int? _selectedIndex;

  LoadoutOption? get _selectedOption =>
      _selectedIndex != null ? widget.drone.loadoutOptions[_selectedIndex!] : null;

  @override
  Widget build(BuildContext context) {
    final drone = widget.drone;
    final options = drone.loadoutOptions;

    return Scaffold(
      backgroundColor: MilstdTheme.backgroundPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ← ARMING: DRONE_NAME
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  if (widget.onBack != null)
                    GestureDetector(
                      onTap: widget.onBack,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: 20,
                          color: MilstdTheme.textPrimary,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      'ARMING: ${drone.name.toUpperCase()}',
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: MilstdTheme.accentSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section label
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'SELECT LOADOUT',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: MilstdTheme.accentPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Weapon cards — horizontal row matching mockup
            Expanded(
              child: options.isEmpty
                  ? const Center(
                      child: Text(
                        'No loadout options available.',
                        style: TextStyle(color: MilstdTheme.textMuted),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(options.length, (i) {
                          final opt = options[i];
                          final isSelected = _selectedIndex == i;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: i > 0 ? 6 : 0,
                                right: i < options.length - 1 ? 6 : 0,
                              ),
                              child: _WeaponCard(
                                option: opt,
                                isSelected: isSelected,
                                onTap: () => setState(() => _selectedIndex = i),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
            ),

            // Slot + payload info
            if (_selectedOption != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: Text(
                    'Slots: ${_selectedIndex! + 1}/${options.length} used | '
                    'Weapons: ${_selectedOption!.weapon1Qty}'
                    '${_selectedOption!.weapon2Qty != null ? " + ${_selectedOption!.weapon2Qty}" : ""}',
                    style: const TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 12,
                      color: MilstdTheme.textSecondary,
                    ),
                  ),
                ),
              ),

            // Confirm bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: MilstdTheme.backgroundSecondary,
                border: Border(
                  top: BorderSide(color: MilstdTheme.borderSubtle, width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _selectedOption != null
                      ? () => widget.onLoadoutConfirmed(_selectedOption!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MilstdTheme.accentPrimary,
                    disabledBackgroundColor:
                        MilstdTheme.accentPrimary.withValues(alpha: 0.3),
                    foregroundColor: MilstdTheme.textInverse,
                    disabledForegroundColor:
                        MilstdTheme.textInverse.withValues(alpha: 0.4),
                    textStyle: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(MilstdTheme.radiusSm),
                    ),
                  ),
                  child: const Text('CONFIRM LOADOUT'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Weapon Card — tall vertical card matching mockup layout
// =============================================================================

class _WeaponCard extends StatelessWidget {
  const _WeaponCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final LoadoutOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MilstdTheme.surface,
          borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
          border: Border.all(
            color: isSelected
                ? MilstdTheme.accentPrimary
                : MilstdTheme.borderDefault,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: MilstdTheme.accentPrimary.withValues(alpha: 0.15),
                    blurRadius: 10,
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weapon 1 name + check
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    option.weapon1Name.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MilstdTheme.textPrimary,
                      height: 1.15,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, size: 18,
                      color: MilstdTheme.accentPrimary),
              ],
            ),

            // Weapon 2 (if any)
            if (option.weapon2Name != null &&
                option.weapon2Name!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                option.weapon2Name!.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: MilstdTheme.textSecondary,
                  height: 1.15,
                ),
              ),
            ],

            const Spacer(),

            // Class + Mode info
            Text(
              'Qty: ×${option.weapon1Qty}',
              style: const TextStyle(
                fontFamily: 'IBMPlexSans',
                fontSize: 11,
                color: MilstdTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Option ${option.optionNumber}',
              style: const TextStyle(
                fontFamily: 'IBMPlexSans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: MilstdTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

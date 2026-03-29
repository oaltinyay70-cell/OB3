import 'package:flutter/material.dart';
import '../../core/theme/milstd_theme.dart';

import '../../models/scenario.dart';

/// Mission Briefing Screen — shown BEFORE drone selection.
///
/// Displays all scenario editor fields so the player can review the mission
/// before accepting. On ACCEPT the player proceeds to drone selection.
///
/// Flow: Menu → **Mission Briefing (ACCEPT)** → Drone Selection → Loadout → Game
class MissionBriefingScreen extends StatelessWidget {
  const MissionBriefingScreen({
    super.key,
    required this.scenario,
    required this.onAccept,
    this.onBack,
  });

  final Scenario scenario;
  final VoidCallback onAccept;
  final VoidCallback? onBack;

  // ---------------------------------------------------------------------------
  // Accept confirmation dialogue
  // ---------------------------------------------------------------------------

  void _confirmAccept(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MilstdTheme.backgroundSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
          side: BorderSide(
            color: MilstdTheme.accentPrimary.withValues(alpha: 0.4),
          ),
        ),
        title: const Text(
          'ACCEPT MISSION?',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: MilstdTheme.textPrimary,
            letterSpacing: 1.0,
          ),
        ),
        content: Text(
          'You will proceed to select your drone and loadout for:\n\n${scenario.name}',
          style: const TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: 14,
            color: MilstdTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w600,
                color: MilstdTheme.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              onAccept();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MilstdTheme.accentPrimary,
              foregroundColor: MilstdTheme.textInverse,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(MilstdTheme.radiusSm),
              ),
            ),
            child: const Text(
              'ACCEPT',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------



  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MilstdTheme.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  if (onBack != null)
                    GestureDetector(
                      onTap: onBack,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: 20,
                          color: MilstdTheme.accentSecondary,
                        ),
                      ),
                    ),
                  const Expanded(
                    child: Text(
                      'MISSION BRIEFING',
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: MilstdTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Scrollable content — STRICTLY scenario editor fields only
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. SCENARIO NAME + SUBTITLE (editor: s_name, s_subtitle) ---
                    _SectionCard(
                      children: [
                        // Location (editor: s_location)
                        if (scenario.location != null && scenario.location!.isNotEmpty) ...[
                          Text(
                            scenario.location!.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'IBMPlexMono',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: MilstdTheme.textMuted.withValues(alpha: 0.7),
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],

                        // Scenario Name
                        Text(
                          scenario.name.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: MilstdTheme.accentPrimary,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                  color: Color(0x4D00E676),
                                  blurRadius: 8),
                            ],
                          ),
                        ),

                        // Scenario Subtitle (editor: s_subtitle)
                        if (scenario.shortDescription != null &&
                            scenario.shortDescription!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            scenario.shortDescription!,
                            style: const TextStyle(
                              fontFamily: 'IBMPlexSans',
                              fontSize: 13,
                              color: MilstdTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // --- 2. METADATA BADGES (designer: difficulty, play time, author, version) ---
                    if (scenario.difficultyRating != null ||
                        scenario.estimatedPlayTimeMinutes != null ||
                        (scenario.authorName != null && scenario.authorName!.isNotEmpty) ||
                        scenario.versionNumber != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (scenario.difficultyRating != null)
                              _MetaBadge(
                                icon: Icons.signal_cellular_alt,
                                label: scenario.difficultyRating!,
                              ),
                            if (scenario.estimatedPlayTimeMinutes != null)
                              _MetaBadge(
                                icon: Icons.timer_outlined,
                                label: '${scenario.estimatedPlayTimeMinutes} min',
                              ),
                            if (scenario.authorName != null && scenario.authorName!.isNotEmpty)
                              _MetaBadge(
                                icon: Icons.person_outline,
                                label: scenario.authorName!,
                              ),
                            if (scenario.versionNumber != null)
                              _MetaBadge(
                                icon: Icons.tag,
                                label: 'v${scenario.versionNumber}',
                              ),
                          ],
                        ),
                      ),

                    // --- TAGS (designer: tags, comma-separated) ---
                    if (scenario.tags != null && scenario.tags!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: scenario.tags!
                              .replaceAll(RegExp(r'[\[\]\"]'), '')
                              .split(',')
                              .map((tag) {
                            final trimmed = tag.trim();
                            if (trimmed.isEmpty) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: MilstdTheme.textMuted.withValues(alpha: 0.15),
                                borderRadius: const BorderRadius.all(MilstdTheme.radiusXs),
                              ),
                              child: Text(
                                trimmed,
                                style: const TextStyle(
                                  fontFamily: 'IBMPlexMono',
                                  fontSize: 9,
                                  color: MilstdTheme.textSecondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // --- 3. OVERVIEW (designer: overviewText → DB: overview) ---
                    if (scenario.overview != null &&
                        scenario.overview!.isNotEmpty)
                      _SectionCard(
                        children: [
                          const _SectionLabel('OVERVIEW'),
                          const SizedBox(height: 6),
                          Text(
                            scenario.overview!,
                            style: const TextStyle(
                              fontFamily: 'IBMPlexSans',
                              fontSize: 14,
                              color: MilstdTheme.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),

                    if (scenario.overview != null &&
                        scenario.overview!.isNotEmpty)
                      const SizedBox(height: 12),

                    // --- 4. MISSION BRIEFING (designer: missionBriefing → DB: mission_briefing_text) ---
                    if (scenario.missionBriefingText != null &&
                        scenario.missionBriefingText!.isNotEmpty)
                      _SectionCard(
                        children: [
                          const _SectionLabel('MISSION BRIEFING'),
                          const SizedBox(height: 6),
                          Text(
                            scenario.missionBriefingText!,
                            style: const TextStyle(
                              fontFamily: 'IBMPlexSans',
                              fontSize: 14,
                              color: MilstdTheme.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),

                    if (scenario.missionBriefingText != null &&
                        scenario.missionBriefingText!.isNotEmpty)
                      const SizedBox(height: 12),

                    // --- 3. OBJECTIVES (editor: Primary + Secondary) ---
                    if (scenario.primaryObjective != null)
                      _SectionCard(
                        children: [
                          const _SectionLabel('OBJECTIVES'),
                          const SizedBox(height: 8),

                          // Primary Objective
                          _ObjectiveRow(
                            label: 'PRIMARY',
                            text: scenario.primaryObjective!,
                            color: MilstdTheme.accentWarm,
                            icon: Icons.gps_fixed,
                          ),

                          // Primary: target type + count (designer fields)
                          if (scenario.primaryObjectiveTargetType != null) ...[
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 28),
                              child: Text(
                                'Target: ${scenario.primaryObjectiveTargetType}'
                                '${scenario.primaryObjectiveTargetCount != null ? ' x${scenario.primaryObjectiveTargetCount}' : ''}',
                                style: const TextStyle(
                                  fontFamily: 'IBMPlexMono',
                                  fontSize: 10,
                                  color: MilstdTheme.accentWarm,
                                ),
                              ),
                            ),
                          ],

                          // Secondary Objective (if set)
                          if (scenario.secondaryObjective != null &&
                              scenario.secondaryObjective!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _ObjectiveRow(
                              label: 'SECONDARY',
                              text: scenario.secondaryObjective!,
                              color: MilstdTheme.accentSecondary,
                              icon: Icons.flag_outlined,
                            ),

                            // Secondary: target type + count (designer fields)
                            if (scenario.secondaryObjectiveTargetType != null) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 28),
                                child: Text(
                                  'Target: ${scenario.secondaryObjectiveTargetType}'
                                  '${scenario.secondaryObjectiveTargetCount != null ? ' x${scenario.secondaryObjectiveTargetCount}' : ''}',
                                  style: const TextStyle(
                                    fontFamily: 'IBMPlexMono',
                                    fontSize: 10,
                                    color: MilstdTheme.accentSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),

                    if (scenario.primaryObjective != null)
                      const SizedBox(height: 12),

                    // --- 5. INTEL / RULES SECTIONS (designer: threatRules, targetRules, combatRules) ---
                    if ((scenario.threatRules != null && scenario.threatRules!.isNotEmpty) ||
                        (scenario.targetRules != null && scenario.targetRules!.isNotEmpty) ||
                        (scenario.combatRules != null && scenario.combatRules!.isNotEmpty)) ...[
                      _SectionCard(
                        children: [
                          const _SectionLabel('INTEL & OPERATIONAL RULES'),
                          const SizedBox(height: 10),
                          if (scenario.threatRules != null && scenario.threatRules!.isNotEmpty) ...[
                            _IntelRow(label: 'THREAT INTEL', text: scenario.threatRules!, icon: Icons.warning_amber_rounded),
                            const SizedBox(height: 12),
                          ],
                          if (scenario.targetRules != null && scenario.targetRules!.isNotEmpty) ...[
                            _IntelRow(label: 'TARGET INTEL', text: scenario.targetRules!, icon: Icons.gps_fixed),
                            const SizedBox(height: 12),
                          ],
                          if (scenario.combatRules != null && scenario.combatRules!.isNotEmpty) ...[
                            _IntelRow(label: 'COMBAT EVENTS', text: scenario.combatRules!, icon: Icons.event_note),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // --- 6. STARTING CONDITIONS (designer: starting_fuel, starting_damage_*) ---
                    if (scenario.startingFuel != null ||
                        (scenario.startingDamageSens ?? 0) > 0 ||
                        (scenario.startingDamageComms ?? 0) > 0) ...[
                      _SectionCard(
                        children: [
                          const _SectionLabel('STARTING CONDITIONS'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (scenario.startingFuel != null)
                                Expanded(
                                  child: _ConditionStat(
                                    label: 'FUEL',
                                    value: '${scenario.startingFuel}F',
                                    icon: Icons.local_gas_station,
                                  ),
                                ),
                              if ((scenario.startingDamageSens ?? 0) > 0)
                                Expanded(
                                  child: _ConditionStat(
                                    label: 'SEN DMG',
                                    value: '${scenario.startingDamageSens}',
                                    icon: Icons.radar,
                                    isWarning: true,
                                  ),
                                ),
                              if ((scenario.startingDamageComms ?? 0) > 0)
                                Expanded(
                                  child: _ConditionStat(
                                    label: 'COM DMG',
                                    value: '${scenario.startingDamageComms}',
                                    icon: Icons.cell_tower,
                                    isWarning: true,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // --- 7. LOADOUT RULES (designer: loadoutRules) ---
                    if (scenario.loadoutRules != null && scenario.loadoutRules!.isNotEmpty) ...[
                      _SectionCard(
                        children: [
                          const _SectionLabel('LOADOUT RESTRICTIONS'),
                          const SizedBox(height: 6),
                          Text(
                            scenario.loadoutRules!,
                            style: const TextStyle(
                              fontFamily: 'IBMPlexSans',
                              fontSize: 13,
                              color: MilstdTheme.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (scenario.hasActiveModifiers)
                      _SectionCard(
                        children: [
                          const _SectionLabel('GAMEPLAY MODIFIERS'),
                          const SizedBox(height: 8),
                          if ((scenario.modifierFuelCost ?? 0) != 0)
                            _ModifierRow('Fuel Cost', scenario.modifierFuelCost!),
                          if ((scenario.modifierAttackRoll ?? 0) != 0)
                            _ModifierRow('Attack Roll', scenario.modifierAttackRoll!),
                          if ((scenario.modifierEvasion ?? 0) != 0)
                            _ModifierRow('Evasion', scenario.modifierEvasion!),
                          if ((scenario.modifierAltitudeCost ?? 0) != 0)
                            _ModifierRow('Altitude Cost', scenario.modifierAltitudeCost!),
                          if ((scenario.modifierTargetAcquisition ?? 0) != 0)
                            _ModifierRow('Target Acquisition', scenario.modifierTargetAcquisition!),
                          if ((scenario.modifierThreatDetermination ?? 0) != 0)
                            _ModifierRow('Threat Determination', scenario.modifierThreatDetermination!),
                        ],
                      ),

                    if (scenario.hasActiveModifiers)
                      const SizedBox(height: 12),

                    // --- 9. ALLOWED PLATFORMS (designer: scenario_designer_drones) ---
                    if (scenario.allowedDroneNames.isNotEmpty)
                      _SectionCard(
                        children: [
                          const _SectionLabel('ALLOWED PLATFORMS'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: scenario.allowedDroneNames.map((name) =>
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: MilstdTheme.accentPrimary.withValues(alpha: 0.1),
                                  borderRadius: const BorderRadius.all(MilstdTheme.radiusXs),
                                  border: Border.all(
                                    color: MilstdTheme.accentPrimary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  name.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'IBMPlexMono',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: MilstdTheme.accentPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ).toList(),
                          ),
                        ],
                      ),

                    if (scenario.allowedDroneNames.isNotEmpty)
                      const SizedBox(height: 12),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Accept button
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
                child: ElevatedButton.icon(
                  onPressed: () => _confirmAccept(context),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('ACCEPT MISSION'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MilstdTheme.accentPrimary,
                    foregroundColor: MilstdTheme.textInverse,
                    textStyle: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(MilstdTheme.radiusSm),
                    ),
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

// =============================================================================
// Sub-widgets
// =============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MilstdTheme.backgroundSecondary,
        borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
        border: Border.all(color: MilstdTheme.borderDefault, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'IBMPlexSans',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: MilstdTheme.textSecondary,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label, required this.icon, this.color = MilstdTheme.accentSecondary});
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.all(MilstdTheme.radiusXs),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectiveRow extends StatelessWidget {
  const _ObjectiveRow({
    required this.label,
    required this.text,
    required this.color,
    required this.icon,
  });
  final String label;
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.all(MilstdTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'IBMPlexMono',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'IBMPlexSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModifierRow extends StatelessWidget {
  const _ModifierRow(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final isPositive = value > 0;
    final color = isPositive ? MilstdTheme.accentPrimary : MilstdTheme.accentWarm;
    final sign = isPositive ? '+' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'IBMPlexSans',
                fontSize: 12,
                color: MilstdTheme.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.all(MilstdTheme.radiusXs),
            ),
            child: Text(
              '$sign$value',
              style: TextStyle(
                fontFamily: 'IBMPlexMono',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntelRow extends StatelessWidget {
  const _IntelRow({required this.label, required this.text, required this.icon});
  final String label;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: MilstdTheme.accentSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: MilstdTheme.accentSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: 13,
                  color: MilstdTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConditionStat extends StatelessWidget {
  const _ConditionStat({
    required this.label,
    required this.value,
    required this.icon,
    this.isWarning = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? MilstdTheme.statusWarning : MilstdTheme.accentPrimary;
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: MilstdTheme.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

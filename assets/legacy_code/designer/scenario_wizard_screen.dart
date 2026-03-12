import 'package:flutter/material.dart';
import '../../utils/design_system.dart';
import '../../services/database_service.dart';
import '../../services/scenario_designer_service.dart';
import '../../game/models/card_models.dart';

/// 8-step wizard for creating/editing scenarios.
class ScenarioWizardScreen extends StatefulWidget {
  final int? editScenarioId;
  final DesignerScenarioData? importedData;
  const ScenarioWizardScreen({super.key, this.editScenarioId, this.importedData});

  @override
  State<ScenarioWizardScreen> createState() => _ScenarioWizardScreenState();
}

class _ScenarioWizardScreenState extends State<ScenarioWizardScreen> {
  int _step = 0;
  late DesignerScenarioData _data;
  bool _loading = true;
  String _status = '';

  // Cached DB data for selection steps
  List<Map<String, dynamic>> _allDrones = [];
  List<Map<String, dynamic>> _allTargetCards = [];
  List<Map<String, dynamic>> _allThreatCards = [];
  List<Map<String, dynamic>> _allCombatCards = [];
  List<Map<String, dynamic>> _allWeapons = [];
  Map<int, DroneData> _droneDataCache = {};

  static const _stepTitles = [
    'Basic Info',
    'Available Drones',
    'Loadout Restrictions',
    'Target Cards',
    'Threat Cards',
    'Combat Cards',
    'Allowed Weapons',
    'Custom Modifiers',
    'Review & Publish',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Load DB data for selection steps
      _allDrones = await DatabaseService.rawQuery('SELECT id, name, category, country FROM drones ORDER BY name');
      _allTargetCards = await DatabaseService.rawQuery('SELECT id, card_number, card_name, sub_category, vp FROM target_cards ORDER BY sub_category, card_name');
      _allThreatCards = await DatabaseService.rawQuery("SELECT card_number, card_name, sub_category FROM threat_cards ORDER BY sub_category, card_name");
      _allCombatCards = await DatabaseService.rawQuery('SELECT id, card_number, card_name, instruction FROM combat_cards ORDER BY card_name');
      _allWeapons = await DatabaseService.rawQuery('SELECT id, name, wpn_type, description, targets, fire_range, fire_altitude FROM weapons ORDER BY wpn_type, name');

      // Load full DroneData for loadout options
      final allDroneData = await DatabaseService.getAllDrones();
      _droneDataCache = { for (final d in allDroneData) d.id: d };

      if (widget.editScenarioId != null) {
        _data = await ScenarioDesignerService.loadForEdit(widget.editScenarioId!);
      } else if (widget.importedData != null) {
        _data = widget.importedData!;
      } else {
        _data = DesignerScenarioData();
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _save({bool publish = false}) async {
    try {
      setState(() => _status = publish ? 'Publishing...' : 'Saving...');
      final id = await ScenarioDesignerService.saveScenario(_data, publish: publish);
      _data.scenarioId = id;
      setState(() => _status = publish
          ? 'Published! (id=$id)'
          : 'Saved as Draft (id=$id)');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publish
                ? 'Scenario published! Now available in game.'
                : 'Scenario saved as Draft.'),
            backgroundColor: publish ? AppColors.success : AppColors.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  void _next() {
    if (_step < 8) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: const Color(0xFF1A1A2E),
            title: const Text('Loading...', style: TextStyle(color: Colors.amber))),
        body: const Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => _confirmExit(),
        ),
        title: Text(
          'Step ${_step + 1}/9: ${_stepTitles[_step]}',
          style: AppTextStyles.h3.copyWith(color: Colors.amber),
        ),
        actions: [
          TextButton(
            onPressed: () => _save(),
            child: const Text('SAVE DRAFT', style: TextStyle(color: Colors.amber, fontSize: 14)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          _progressBar(),
          // Status
          if (_status.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: const Color(0xFF0A0A14),
              child: Text('> $_status',
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.greenAccent)),
            ),
          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStep(),
            ),
          ),
          // Navigation
          _navBar(),
        ],
      ),
    );
  }

  Widget _progressBar() {
    return Container(
      height: 4,
      color: AppColors.surface,
      child: Row(
        children: List.generate(9, (i) {
          return Expanded(
            child: Container(
              color: i <= _step ? Colors.amber : Colors.transparent,
            ),
          );
        }),
      ),
    );
  }

  Widget _navBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.surfaceElevated,
      child: Row(
        children: [
          if (_step > 0)
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back, size: 14),
              label: const Text('BACK'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.surfaceBorder),
              ),
              onPressed: _back,
            ),
          const Spacer(),
          if (_step < 8)
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: const Text('NEXT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              onPressed: _next,
            ),
          if (_step == 8) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber,
                side: const BorderSide(color: Colors.amber),
              ),
              onPressed: () => _save(),
              child: const Text('SAVE DRAFT'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.publish, size: 14),
              label: const Text('PUBLISH'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final errors = ScenarioDesignerService.validate(_data);
                if (errors.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surfaceElevated,
                      title: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 22),
                          const SizedBox(width: 8),
                          Text('Cannot Publish', style: AppTextStyles.h3.copyWith(color: AppColors.danger)),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Please fix the following issues:', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 12),
                          ...errors.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(color: AppColors.danger, fontSize: 14)),
                                Expanded(child: Text(e.message, style: AppTextStyles.body)),
                              ],
                            ),
                          )),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('OK', style: TextStyle(color: Colors.amber)),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                _save(publish: true);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildBasicInfo();
      case 1: return _buildDrones();
      case 2: return _buildLoadoutRestrictions();
      case 3: return _buildCards('Target', _allTargetCards, _data.targetCards, isTarget: true);
      case 4: return _buildCards('Threat', _allThreatCards, null, isThreat: true);
      case 5: return _buildCards('Combat', _allCombatCards, _data.combatCards);
      case 6: return _buildWeapons();
      case 7: return _buildModifiers();
      case 8: return _buildReview();
      default: return const SizedBox.shrink();
    }
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Discard changes?', style: AppTextStyles.h3.copyWith(color: AppColors.warning)),
        content: const Text('Any unsaved changes will be lost.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('DISCARD', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 1: BASIC INFO
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textField('Scenario Title *', _data.title, (v) => _data.title = v, maxLen: 100),
        _textField('Short Description *', _data.shortDescription, (v) => _data.shortDescription = v, maxLen: 200),
        _textField('Overview Text *', _data.overviewText, (v) => _data.overviewText = v, maxLen: 1000, lines: 4),
        const SizedBox(height: 8),
        Text("COMMANDER'S INTENT", style: AppTextStyles.label),
        const SizedBox(height: 8),
        _textField('Mission Briefing *', _data.missionBriefing, (v) => _data.missionBriefing = v, maxLen: 1000, lines: 3),
        _textField('Primary Objective *', _data.primaryObjective, (v) => _data.primaryObjective = v, maxLen: 500, lines: 2),

        // Primary condition
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PRIMARY CONDITION (combine freely — all must be met)', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.danger)),
              const SizedBox(height: 4),
              Text('Leave all blank for narrative-only. Conditions are AND-ed together.', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _textField(
                      'Destroy card (exact name)',
                      _data.primaryObjectiveCardName ?? '',
                      (v) => setState(() => _data.primaryObjectiveCardName = v.trim().isEmpty ? null : v.trim()),
                      maxLen: 100,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _textField(
                      'Min VP',
                      _data.primaryObjectiveVpThreshold?.toString() ?? '',
                      (v) => setState(() => _data.primaryObjectiveVpThreshold = int.tryParse(v)),
                      number: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _objectiveTypeDropdown(
                      value: _data.primaryObjectiveTargetType,
                      onChanged: (v) => setState(() => _data.primaryObjectiveTargetType = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _textField(
                      'Min count',
                      _data.primaryObjectiveTargetCount?.toString() ?? '',
                      (v) => setState(() => _data.primaryObjectiveTargetCount = int.tryParse(v)),
                      number: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        _textField('Secondary Objective', _data.secondaryObjective, (v) => _data.secondaryObjective = v, maxLen: 500, lines: 2),

        // Secondary condition
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SECONDARY CONDITION (combine freely — all must be met)', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.info)),
              const SizedBox(height: 4),
              Text('Leave all blank for narrative-only. Conditions are AND-ed together.', style: AppTextStyles.caption),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _textField(
                      'Destroy card (exact name)',
                      _data.secondaryObjectiveCardName ?? '',
                      (v) => setState(() => _data.secondaryObjectiveCardName = v.trim().isEmpty ? null : v.trim()),
                      maxLen: 100,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _textField(
                      'Min VP',
                      _data.secondaryObjectiveVpThreshold?.toString() ?? '',
                      (v) => setState(() => _data.secondaryObjectiveVpThreshold = int.tryParse(v)),
                      number: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _textField(
                      'Bonus VP',
                      _data.secondaryObjectiveVpBonus > 0 ? _data.secondaryObjectiveVpBonus.toStringAsFixed(1) : '',
                      (v) => setState(() => _data.secondaryObjectiveVpBonus = double.tryParse(v) ?? 0.0),
                      number: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _objectiveTypeDropdown(
                      value: _data.secondaryObjectiveTargetType,
                      onChanged: (v) => setState(() => _data.secondaryObjectiveTargetType = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _textField(
                      'Min count',
                      _data.secondaryObjectiveTargetCount?.toString() ?? '',
                      (v) => setState(() => _data.secondaryObjectiveTargetCount = int.tryParse(v)),
                      number: true,
                    ),
                  ),
                  const SizedBox(width: 8 + 8 + (2 * 40)), // spacer to match Bonus VP above
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Difficulty & Play Time row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DIFFICULTY *', style: AppTextStyles.label.copyWith(fontSize: 10)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: DropdownButton<String>(
                      value: const ['Easy', 'Medium', 'Hard', 'Expert'].contains(_data.difficultyRating)
                          ? _data.difficultyRating
                          : 'Medium',
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceElevated,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      items: ['Easy', 'Medium', 'Hard', 'Expert']
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (v) => setState(() => _data.difficultyRating = v ?? 'Medium'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _textField(
                'Play Time (min) *',
                _data.estimatedPlayTimeMinutes.toString(),
                (v) => _data.estimatedPlayTimeMinutes = int.tryParse(v) ?? 30,
                number: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Tags
        Text('TAGS', style: AppTextStyles.label.copyWith(fontSize: 10)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: ['Desert', 'Urban', 'Naval', 'Mountain', 'Arctic', 'Jungle', 'Historical', 'Training']
              .map((tag) {
            final selected = _data.tags.contains(tag);
            return FilterChip(
              label: Text(tag, style: TextStyle(fontSize: 11, color: selected ? Colors.black : AppColors.textSecondary)),
              selected: selected,
              selectedColor: Colors.amber,
              backgroundColor: AppColors.surface,
              checkmarkColor: Colors.black,
              side: BorderSide(color: selected ? Colors.amber : AppColors.surfaceBorder),
              onSelected: (val) {
                setState(() {
                  if (val) { _data.tags = [..._data.tags, tag]; }
                  else { _data.tags = _data.tags.where((t) => t != tag).toList(); }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _textField('Author Name *', _data.authorName, (v) => _data.authorName = v, maxLen: 50),
        _textField('Designer Notes (internal)', _data.designerNotes, (v) => _data.designerNotes = v, maxLen: 2000, lines: 3),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 2: DRONES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDrones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${_data.selectedDroneIds.length} of ${_allDrones.length} drones selected',
                style: AppTextStyles.body.copyWith(color: Colors.amber)),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _data.selectedDroneIds = _allDrones.map((d) => d['id'] as int).toSet()),
              child: const Text('SELECT ALL', style: TextStyle(color: Colors.amber, fontSize: 14)),
            ),
            TextButton(
              onPressed: () => setState(() => _data.selectedDroneIds = {}),
              child: const Text('DESELECT ALL', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ),
          ],
        ),
        if (_data.selectedDroneIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Must select at least 1 drone', style: TextStyle(color: AppColors.danger, fontSize: 12)),
          ),
        const SizedBox(height: 8),
        ..._allDrones.map((d) {
          final id = d['id'] as int;
          final selected = _data.selectedDroneIds.contains(id);
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: selected ? Colors.amber.withValues(alpha: 0.08) : AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: selected ? Colors.amber.withValues(alpha: 0.4) : AppColors.surfaceBorder),
            ),
            child: CheckboxListTile(
              dense: true,
              value: selected,
              activeColor: Colors.amber,
              checkColor: Colors.black,
              title: Text(d['name'] as String,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'Courier')),
              subtitle: Text('${d['category'] ?? '-'} • ${d['country'] ?? '-'}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              onChanged: (val) {
                setState(() {
                  if (val == true) { _data.selectedDroneIds.add(id); }
                  else { _data.selectedDroneIds.remove(id); }
                });
              },
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 3: LOADOUT RESTRICTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoadoutRestrictions() {
    final selectedDrones = _data.selectedDroneIds
        .where((id) => _droneDataCache.containsKey(id))
        .map((id) => _droneDataCache[id]!)
        .toList();

    if (selectedDrones.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber, color: Colors.amber, size: 40),
            const SizedBox(height: 12),
            Text('No drones selected yet.', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('← Go back to Drone Selection', style: TextStyle(color: Colors.amber, fontSize: 14)),
            ),
          ],
        ),
      );
    }

    int totalExcluded = _data.excludedLoadouts.values.fold(0, (a, s) => a + s.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Restrict which loadout presets are available to each drone in this scenario.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 4),
        Text('All presets allowed by default. Toggle OFF to exclude.',
            style: AppTextStyles.caption.copyWith(fontSize: 12)),
        if (totalExcluded > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('$totalExcluded preset(s) currently excluded',
                style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 16),
        ...selectedDrones.map((drone) {
          final options = drone.loadoutOptions;
          if (options.isEmpty) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flight, color: Colors.cyan, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(drone.name, style: AppTextStyles.body.copyWith(fontFamily: 'Courier', fontSize: 14)),
                  ),
                  Text('No loadout presets', style: AppTextStyles.caption),
                ],
              ),
            );
          }

          final excludedSet = _data.excludedLoadouts[drone.id] ?? <int>{};

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drone header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flight, color: Colors.cyan, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(drone.name,
                            style: AppTextStyles.body.copyWith(fontFamily: 'Courier', fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                      Text('${drone.category ?? ""} · ${drone.country ?? ""}',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                // Loadout options
                ...options.map((opt) {
                  final isExcluded = excludedSet.contains(opt.optionIndex);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.surfaceBorder.withValues(alpha: 0.3))),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36,
                          child: Text('OPT ${opt.optionIndex}',
                              style: TextStyle(
                                color: isExcluded ? AppColors.textSecondary : Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                        Expanded(
                          child: Text(
                            opt.label,
                            style: TextStyle(
                              color: isExcluded ? AppColors.textSecondary : AppColors.textPrimary,
                              fontSize: 13,
                              fontFamily: 'Courier',
                              decoration: isExcluded ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        Switch(
                          value: !isExcluded,
                          activeThumbColor: Colors.amber,
                          onChanged: (allowed) {
                            setState(() {
                              if (!allowed) {
                                _data.excludedLoadouts
                                    .putIfAbsent(drone.id, () => <int>{})
                                    .add(opt.optionIndex);
                              } else {
                                _data.excludedLoadouts[drone.id]?.remove(opt.optionIndex);
                                if (_data.excludedLoadouts[drone.id]?.isEmpty ?? false) {
                                  _data.excludedLoadouts.remove(drone.id);
                                }
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEPS 4-6: CARD SELECTION (Shared)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCards(String type, List<Map<String, dynamic>> cards, Map<int, int>? intMap,
      {bool isTarget = false, bool isThreat = false}) {
    // Group by sub_category for target/threat cards
    final categories = <String>{};
    for (final c in cards) {
      categories.add(c['sub_category'] as String? ?? 'Other');
    }

    int total;
    if (isThreat) {
      total = _data.totalThreatCards;
    } else if (isTarget) {
      total = _data.totalTargetCards;
    } else {
      total = _data.totalCombatCards;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Counter
        Row(
          children: [
            Text('Total $type Cards: ', style: AppTextStyles.body),
            Text('$total', style: AppTextStyles.body.copyWith(
                color: total < 5 ? AppColors.danger : total > 100 ? AppColors.danger : Colors.amber,
                fontWeight: FontWeight.bold)),
            Text(' / 100 max', style: AppTextStyles.small),
          ],
        ),
        if (total < 5)
          Text('Must have at least 5 $type cards', style: TextStyle(color: AppColors.danger, fontSize: 14)),
        const SizedBox(height: 12),

        if (categories.length > 1)
          // Tabbed view for target/threat
          ..._buildGroupedCards(cards, categories, isThreat: isThreat, isTarget: isTarget)
        else ...[
          // Select All row for flat list
          _buildSelectAllRow(cards, isThreat: isThreat, isTarget: isTarget),
          const SizedBox(height: 8),
          // Flat list for combat
          ..._buildCardList(cards, isThreat: isThreat, isTarget: isTarget),
        ],
      ],
    );
  }

  List<Widget> _buildGroupedCards(List<Map<String, dynamic>> cards, Set<String> categories,
      {bool isThreat = false, bool isTarget = false}) {
    return categories.map((cat) {
      final catCards = cards.where((c) => (c['sub_category'] as String? ?? 'Other') == cat).toList();

      // Check if all cards in this category are selected
      final allSelected = catCards.every((c) {
        if (isThreat) return _data.threatCards.containsKey(c['card_number'] as String);
        return isTarget
            ? _data.targetCards.containsKey(c['id'] as int)
            : _data.combatCards.containsKey(c['id'] as int);
      });

      return ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        collapsedIconColor: AppColors.textSecondary,
        iconColor: Colors.amber,
        title: Row(
          children: [
            Expanded(
              child: Text(cat.toUpperCase(),
                  style: AppTextStyles.label.copyWith(color: Colors.amber, fontSize: 11)),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (allSelected) {
                    // Deselect all in this category
                    for (final c in catCards) {
                      if (isThreat) {
                        _data.threatCards.remove(c['card_number'] as String);
                      } else if (isTarget) {
                        _data.targetCards.remove(c['id'] as int);
                      } else {
                        _data.combatCards.remove(c['id'] as int);
                      }
                    }
                  } else {
                    // Select all in this category (qty = 1)
                    for (final c in catCards) {
                      if (isThreat) {
                        final key = c['card_number'] as String;
                        if (!_data.threatCards.containsKey(key)) _data.threatCards[key] = 1;
                      } else if (isTarget) {
                        final id = c['id'] as int;
                        if (!_data.targetCards.containsKey(id)) _data.targetCards[id] = 1;
                      } else {
                        final id = c['id'] as int;
                        if (!_data.combatCards.containsKey(id)) _data.combatCards[id] = 1;
                      }
                    }
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: allSelected
                      ? Colors.amber.withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: allSelected ? Colors.amber.withValues(alpha: 0.5) : AppColors.surfaceBorder,
                  ),
                ),
                child: Text(
                  allSelected ? 'DESELECT ALL' : 'SELECT ALL',
                  style: TextStyle(
                    color: allSelected ? Colors.amber : AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        subtitle: Text('${catCards.length} cards', style: AppTextStyles.caption),
        children: _buildCardList(catCards, isThreat: isThreat, isTarget: isTarget),
      );
    }).toList();
  }

  Widget _buildSelectAllRow(List<Map<String, dynamic>> cards,
      {bool isThreat = false, bool isTarget = false}) {
    final allSelected = cards.every((c) {
      if (isThreat) return _data.threatCards.containsKey(c['card_number'] as String);
      return isTarget
          ? _data.targetCards.containsKey(c['id'] as int)
          : _data.combatCards.containsKey(c['id'] as int);
    });

    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (allSelected) {
              for (final c in cards) {
                if (isThreat) {
                  _data.threatCards.remove(c['card_number'] as String);
                } else if (isTarget) {
                  _data.targetCards.remove(c['id'] as int);
                } else {
                  _data.combatCards.remove(c['id'] as int);
                }
              }
            } else {
              for (final c in cards) {
                if (isThreat) {
                  final key = c['card_number'] as String;
                  if (!_data.threatCards.containsKey(key)) _data.threatCards[key] = 1;
                } else if (isTarget) {
                  final id = c['id'] as int;
                  if (!_data.targetCards.containsKey(id)) _data.targetCards[id] = 1;
                } else {
                  final id = c['id'] as int;
                  if (!_data.combatCards.containsKey(id)) _data.combatCards[id] = 1;
                }
              }
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: allSelected
                ? Colors.amber.withValues(alpha: 0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: allSelected ? Colors.amber.withValues(alpha: 0.5) : AppColors.surfaceBorder,
            ),
          ),
          child: Text(
            allSelected ? 'DESELECT ALL' : 'SELECT ALL',
            style: TextStyle(
              color: allSelected ? Colors.amber : AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCardList(List<Map<String, dynamic>> cards,
      {bool isThreat = false, bool isTarget = false}) {
    return cards.map((c) {
      final String cardKey;
      final bool selected;
      final int qty;

      if (isThreat) {
        cardKey = c['card_number'] as String;
        selected = _data.threatCards.containsKey(cardKey);
        qty = _data.threatCards[cardKey] ?? 1;
      } else if (isTarget) {
        final id = c['id'] as int;
        cardKey = id.toString();
        selected = _data.targetCards.containsKey(id);
        qty = _data.targetCards[id] ?? 1;
      } else {
        final id = c['id'] as int;
        cardKey = id.toString();
        selected = _data.combatCards.containsKey(id);
        qty = _data.combatCards[id] ?? 1;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.amber.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? Colors.amber.withValues(alpha: 0.3) : AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: selected,
                activeColor: Colors.amber,
                checkColor: Colors.black,
                onChanged: (val) {
                  setState(() {
                    if (isThreat) {
                      final key = c['card_number'] as String;
                      if (val == true) { _data.threatCards[key] = 1; }
                      else { _data.threatCards.remove(key); }
                    } else if (isTarget) {
                      final id = c['id'] as int;
                      if (val == true) { _data.targetCards[id] = 1; }
                      else { _data.targetCards.remove(id); }
                    } else {
                      final id = c['id'] as int;
                      if (val == true) { _data.combatCards[id] = 1; }
                      else { _data.combatCards.remove(id); }
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['card_name'] as String? ?? '-',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontFamily: 'Courier')),
                  if (isTarget && c['vp'] != null)
                    Text('VP: ${c['vp']}', style: AppTextStyles.caption),
                  if (!isTarget && !isThreat && c['instruction'] != null)
                    Text(c['instruction'] as String, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Quantity spinner
            if (selected) ...[
              _spinnerBtn(Icons.remove, () {
                setState(() {
                  if (isThreat) {
                    final key = c['card_number'] as String;
                    final cur = _data.threatCards[key] ?? 1;
                    if (cur > 1) _data.threatCards[key] = cur - 1;
                  } else if (isTarget) {
                    final id = c['id'] as int;
                    final cur = _data.targetCards[id] ?? 1;
                    if (cur > 1) _data.targetCards[id] = cur - 1;
                  } else {
                    final id = c['id'] as int;
                    final cur = _data.combatCards[id] ?? 1;
                    if (cur > 1) _data.combatCards[id] = cur - 1;
                  }
                });
              }),
              Container(
                width: 28,
                alignment: Alignment.center,
                child: Text('$qty', style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              _spinnerBtn(Icons.add, () {
                setState(() {
                  if (isThreat) {
                    final key = c['card_number'] as String;
                    _data.threatCards[key] = (_data.threatCards[key] ?? 1) + 1;
                  } else if (isTarget) {
                    final id = c['id'] as int;
                    _data.targetCards[id] = (_data.targetCards[id] ?? 1) + 1;
                  } else {
                    final id = c['id'] as int;
                    _data.combatCards[id] = (_data.combatCards[id] ?? 1) + 1;
                  }
                });
              }),
            ],
          ],
        ),
      );
    }).toList();
  }

  Widget _spinnerBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Icon(icon, size: 20, color: Colors.amber),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 7: ALLOWED WEAPONS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWeapons() {
    // ── Collect weapon names from selected drones ──
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadDroneWeapons(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final availableWeapons = snapshot.data!;
        if (availableWeapons.isEmpty && _data.selectedDroneIds.isNotEmpty) {
          return Center(
            child: Text('No weapons found for the selected drones.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          );
        }

        // Group by type
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final w in availableWeapons) {
          final type = (w['wpn_type'] as String?) ?? 'Other';
          grouped.putIfAbsent(type, () => []).add(w);
        }
        final types = grouped.keys.toList()..sort();
        final allIds = availableWeapons.map((w) => w['id'] as int).toSet();
        final noneSelected = _data.weaponQuantities.isEmpty;
        final totalQty = _data.weaponQuantities.values.fold(0, (a, b) => a + b);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      noneSelected
                          ? 'No weapons selected = ALL weapons allowed (default)'
                          : '${_data.weaponQuantities.length} weapons, $totalQty total quantity',
                      style: AppTextStyles.small.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            if (_data.selectedDroneIds.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No drones selected — showing ALL weapons. Select drones first to filter.',
                          style: AppTextStyles.small.copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Global buttons
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    for (final id in allIds) {
                      _data.weaponQuantities.putIfAbsent(id, () => 1);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: !noneSelected && _data.weaponQuantities.length == allIds.length
                          ? Colors.amber.withValues(alpha: 0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: !noneSelected && _data.weaponQuantities.length == allIds.length
                            ? Colors.amber.withValues(alpha: 0.5)
                            : AppColors.surfaceBorder,
                      ),
                    ),
                    child: Text('SELECT ALL', style: TextStyle(
                      color: !noneSelected && _data.weaponQuantities.length == allIds.length
                          ? Colors.amber
                          : AppColors.textSecondary,
                      fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5,
                    )),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _data.weaponQuantities.clear()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: noneSelected ? Colors.amber.withValues(alpha: 0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: noneSelected ? Colors.amber.withValues(alpha: 0.5) : AppColors.surfaceBorder,
                      ),
                    ),
                    child: Text('DESELECT ALL (No Restriction)', style: TextStyle(
                      color: noneSelected ? Colors.amber : AppColors.textSecondary,
                      fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5,
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Grouped weapons with quantity
            ...types.map((type) {
              final weapons = grouped[type]!;
              final typeIds = weapons.map((w) => w['id'] as int).toSet();
              final allTypeSelected = typeIds.every((id) => _data.weaponQuantities.containsKey(id));

              return ExpansionTile(
                initiallyExpanded: true,
                tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Row(
                  children: [
                    Text(type, style: AppTextStyles.label),
                    const SizedBox(width: 8),
                    Text('(${weapons.length})', style: AppTextStyles.caption),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() {
                        if (allTypeSelected) {
                          for (final id in typeIds) {
                            _data.weaponQuantities.remove(id);
                          }
                        } else {
                          for (final id in typeIds) {
                            _data.weaponQuantities.putIfAbsent(id, () => 1);
                          }
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: allTypeSelected ? Colors.amber.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: allTypeSelected ? Colors.amber.withValues(alpha: 0.5) : AppColors.surfaceBorder,
                          ),
                        ),
                        child: Text(
                          allTypeSelected ? 'DESELECT ALL' : 'SELECT ALL',
                          style: TextStyle(
                            color: allTypeSelected ? Colors.amber : AppColors.textSecondary,
                            fontSize: 9, fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                children: weapons.map((w) {
                  final id = w['id'] as int;
                  final name = w['name'] as String;
                  final desc = w['description'] as String? ?? '';
                  final targets = w['targets'] as String? ?? '';
                  final selected = _data.weaponQuantities.containsKey(id);
                  final qty = _data.weaponQuantities[id] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Row(
                      children: [
                        // Checkbox
                        SizedBox(
                          width: 32,
                          child: Checkbox(
                            value: selected,
                            activeColor: Colors.amber,
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _data.weaponQuantities[id] = 1;
                              } else {
                                _data.weaponQuantities.remove(id);
                              }
                            }),
                          ),
                        ),
                        // Name + description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.amber : AppColors.textPrimary,
                              )),
                              if (targets.isNotEmpty || desc.isNotEmpty)
                                Text(
                                  [if (targets.isNotEmpty) 'Targets: $targets', if (desc.isNotEmpty) desc]
                                      .join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption,
                                ),
                            ],
                          ),
                        ),
                        // Quantity controls
                        if (selected) ...[
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: qty > 1 ? () => setState(() {
                                    _data.weaponQuantities[id] = qty - 1;
                                  }) : null,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(Icons.remove, size: 16,
                                      color: qty > 1 ? AppColors.textPrimary : AppColors.textDisabled),
                                  ),
                                ),
                                Container(
                                  width: 28,
                                  alignment: Alignment.center,
                                  child: Text('$qty', style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 13, fontWeight: FontWeight.bold,
                                  )),
                                ),
                                InkWell(
                                  onTap: () => setState(() {
                                    _data.weaponQuantities[id] = qty + 1;
                                  }),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.add, size: 16, color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        );
      },
    );
  }

  /// Load weapons available for the selected drones.
  /// If no drones selected, return all weapons.
  Future<List<Map<String, dynamic>>> _loadDroneWeapons() async {
    if (_data.selectedDroneIds.isEmpty) {
      return _allWeapons;
    }
    final droneIds = _data.selectedDroneIds.toList();
    final placeholders = droneIds.map((_) => '?').join(',');
    final droneRows = await DatabaseService.rawQuery(
      'SELECT opt1_wpn1_name, opt1_wpn2_name, opt2_wpn1_name, opt2_wpn2_name, opt3_wpn1_name, opt3_wpn2_name FROM drones WHERE id IN ($placeholders)',
      droneIds,
    );
    final weaponNames = <String>{};
    for (final row in droneRows) {
      for (final col in ['opt1_wpn1_name', 'opt1_wpn2_name', 'opt2_wpn1_name', 'opt2_wpn2_name', 'opt3_wpn1_name', 'opt3_wpn2_name']) {
        final name = row[col] as String?;
        if (name != null && name.isNotEmpty) weaponNames.add(name);
      }
    }
    if (weaponNames.isEmpty) return [];
    return _allWeapons.where((w) => weaponNames.contains(w['name'] as String)).toList();
  }




  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 8: MODIFIERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildModifiers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('CUSTOM MODIFIERS', style: AppTextStyles.label),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() {
                _data.modifierFuelCost = 0;
                _data.modifierAttackRoll = 0;
                _data.modifierEvasion = 0;
                _data.modifierAltitudeCost = 0;
                _data.modifierTargetAcquisition = 0;
                _data.modifierThreatDetermination = 0;
              }),
              child: const Text('RESET ALL', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ),
          ],
        ),
        Text('These modifiers apply to ALL missions in this scenario.',
            style: AppTextStyles.small),
        const SizedBox(height: 16),
        _modifierRow('Fuel Cost Modifier', _data.modifierFuelCost,
            (v) => setState(() => _data.modifierFuelCost = v),
            help: 'Adjust fuel cost for all drone actions', min: -5, max: 5),
        _modifierRow('Attack Roll Modifier', _data.modifierAttackRoll,
            (v) => setState(() => _data.modifierAttackRoll = v),
            help: 'Adjust all attack rolls (positive = easier hits)', min: -5, max: 5),
        _modifierRow('Evasion/Counterfire', _data.modifierEvasion,
            (v) => setState(() => _data.modifierEvasion = v),
            help: 'Adjust enemy counterfire effectiveness', min: -5, max: 5),
        _modifierRow('Altitude Change Cost', _data.modifierAltitudeCost,
            (v) => setState(() => _data.modifierAltitudeCost = v),
            help: 'Adjust fuel cost to change altitude', min: -5, max: 5),
        _modifierRow('Target Acquisition DRM', _data.modifierTargetAcquisition,
            (v) => setState(() => _data.modifierTargetAcquisition = v),
            help: 'Adjust target acquisition DRM', min: -50, max: 50, step: 10),
        _modifierRow('Threat Determination DRM', _data.modifierThreatDetermination,
            (v) => setState(() => _data.modifierThreatDetermination = v),
            help: 'Adjust threat determination DRM', min: -50, max: 50, step: 10),
      ],
    );
  }

  Widget _modifierRow(String label, int value, ValueChanged<int> onChanged,
      {String? help, int min = -5, int max = 5, int step = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: value != 0 ? Colors.amber.withValues(alpha: 0.4) : AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.body.copyWith(fontSize: 16)),
                if (help != null) Text(help, style: AppTextStyles.caption),
              ],
            ),
          ),
          _spinnerBtn(Icons.remove, () {
            if (value > min) onChanged(value - step);
          }),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              value >= 0 ? '+$value' : '$value',
              style: TextStyle(
                color: value == 0 ? AppColors.textSecondary : (value > 0 ? AppColors.success : AppColors.danger),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
              ),
            ),
          ),
          _spinnerBtn(Icons.add, () {
            if (value < max) onChanged(value + step);
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 8: REVIEW & PUBLISH
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildReview() {
    final errors = ScenarioDesignerService.validate(_data);
    final isValid = errors.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Validation status
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isValid ? AppColors.success.withValues(alpha: 0.1) : AppColors.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isValid ? AppColors.success.withValues(alpha: 0.4) : AppColors.danger.withValues(alpha: 0.4)),
          ),
          child: isValid
              ? Row(children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Text('All validation passed — ready to publish!', style: TextStyle(color: AppColors.success, fontSize: 16)),
                ])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.error, color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Text('${errors.length} validation error(s)', style: TextStyle(color: AppColors.danger, fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 4),
                    ...errors.map((e) => Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text('• ${e.message}', style: TextStyle(color: AppColors.danger, fontSize: 14)),
                    )),
                  ],
                ),
        ),
        const SizedBox(height: 16),

        // Basic Info Summary
        _reviewSection('BASIC INFO', [
          _reviewField('Title', _data.title),
          _reviewField('Short Description', _data.shortDescription),
          _reviewField('Difficulty', _data.difficultyRating),
          _reviewField('Play Time', '${_data.estimatedPlayTimeMinutes} min'),
          if (_data.tags.isNotEmpty) _reviewField('Tags', _data.tags.join(', ')),
          _reviewField('Author', _data.authorName),
        ], editStep: 0),

        _reviewSection('MISSION', [
          _reviewField('Overview', _data.overviewText),
          _reviewField('Briefing', _data.missionBriefing),
          _reviewField('Primary Objective', _data.primaryObjective),
          if (_data.secondaryObjective.isNotEmpty) _reviewField('Secondary Objective', _data.secondaryObjective),
        ], editStep: 0),

        _reviewSection('DRONES', [
          _reviewField('Selected', '${_data.selectedDroneIds.length} drones'),
        ], editStep: 1),

        if (_data.excludedLoadouts.isNotEmpty)
          _reviewSection('LOADOUT RESTRICTIONS', [
            _reviewField('Excluded', '${_data.excludedLoadouts.values.fold(0, (a, s) => a + s.length)} preset(s) restricted'),
          ], editStep: 2),

        _reviewSection('CARDS', [
          _reviewField('Target Cards', '${_data.totalTargetCards} total (${_data.targetCards.length} types)'),
          _reviewField('Threat Cards', '${_data.totalThreatCards} total (${_data.threatCards.length} types)'),
          _reviewField('Combat Cards', '${_data.totalCombatCards} total (${_data.combatCards.length} types)'),
        ], editStep: 3),

        if (_data.weaponQuantities.isNotEmpty)
          _reviewSection('WEAPON RESTRICTIONS', [
            _reviewField('Allowed Weapons', '${_data.weaponQuantities.length} weapons, ${_data.weaponQuantities.values.fold(0, (a, b) => a + b)} total qty'),
          ], editStep: 6),

        // Only show non-zero modifiers
        if (_data.modifierFuelCost != 0 || _data.modifierAttackRoll != 0 ||
            _data.modifierEvasion != 0 || _data.modifierAltitudeCost != 0 ||
            _data.modifierTargetAcquisition != 0 || _data.modifierThreatDetermination != 0)
          _reviewSection('MODIFIERS', [
            if (_data.modifierFuelCost != 0) _reviewField('Fuel Cost', '${_data.modifierFuelCost > 0 ? "+" : ""}${_data.modifierFuelCost}'),
            if (_data.modifierAttackRoll != 0) _reviewField('Attack Roll', '${_data.modifierAttackRoll > 0 ? "+" : ""}${_data.modifierAttackRoll}'),
            if (_data.modifierEvasion != 0) _reviewField('Evasion', '${_data.modifierEvasion > 0 ? "+" : ""}${_data.modifierEvasion}'),
            if (_data.modifierAltitudeCost != 0) _reviewField('Altitude Cost', '${_data.modifierAltitudeCost > 0 ? "+" : ""}${_data.modifierAltitudeCost}'),
            if (_data.modifierTargetAcquisition != 0) _reviewField('Target Acq DRM', '${_data.modifierTargetAcquisition > 0 ? "+" : ""}${_data.modifierTargetAcquisition}'),
            if (_data.modifierThreatDetermination != 0) _reviewField('Threat Det DRM', '${_data.modifierThreatDetermination > 0 ? "+" : ""}${_data.modifierThreatDetermination}'),
          ], editStep: 7),

        if (_data.designerNotes.isNotEmpty)
          _reviewSection('DESIGNER NOTES', [
            _reviewField('Notes', _data.designerNotes),
          ], editStep: 0),
      ],
    );
  }

  Widget _reviewSection(String title, List<Widget> fields, {required int editStep}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTextStyles.label.copyWith(fontSize: 14)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _step = editStep),
                child: const Text('EDIT', style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...fields,
        ],
      ),
    );
  }

  Widget _reviewField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static const _targetTypes = [
    'TANK', 'AFV', 'ARTILLERY', 'SAM', 'ADA', 'HQ', 'SUPPLY NODE',
    'BRIDGE', 'AIRFIELD', 'PERSONNEL', 'TRUCK', 'AIR',
  ];

  Widget _objectiveTypeDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = value != null && _targetTypes.contains(value.toUpperCase())
        ? value.toUpperCase()
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: DropdownButton<String?>(
          value: safeValue,
          hint: Text('Target type (optional)',
              style: AppTextStyles.label.copyWith(fontSize: 12, color: Colors.amber.withValues(alpha: 0.7))),
          isExpanded: true,
          dropdownColor: AppColors.surfaceElevated,
          underline: const SizedBox.shrink(),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'Courier'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('— None —', style: TextStyle(color: AppColors.textSecondary))),
            ..._targetTypes.map((t) => DropdownMenuItem<String?>(value: t, child: Text(t))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _textField(String label, String initialValue, ValueChanged<String> onChanged,
      {int maxLen = 100, int lines = 1, bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        initialValue: initialValue,
        maxLines: lines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontFamily: 'Courier'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.label.copyWith(fontSize: 13, color: Colors.amber),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.surfaceBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.amber),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          counterText: number ? '' : '${initialValue.length}/$maxLen',
          counterStyle: AppTextStyles.caption,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../utils/design_system.dart';
import '../../services/database_service.dart';

/// Full editor screen for a single drone's DB fields.
class DroneEditorScreen extends StatefulWidget {
  final int droneId;
  const DroneEditorScreen({super.key, required this.droneId});

  @override
  State<DroneEditorScreen> createState() => _DroneEditorScreenState();
}

class _DroneEditorScreenState extends State<DroneEditorScreen> {
  bool _loading = true;
  Map<String, dynamic> _row = {};

  // Identity
  final _nameC = TextEditingController();
  final _categoryC = TextEditingController();
  final _countryC = TextEditingController();
  final _classC = TextEditingController();

  // Stats
  final _stationsC = TextEditingController();
  final _maxPayloadC = TextEditingController();
  final _stationWeightC = TextEditingController();
  final _altitudeC = TextEditingController();
  final _rangeC = TextEditingController();
  final _maxSiC = TextEditingController();

  // Capabilities (booleans stored as checkboxes)
  bool _foLaze = true;
  bool _aeasaRadar = false;
  bool _satcom = false;
  bool _commsRedundancy = false;
  bool _autonomousAi = false;

  // Loadout options
  final _o1w1Name = TextEditingController();
  final _o1w1Qty = TextEditingController();
  final _o1w2Name = TextEditingController();
  final _o1w2Qty = TextEditingController();
  final _o2w1Name = TextEditingController();
  final _o2w1Qty = TextEditingController();
  final _o2w2Name = TextEditingController();
  final _o2w2Qty = TextEditingController();
  final _o3w1Name = TextEditingController();
  final _o3w1Qty = TextEditingController();
  final _o3w2Name = TextEditingController();
  final _o3w2Qty = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await DatabaseService.rawQuery(
        'SELECT * FROM drones WHERE id = ?',
        [widget.droneId],
      );
      if (rows.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }
      _row = rows.first;
      _nameC.text = _row['name'] ?? '';
      _categoryC.text = _row['category'] ?? '';
      _countryC.text = _row['country'] ?? '';
      _classC.text = _row['drone_class'] ?? 'B';
      _stationsC.text = '${_row['stations'] ?? ''}';
      _maxPayloadC.text = _row['max_payload'] ?? '';
      _stationWeightC.text = _row['station_weight_limits'] ?? '';
      _altitudeC.text = _row['altitude'] ?? '';
      _rangeC.text = _row['range'] ?? '';
      _maxSiC.text = '${_row['max_structural_integrity'] ?? 1000}';
      _foLaze = (_row['has_builtin_fo_laze'] ?? 1) == 1;
      _aeasaRadar = (_row['has_aeasa_radar'] ?? 0) == 1;
      _satcom = (_row['has_satcom'] ?? 0) == 1;
      _commsRedundancy = (_row['has_comms_redundancy'] ?? 0) == 1;
      _autonomousAi = (_row['has_autonomous_ai'] ?? 0) == 1;

      _o1w1Name.text = _row['opt1_wpn1_name'] ?? '';
      _o1w1Qty.text = '${_row['opt1_wpn1_qty'] ?? ''}';
      _o1w2Name.text = _row['opt1_wpn2_name'] ?? '';
      _o1w2Qty.text = '${_row['opt1_wpn2_qty'] ?? ''}';
      _o2w1Name.text = _row['opt2_wpn1_name'] ?? '';
      _o2w1Qty.text = '${_row['opt2_wpn1_qty'] ?? ''}';
      _o2w2Name.text = _row['opt2_wpn2_name'] ?? '';
      _o2w2Qty.text = '${_row['opt2_wpn2_qty'] ?? ''}';
      _o3w1Name.text = _row['opt3_wpn1_name'] ?? '';
      _o3w1Qty.text = '${_row['opt3_wpn1_qty'] ?? ''}';
      _o3w2Name.text = _row['opt3_wpn2_name'] ?? '';
      _o3w2Qty.text = '${_row['opt3_wpn2_qty'] ?? ''}';

      setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading drone: $e')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _save() async {
    try {
      await DatabaseService.rawExecute('''
        UPDATE drones SET
          name = ?, category = ?, country = ?, drone_class = ?,
          stations = ?, max_payload = ?, station_weight_limits = ?,
          altitude = ?, range = ?, max_structural_integrity = ?,
          has_builtin_fo_laze = ?, has_aeasa_radar = ?, has_satcom = ?,
          has_comms_redundancy = ?, has_autonomous_ai = ?,
          opt1_wpn1_name = ?, opt1_wpn1_qty = ?, opt1_wpn2_name = ?, opt1_wpn2_qty = ?,
          opt2_wpn1_name = ?, opt2_wpn1_qty = ?, opt2_wpn2_name = ?, opt2_wpn2_qty = ?,
          opt3_wpn1_name = ?, opt3_wpn1_qty = ?, opt3_wpn2_name = ?, opt3_wpn2_qty = ?
        WHERE id = ?
      ''', [
        _nameC.text.trim(),
        _categoryC.text.trim().isEmpty ? null : _categoryC.text.trim(),
        _countryC.text.trim().isEmpty ? null : _countryC.text.trim(),
        _classC.text.trim(),
        int.tryParse(_stationsC.text.trim()),
        _maxPayloadC.text.trim().isEmpty ? null : _maxPayloadC.text.trim(),
        _stationWeightC.text.trim().isEmpty ? null : _stationWeightC.text.trim(),
        _altitudeC.text.trim().isEmpty ? null : _altitudeC.text.trim(),
        _rangeC.text.trim().isEmpty ? null : _rangeC.text.trim(),
        int.tryParse(_maxSiC.text.trim()) ?? 1000,
        _foLaze ? 1 : 0, _aeasaRadar ? 1 : 0, _satcom ? 1 : 0,
        _commsRedundancy ? 1 : 0, _autonomousAi ? 1 : 0,
        _o1w1Name.text.trim().isEmpty ? null : _o1w1Name.text.trim(),
        int.tryParse(_o1w1Qty.text.trim()),
        _o1w2Name.text.trim().isEmpty ? null : _o1w2Name.text.trim(),
        int.tryParse(_o1w2Qty.text.trim()),
        _o2w1Name.text.trim().isEmpty ? null : _o2w1Name.text.trim(),
        int.tryParse(_o2w1Qty.text.trim()),
        _o2w2Name.text.trim().isEmpty ? null : _o2w2Name.text.trim(),
        int.tryParse(_o2w2Qty.text.trim()),
        _o3w1Name.text.trim().isEmpty ? null : _o3w1Name.text.trim(),
        int.tryParse(_o3w1Qty.text.trim()),
        _o3w2Name.text.trim().isEmpty ? null : _o3w2Name.text.trim(),
        int.tryParse(_o3w2Qty.text.trim()),
        widget.droneId,
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drone saved.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // true = changed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save error: $e')));
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameC, _categoryC, _countryC, _classC, _stationsC, _maxPayloadC,
      _stationWeightC, _altitudeC, _rangeC, _maxSiC,
      _o1w1Name, _o1w1Qty, _o1w2Name, _o1w2Qty,
      _o2w1Name, _o2w1Qty, _o2w2Name, _o2w2Qty,
      _o3w1Name, _o3w1Qty, _o3w2Name, _o3w2Qty,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          _loading ? 'DRONE EDITOR' : 'EDIT: ${_nameC.text}',
          style: AppTextStyles.h3.copyWith(color: Colors.amber),
        ),
        actions: [
          if (!_loading)
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save, color: Colors.greenAccent),
              label: const Text('SAVE', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── IDENTITY ──
                  _sectionHeader('IDENTITY'),
                  _field('Name', _nameC),
                  Row(children: [
                    Expanded(child: _field('Category', _categoryC)),
                    const SizedBox(width: 8),
                    Expanded(child: _field('Country', _countryC)),
                  ]),
                  Row(children: [
                    Expanded(child: _field('Class (A/B/C)', _classC)),
                    const SizedBox(width: 8),
                    Expanded(child: _field('Stations', _stationsC, numeric: true)),
                  ]),

                  const SizedBox(height: 16),
                  _sectionHeader('PERFORMANCE'),
                  Row(children: [
                    Expanded(child: _field('Range', _rangeC)),
                    const SizedBox(width: 8),
                    Expanded(child: _field('Altitude (LOW,MED,HIGH)', _altitudeC)),
                  ]),
                  Row(children: [
                    Expanded(child: _field('Max Payload', _maxPayloadC)),
                    const SizedBox(width: 8),
                    Expanded(child: _field('Station Weight Limits', _stationWeightC)),
                  ]),
                  _field('Max Structural Integrity', _maxSiC, numeric: true),

                  const SizedBox(height: 16),
                  _sectionHeader('CAPABILITIES'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 0,
                    children: [
                      _toggle('FO/Laze', _foLaze, (v) => setState(() => _foLaze = v)),
                      _toggle('AESA Radar', _aeasaRadar, (v) => setState(() => _aeasaRadar = v)),
                      _toggle('SATCOM', _satcom, (v) => setState(() => _satcom = v)),
                      _toggle('Comms Redundancy', _commsRedundancy, (v) => setState(() => _commsRedundancy = v)),
                      _toggle('Autonomous AI', _autonomousAi, (v) => setState(() => _autonomousAi = v)),
                    ],
                  ),

                  const SizedBox(height: 16),
                  _sectionHeader('LOADOUT OPTIONS'),
                  _loadoutOption('Option 1', _o1w1Name, _o1w1Qty, _o1w2Name, _o1w2Qty),
                  _loadoutOption('Option 2', _o2w1Name, _o2w1Qty, _o2w2Name, _o2w2Qty),
                  _loadoutOption('Option 3', _o3w1Name, _o3w1Qty, _o3w2Name, _o3w2Qty),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('SAVE DRONE', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ── Helpers ──

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: AppTextStyles.label.copyWith(color: Colors.amber, fontSize: 12, letterSpacing: 2)),
  );

  Widget _field(String label, TextEditingController c, {bool numeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.amber.withValues(alpha: 0.7), fontSize: 11),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: TextStyle(color: value ? Colors.black : Colors.white70, fontSize: 11)),
      selected: value,
      onSelected: onChanged,
      selectedColor: Colors.amber,
      backgroundColor: AppColors.surface,
      checkmarkColor: Colors.black,
    );
  }

  Widget _loadoutOption(String title, TextEditingController w1Name, TextEditingController w1Qty,
      TextEditingController w2Name, TextEditingController w2Qty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.amber.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(flex: 3, child: _field('Weapon 1 Name', w1Name)),
            const SizedBox(width: 6),
            Expanded(flex: 1, child: _field('Qty', w1Qty, numeric: true)),
          ]),
          Row(children: [
            Expanded(flex: 3, child: _field('Weapon 2 Name', w2Name)),
            const SizedBox(width: 6),
            Expanded(flex: 1, child: _field('Qty', w2Qty, numeric: true)),
          ]),
        ],
      ),
    );
  }
}

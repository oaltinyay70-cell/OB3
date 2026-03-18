import 'package:flutter/material.dart';
import '../../utils/design_system.dart';
import '../../services/database_service.dart';

/// Full editor screen for a single weapon's DB fields.
class WeaponEditorScreen extends StatefulWidget {
  final int weaponId;
  const WeaponEditorScreen({super.key, required this.weaponId});

  @override
  State<WeaponEditorScreen> createState() => _WeaponEditorScreenState();
}

class _WeaponEditorScreenState extends State<WeaponEditorScreen> {
  bool _loading = true;

  // Identity
  final _nameC = TextEditingController();
  final _wpnTypeC = TextEditingController();
  final _descC = TextEditingController();

  // Combat
  final _targetsC = TextEditingController();
  final _fireRangeC = TextEditingController();
  final _fireAltC = TextEditingController();

  // DRM Stats
  final _drmTruck = TextEditingController();
  final _drmPersonnel = TextEditingController();
  final _drmAfv = TextEditingController();
  final _drmSam = TextEditingController();
  final _drmTank = TextEditingController();
  final _drmArtillery = TextEditingController();
  final _drmHqBunker = TextEditingController();
  final _drmVip = TextEditingController();
  final _drmAir = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await DatabaseService.rawQuery(
        'SELECT * FROM weapons WHERE id = ?',
        [widget.weaponId],
      );
      if (rows.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }
      final r = rows.first;
      _nameC.text = r['name'] ?? '';
      _wpnTypeC.text = r['wpn_type'] ?? '';
      _descC.text = r['description'] ?? '';
      _targetsC.text = r['targets'] ?? '';
      _fireRangeC.text = r['fire_range'] ?? '';
      _fireAltC.text = r['fire_altitude'] ?? '';
      _drmTruck.text = '${r['drm_truck'] ?? 0}';
      _drmPersonnel.text = '${r['drm_personnel'] ?? 0}';
      _drmAfv.text = '${r['drm_afv'] ?? 0}';
      _drmSam.text = '${r['drm_sam'] ?? 0}';
      _drmTank.text = '${r['drm_tank'] ?? 0}';
      _drmArtillery.text = '${r['drm_artillery'] ?? 0}';
      _drmHqBunker.text = '${r['drm_hq_bunker'] ?? 0}';
      _drmVip.text = '${r['drm_vip'] ?? 0}';
      _drmAir.text = '${r['drm_air'] ?? 0}';
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading weapon: $e')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _save() async {
    try {
      await DatabaseService.rawExecute('''
        UPDATE weapons SET
          name = ?, wpn_type = ?, description = ?,
          targets = ?, fire_range = ?, fire_altitude = ?,
          drm_truck = ?, drm_personnel = ?, drm_afv = ?,
          drm_sam = ?, drm_tank = ?, drm_artillery = ?,
          drm_hq_bunker = ?, drm_vip = ?, drm_air = ?
        WHERE id = ?
      ''', [
        _nameC.text.trim(),
        _wpnTypeC.text.trim().isEmpty ? null : _wpnTypeC.text.trim(),
        _descC.text.trim().isEmpty ? null : _descC.text.trim(),
        _targetsC.text.trim().isEmpty ? null : _targetsC.text.trim(),
        _fireRangeC.text.trim().isEmpty ? null : _fireRangeC.text.trim(),
        _fireAltC.text.trim().isEmpty ? null : _fireAltC.text.trim(),
        int.tryParse(_drmTruck.text.trim()) ?? 0,
        int.tryParse(_drmPersonnel.text.trim()) ?? 0,
        int.tryParse(_drmAfv.text.trim()) ?? 0,
        int.tryParse(_drmSam.text.trim()) ?? 0,
        int.tryParse(_drmTank.text.trim()) ?? 0,
        int.tryParse(_drmArtillery.text.trim()) ?? 0,
        int.tryParse(_drmHqBunker.text.trim()) ?? 0,
        int.tryParse(_drmVip.text.trim()) ?? 0,
        int.tryParse(_drmAir.text.trim()) ?? 0,
        widget.weaponId,
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weapon saved.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
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
      _nameC, _wpnTypeC, _descC, _targetsC, _fireRangeC, _fireAltC,
      _drmTruck, _drmPersonnel, _drmAfv, _drmSam, _drmTank,
      _drmArtillery, _drmHqBunker, _drmVip, _drmAir,
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
          _loading ? 'WEAPON EDITOR' : 'EDIT: ${_nameC.text}',
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
                    Expanded(child: _field('Weapon Type', _wpnTypeC)),
                  ]),
                  _field('Description', _descC, maxLines: 3),

                  const SizedBox(height: 16),
                  _sectionHeader('COMBAT PARAMETERS'),
                  _field('Targets', _targetsC),
                  Row(children: [
                    Expanded(child: _field('Fire Range', _fireRangeC)),
                    const SizedBox(width: 8),
                    Expanded(child: _field('Fire Altitude', _fireAltC)),
                  ]),

                  const SizedBox(height: 16),
                  _sectionHeader('DRM MODIFIERS'),
                  _drmGrid(),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('SAVE WEAPON', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: AppTextStyles.label.copyWith(color: Colors.amber, fontSize: 12, letterSpacing: 2)),
  );

  Widget _field(String label, TextEditingController c, {bool numeric = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        maxLines: maxLines,
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

  Widget _drmGrid() {
    final entries = [
      ('Truck', _drmTruck),
      ('Personnel', _drmPersonnel),
      ('AFV', _drmAfv),
      ('SAM', _drmSam),
      ('Tank', _drmTank),
      ('Artillery', _drmArtillery),
      ('HQ/Bunker', _drmHqBunker),
      ('VIP', _drmVip),
      ('Air', _drmAir),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: entries.map((e) => SizedBox(
        width: 100,
        child: _field(e.$1, e.$2, numeric: true),
      )).toList(),
    );
  }
}

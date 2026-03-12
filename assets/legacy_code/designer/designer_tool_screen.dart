import 'package:flutter/material.dart';
import '../../utils/design_system.dart';
import '../../services/database_service.dart';
import '../../services/scenario_designer_service.dart';
import 'scenario_list_tab.dart';
import 'drone_editor_screen.dart';
import 'weapon_editor_screen.dart';

/// Sprint 10 (Epic 8): Hidden designer tool for authoring scenarios,
/// campaigns, medals, and drone restrictions.
/// Access: Long-press on version text in settings or 5-tap on logo.
class DesignerToolScreen extends StatefulWidget {
  const DesignerToolScreen({super.key});

  @override
  State<DesignerToolScreen> createState() => _DesignerToolScreenState();
}

class _DesignerToolScreenState extends State<DesignerToolScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _output = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initTables();
  }

  /// Create campaign/medal tables if they don't exist.
  Future<void> _initTables() async {
    try {
      await DatabaseService.rawExecute('''
        CREATE TABLE IF NOT EXISTS campaigns (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          narrative TEXT,
          repair_points_pool INTEGER DEFAULT 10
        )
      ''');
      await DatabaseService.rawExecute('''
        CREATE TABLE IF NOT EXISTS campaign_scenarios (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          campaign_id INTEGER,
          scenario_id INTEGER,
          sequence_order INTEGER,
          FOREIGN KEY(campaign_id) REFERENCES campaigns(id)
        )
      ''');
      await DatabaseService.rawExecute('''
        CREATE TABLE IF NOT EXISTS campaign_drones (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          campaign_id INTEGER,
          drone_id INTEGER,
          quantity INTEGER DEFAULT 1,
          FOREIGN KEY(campaign_id) REFERENCES campaigns(id)
        )
      ''');
      await DatabaseService.rawExecute('''
        CREATE TABLE IF NOT EXISTS scenario_allowed_drones (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          scenario_id INTEGER,
          drone_id INTEGER
        )
      ''');
      await DatabaseService.rawExecute('''
        CREATE TABLE IF NOT EXISTS medals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          nationality TEXT DEFAULT 'Any',
          criteria_type TEXT DEFAULT 'vp',
          criteria_value INTEGER DEFAULT 0,
          icon_asset TEXT
        )
      ''');
      // Designer Tool scenario schema
      await ScenarioDesignerService.initSchema();
      setState(() => _output = 'Tables initialized OK.');
    } catch (e) {
      setState(() => _output = 'Error: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('⚙️ DESIGNER TOOL', style: AppTextStyles.h2.copyWith(color: Colors.amber)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'SCENARIOS'),
            Tab(text: 'CAMPAIGNS'),
            Tab(text: 'DRONES'),
            Tab(text: 'WEAPONS'),
            Tab(text: 'MEDALS'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ScenarioListTab(onOutput: (s) => setState(() => _output = s)),
                _CampaignTab(onOutput: (s) => setState(() => _output = s)),
                _DroneTab(onOutput: (s) => setState(() => _output = s)),
                _WeaponTab(onOutput: (s) => setState(() => _output = s)),
                _MedalTab(onOutput: (s) => setState(() => _output = s)),
              ],
            ),
          ),
          // Output console
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0A0A14),
            child: Text(
              '> $_output',
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 11,
                color: Colors.greenAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scenario Tab ─── (Replaced by ScenarioListTab in scenario_list_tab.dart)

// ── Campaign Tab ─────────────────────────────────────────────────────────────

class _CampaignTab extends StatefulWidget {
  final ValueChanged<String> onOutput;
  const _CampaignTab({required this.onOutput});

  @override
  State<_CampaignTab> createState() => _CampaignTabState();
}

class _CampaignTabState extends State<_CampaignTab> {
  final _nameC = TextEditingController();
  final _descC = TextEditingController();
  final _narrativeC = TextEditingController();
  final _repairC = TextEditingController(text: '10');
  final _scenarioIdsC = TextEditingController();
  final _droneIdsC = TextEditingController();

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    _narrativeC.dispose();
    _repairC.dispose();
    _scenarioIdsC.dispose();
    _droneIdsC.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    try {
      final name = _nameC.text.trim();
      if (name.isEmpty) { widget.onOutput('Name required'); return; }

      final campaignId = await DatabaseService.rawInsert(
        'INSERT INTO campaigns (name, description, narrative, repair_points_pool) VALUES (?, ?, ?, ?)',
        [name, _descC.text.trim(), _narrativeC.text.trim(), int.tryParse(_repairC.text) ?? 10],
      );

      // Add scenario sequence
      final scenarioIds = _scenarioIdsC.text.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toList();
      for (var i = 0; i < scenarioIds.length; i++) {
        await DatabaseService.rawInsert(
          'INSERT INTO campaign_scenarios (campaign_id, scenario_id, sequence_order) VALUES (?, ?, ?)',
          [campaignId, scenarioIds[i], i + 1],
        );
      }

      // Add drone pool
      final droneIds = _droneIdsC.text.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toList();
      for (final droneId in droneIds) {
        await DatabaseService.rawInsert(
          'INSERT INTO campaign_drones (campaign_id, drone_id, quantity) VALUES (?, ?, 1)',
          [campaignId, droneId],
        );
      }

      widget.onOutput('Campaign "$name" created (id=$campaignId, ${scenarioIds.length} scenarios, ${droneIds.length} drones)');
    } catch (e) {
      widget.onOutput('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CREATE CAMPAIGN', style: AppTextStyles.h2.copyWith(color: Colors.amber)),
          const SizedBox(height: 12),
          _field('Name', _nameC),
          _field('Description', _descC),
          _field('Narrative', _narrativeC, maxLines: 3),
          _field('Repair Points Pool', _repairC),
          _field('Scenario IDs (comma-sep)', _scenarioIdsC),
          _field('Drone IDs (comma-sep)', _droneIdsC),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: _create,
            child: const Text('CREATE', style: TextStyle(color: Colors.black)),
          ),
          const SizedBox(height: 24),
          _QueryTab(
            title: 'EXISTING CAMPAIGNS',
            listQuery: 'SELECT id, name, description, repair_points_pool FROM campaigns ORDER BY id',
            onOutput: widget.onOutput,
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.amber, fontSize: 12),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }
}

// ── Drone Tab ────────────────────────────────────────────────────────────────

class _DroneTab extends StatefulWidget {
  final ValueChanged<String> onOutput;
  const _DroneTab({required this.onOutput});

  @override
  State<_DroneTab> createState() => _DroneTabState();
}

class _DroneTabState extends State<_DroneTab> {
  List<Map<String, dynamic>> _rows = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await DatabaseService.rawQuery(
        'SELECT * FROM drones ORDER BY name',
      );
      setState(() { _rows = rows; _loaded = true; });
      widget.onOutput('DRONES: ${rows.length} rows');
    } catch (e) {
      setState(() => _loaded = true);
      widget.onOutput('Query error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator(color: Colors.amber));
    if (_rows.isEmpty) return const Center(child: Text('No drones found.', style: TextStyle(color: Colors.white38)));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _rows.length,
      itemBuilder: (context, index) {
        final r = _rows[index];
        return Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: const Icon(Icons.flight, color: Colors.cyan, size: 28),
            title: Text(r['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              [
                if (r['category'] != null) r['category'],
                if (r['country'] != null) r['country'],
                if (r['drone_class'] != null) 'Class ${r['drone_class']}',
                if (r['stations'] != null) '${r['stations']} stations',
              ].join(' · '),
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            trailing: const Icon(Icons.edit, color: Colors.amber, size: 20),
            onTap: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => DroneEditorScreen(droneId: r['id'] as int)),
              );
              if (changed == true) _load();
            },
          ),
        );
      },
    );
  }
}

// ── Weapon Tab ───────────────────────────────────────────────────────────────

class _WeaponTab extends StatefulWidget {
  final ValueChanged<String> onOutput;
  const _WeaponTab({required this.onOutput});

  @override
  State<_WeaponTab> createState() => _WeaponTabState();
}

class _WeaponTabState extends State<_WeaponTab> {
  List<Map<String, dynamic>> _rows = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await DatabaseService.rawQuery(
        'SELECT * FROM weapons ORDER BY wpn_type, name',
      );
      setState(() { _rows = rows; _loaded = true; });
      widget.onOutput('WEAPONS: ${rows.length} rows');
    } catch (e) {
      setState(() => _loaded = true);
      widget.onOutput('Query error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator(color: Colors.amber));
    if (_rows.isEmpty) return const Center(child: Text('No weapons found.', style: TextStyle(color: Colors.white38)));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _rows.length,
      itemBuilder: (context, index) {
        final r = _rows[index];
        return Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: const Icon(Icons.gps_fixed, color: Colors.redAccent, size: 24),
            title: Text(r['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              [
                if (r['wpn_type'] != null) r['wpn_type'],
                if (r['targets'] != null) 'vs ${r['targets']}',
                if (r['fire_range'] != null) r['fire_range'],
              ].join(' · '),
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            trailing: const Icon(Icons.edit, color: Colors.amber, size: 20),
            onTap: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => WeaponEditorScreen(weaponId: r['id'] as int)),
              );
              if (changed == true) _load();
            },
          ),
        );
      },
    );
  }
}

// ── Medal Tab ────────────────────────────────────────────────────────────────

class _MedalTab extends StatefulWidget {
  final ValueChanged<String> onOutput;
  const _MedalTab({required this.onOutput});

  @override
  State<_MedalTab> createState() => _MedalTabState();
}

class _MedalTabState extends State<_MedalTab> {
  final _nameC = TextEditingController();
  final _descC = TextEditingController();
  final _nationalityC = TextEditingController(text: 'Any');
  final _criteriaTypeC = TextEditingController(text: 'vp');
  final _criteriaValC = TextEditingController(text: '10');

  @override
  void dispose() {
    _nameC.dispose();
    _descC.dispose();
    _nationalityC.dispose();
    _criteriaTypeC.dispose();
    _criteriaValC.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    try {
      final id = await DatabaseService.rawInsert(
        'INSERT INTO medals (name, description, nationality, criteria_type, criteria_value) VALUES (?, ?, ?, ?, ?)',
        [_nameC.text.trim(), _descC.text.trim(), _nationalityC.text.trim(), _criteriaTypeC.text.trim(), int.tryParse(_criteriaValC.text) ?? 0],
      );
      widget.onOutput('Medal "${_nameC.text}" created (id=$id)');
    } catch (e) {
      widget.onOutput('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CREATE MEDAL', style: AppTextStyles.h2.copyWith(color: Colors.amber)),
          const SizedBox(height: 12),
          _field('Name', _nameC),
          _field('Description', _descC),
          _field('Nationality (or "Any")', _nationalityC),
          _field('Criteria Type (vp/kills/scenario_complete)', _criteriaTypeC),
          _field('Criteria Value', _criteriaValC),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: _create,
            child: const Text('CREATE', style: TextStyle(color: Colors.black)),
          ),
          const SizedBox(height: 24),
          _QueryTab(
            title: 'EXISTING MEDALS',
            listQuery: 'SELECT id, name, nationality, criteria_type, criteria_value FROM medals ORDER BY id',
            onOutput: widget.onOutput,
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.amber, fontSize: 12),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }
}

// ── Reusable Query List Widget ───────────────────────────────────────────────

class _QueryTab extends StatefulWidget {
  final String title;
  final String listQuery;
  final ValueChanged<String> onOutput;

  const _QueryTab({
    required this.title,
    required this.listQuery,
    required this.onOutput,
  });

  @override
  State<_QueryTab> createState() => _QueryTabState();
}

class _QueryTabState extends State<_QueryTab> {
  List<Map<String, dynamic>> _rows = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await DatabaseService.rawQuery(widget.listQuery);
      setState(() {
        _rows = rows;
        _loaded = true;
      });
      widget.onOutput('${widget.title}: ${rows.length} rows');
    } catch (e) {
      setState(() => _loaded = true);
      widget.onOutput('Query error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }
    if (_rows.isEmpty) {
      return Center(
        child: Text('No ${widget.title.toLowerCase()} found.',
            style: const TextStyle(color: Colors.white38)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _rows.length,
      itemBuilder: (context, index) {
        final row = _rows[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            row.entries.map((e) => '${e.key}: ${e.value}').join(' | '),
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Courier'),
          ),
        );
      },
    );
  }
}

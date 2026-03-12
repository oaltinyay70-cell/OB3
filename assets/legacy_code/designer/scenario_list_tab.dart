import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/design_system.dart';
import '../../services/scenario_designer_service.dart';
import '../../services/scenario_import_export.dart';
import 'scenario_wizard_screen.dart';

/// Full scenario list tab for the Designer Tool.
/// Replaces the old read-only _ScenarioTab stub.
class ScenarioListTab extends StatefulWidget {
  final ValueChanged<String> onOutput;
  const ScenarioListTab({super.key, required this.onOutput});

  @override
  State<ScenarioListTab> createState() => _ScenarioListTabState();
}

class _ScenarioListTabState extends State<ScenarioListTab> {
  List<ScenarioListItem> _scenarios = [];
  bool _loading = true;
  String _sortBy = 'name';
  bool _ascending = true;
  String? _stateFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ScenarioDesignerService.getAllScenarios(
        stateFilter: _stateFilter,
        sortBy: _sortBy,
        ascending: _ascending,
      );
      setState(() {
        _scenarios = items;
        _loading = false;
      });
      widget.onOutput('Loaded ${items.length} scenarios');
    } catch (e) {
      setState(() => _loading = false);
      widget.onOutput('Error loading scenarios: $e');
    }
  }

  Future<void> _openWizard({int? editId}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ScenarioWizardScreen(editScenarioId: editId),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _clone(ScenarioListItem item) async {
    try {
      final newId = await ScenarioDesignerService.cloneScenario(item.id);
      widget.onOutput('Cloned "${item.name}" → id=$newId');
      _load();
    } catch (e) {
      widget.onOutput('Clone error: $e');
    }
  }

  Future<void> _delete(ScenarioListItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Delete "${item.name}"?',
            style: AppTextStyles.h3.copyWith(color: AppColors.danger)),
        content: const Text(
          'This action cannot be undone. The scenario and all its data will be permanently removed.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ScenarioDesignerService.deleteScenario(item.id);
      widget.onOutput('Deleted "${item.name}"');
      _load();
    } catch (e) {
      widget.onOutput('Delete error: $e');
    }
  }

  Future<void> _toggleState(ScenarioListItem item) async {
    try {
      if (item.state == 'Published') {
        await ScenarioDesignerService.setScenarioState(item.id, 'Inactive');
        widget.onOutput('"${item.name}" marked Inactive');
      } else if (item.state == 'Inactive') {
        await ScenarioDesignerService.setScenarioState(item.id, 'Published');
        widget.onOutput('"${item.name}" reactivated');
      }
      _load();
    } catch (e) {
      widget.onOutput('State change error: $e');
    }
  }

  Future<void> _importFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select Scenario File to Import',
      );
      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) return;

      final content = await File(path).readAsString();
      final importResult = await ScenarioImportExport.importScenario(content);
      final data = importResult.data;
      widget.onOutput('Imported "${data.title}" from ${result.files.single.name}');

      if (!mounted) return;

      // Combine DB-level warnings (invalid IDs) with validation errors
      final validationErrors = ScenarioDesignerService.validate(data);
      final hasDbWarnings = importResult.hasWarnings;
      final totalIssues = importResult.warnings.length + validationErrors.length;

      if (totalIssues > 0 && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            title: Row(children: [
              Icon(
                hasDbWarnings ? Icons.error : Icons.warning_amber,
                color: hasDbWarnings ? const Color(0xFFFF4444) : Colors.amber,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('$totalIssues issue(s) found',
                  style: TextStyle(
                    color: hasDbWarnings ? const Color(0xFFFF4444) : Colors.amber,
                    fontSize: 16,
                  ))),
            ]),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasDbWarnings)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFF4444).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Invalid references found! These IDs do not exist in the database. '
                        'Fix them in the file or correct them in the wizard. '
                        'The scenario cannot be published until all references are valid.',
                        style: TextStyle(color: Color(0xFFFF8888), fontSize: 12),
                      ),
                    ),
                  const Text(
                    'You can fix these in the wizard before saving.',
                    style: TextStyle(color: Color(0xFFAAB0C0), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  // DB warnings (red)
                  ...importResult.warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✗ ', style: TextStyle(color: Color(0xFFFF4444), fontSize: 13)),
                        Expanded(child: Text(w,
                            style: const TextStyle(color: Color(0xFFFF8888), fontSize: 12))),
                      ],
                    ),
                  )),
                  // Validation errors (amber)
                  ...validationErrors.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.amber, fontSize: 13)),
                        Expanded(child: Text(e.message,
                            style: const TextStyle(color: Color(0xFFCCD0DC), fontSize: 13))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCEL', style: TextStyle(color: Color(0xFF888CA0))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('OPEN WIZARD & FIX'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }

      if (!mounted) return;
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ScenarioWizardScreen(importedData: data),
        ),
      );
      if (saved == true) _load();
    } catch (e) {
      widget.onOutput('Import error: $e');
    }
  }

  Future<void> _exportTemplate() async {
    try {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Scenario Template',
        fileName: 'scenario_template.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );
      if (savePath == null) return;

      final content = ScenarioImportExport.exportTemplate();
      await File(savePath).writeAsString(content);
      widget.onOutput('Template saved to: $savePath');
    } catch (e) {
      widget.onOutput('Error saving template: $e');
    }
  }

  Future<void> _export(ScenarioListItem item) async {
    try {
      final safeName = item.name.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Scenario: ${item.name}',
        fileName: '${safeName}_export.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );
      if (savePath == null) return;

      final content = await ScenarioImportExport.exportScenario(item.id);
      await File(savePath).writeAsString(content);
      widget.onOutput('Exported "${item.name}" to: $savePath');
    } catch (e) {
      widget.onOutput('Export error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text('SCENARIOS', style: AppTextStyles.h2.copyWith(color: Colors.amber)),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('NEW SCENARIO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _openWizard(),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.amber),
                color: AppColors.surfaceElevated,
                onSelected: (v) async {
                  if (v == 'template') {
                    _exportTemplate();
                  } else if (v == 'import') {
                    _importFile();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'template', child: Text('Export Template', style: TextStyle(color: AppColors.textPrimary))),
                  const PopupMenuItem(value: 'import', child: Text('Import from File', style: TextStyle(color: AppColors.textPrimary))),
                ],
              ),
            ],
          ),
        ),

        // ── Sort & Filter ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              // Sort dropdown
              _chip('Sort:', _sortLabel(), () {
                final options = ['name', 'date', 'difficulty'];
                final idx = options.indexOf(_sortBy);
                setState(() {
                  _sortBy = options[(idx + 1) % options.length];
                });
                _load();
              }),
              const SizedBox(width: 4),
              // Sort direction
              GestureDetector(
                onTap: () {
                  setState(() => _ascending = !_ascending);
                  _load();
                },
                child: Icon(
                  _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.amber,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              // State filter chips
              _filterChip('All', null),
              _filterChip('Draft', 'Draft'),
              _filterChip('Published', 'Published'),
              _filterChip('Inactive', 'Inactive'),
            ],
          ),
        ),

        const Divider(color: AppColors.surfaceBorder, height: 1),

        // ── List ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.amber))
              : _scenarios.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _scenarios.length,
                      itemBuilder: (_, i) => _scenarioRow(_scenarios[i]),
                    ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 48, color: AppColors.textDisabled),
          const SizedBox(height: 12),
          Text('No scenarios yet.', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: () => _openWizard(),
            child: const Text('CREATE YOUR FIRST SCENARIO'),
          ),
        ],
      ),
    );
  }

  Widget _scenarioRow(ScenarioListItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title + state badge
          Row(
            children: [
              Expanded(
                child: Text(item.name,
                    style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
              ),
              _stateBadge(item.state),
            ],
          ),
          if (item.shortDescription != null && item.shortDescription!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(item.shortDescription!,
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          const SizedBox(height: 8),
          // Row 2: Stats
          Row(
            children: [
              _stat('⚙', item.difficultyRating ?? '-'),
              _stat('✈', '${item.droneCount}'),
              _stat('🎯', '${item.targetCardCount}'),
              _stat('⚠', '${item.threatCardCount}'),
              _stat('⚔', '${item.combatCardCount}'),
              const Spacer(),
              Text('v${item.versionNumber}', style: AppTextStyles.body),
            ],
          ),
          const SizedBox(height: 8),
          // Row 3: Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _actionBtn(Icons.edit, 'Edit', () => _openWizard(editId: item.id)),
              _actionBtn(Icons.file_download, 'Export', () => _export(item)),
              _actionBtn(Icons.copy, 'Clone', () => _clone(item)),
              if (item.state == 'Published')
                _actionBtn(Icons.visibility_off, 'Deactivate', () => _toggleState(item)),
              if (item.state == 'Inactive')
                _actionBtn(Icons.visibility, 'Reactivate', () => _toggleState(item)),
              _actionBtn(Icons.delete, 'Delete', () => _delete(item), color: AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stateBadge(String state) {
    Color c;
    switch (state) {
      case 'Published':
        c = AppColors.success;
        break;
      case 'Inactive':
        c = AppColors.danger;
        break;
      default:
        c = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Text(state.toUpperCase(),
          style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _stat(String icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Text('$icon $value', style: AppTextStyles.body),
    );
  }

  Widget _actionBtn(IconData icon, String tooltip, VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 22, color: color ?? AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  String _sortLabel() {
    switch (_sortBy) {
      case 'date':
        return 'Date';
      case 'difficulty':
        return 'Difficulty';
      default:
        return 'Name';
    }
  }

  Widget _chip(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Text('$label $value',
            style: const TextStyle(color: Colors.amber, fontSize: 15)),
      ),
    );
  }

  Widget _filterChip(String label, String? filterValue) {
    final selected = _stateFilter == filterValue;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: GestureDetector(
        onTap: () {
          setState(() => _stateFilter = filterValue);
          _load();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? Colors.amber.withValues(alpha: 0.2) : AppColors.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: selected ? Colors.amber : AppColors.surfaceBorder),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.amber : AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }
}

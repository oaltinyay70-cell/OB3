import 'package:flutter/material.dart';
import '../../core/theme/milstd_theme.dart';
import '../../data/database_service.dart';
import '../../data/repositories/scenario_repository.dart';
import '../../models/scenario.dart';

/// Scenario Selection screen — lists all published scenarios from the DB.
/// Designed with tactical/military precision to align with the Scenario Designer aesthetic.
class ScenarioSelectionScreen extends StatefulWidget {
  const ScenarioSelectionScreen({
    super.key,
    required this.onScenarioSelected,
    required this.onBack,
  });

  final Function(Scenario) onScenarioSelected;
  final VoidCallback onBack;

  @override
  State<ScenarioSelectionScreen> createState() => _ScenarioSelectionScreenState();
}

class _ScenarioSelectionScreenState extends State<ScenarioSelectionScreen> {
  List<Map<String, dynamic>> _scenarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScenarios();
  }

  Future<void> _loadScenarios() async {
    try {
      final db = DatabaseService.instance;
      final repo = ScenarioRepository(db);
      final list = await repo.listScenarios();
      setState(() {
        _scenarios = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load scenarios: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MilstdTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: MilstdTheme.backgroundSecondary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('SCENARIO SELECTION'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: MilstdTheme.accentSecondary, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scenarios.isEmpty
              ? _buildEmptyState()
              : _buildScenarioList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 48, color: MilstdTheme.textMuted),
          const SizedBox(height: 16),
          const Text(
            'NO OPERATIONAL SCENARIOS FOUND',
            style: TextStyle(
              fontFamily: 'IBMPlexMono',
              color: MilstdTheme.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sync with Scenario Designer to publish new missions.',
            style: TextStyle(
              fontFamily: 'IBMPlexSans',
              color: MilstdTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scenarios.length,
      itemBuilder: (context, index) {
        final item = _scenarios[index];
        return _ScenarioCard(
          data: item,
          onTap: () async {
            final repo = ScenarioRepository(DatabaseService.instance);
            final fullScenario = await repo.getById(item['id'] as int);
            if (fullScenario != null) {
              widget.onScenarioSelected(fullScenario);
            }
          },
        );
      },
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.data, required this.onTap});
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final difficulty = (data['difficulty_rating'] as String? ?? 'Medium').toUpperCase();
    final version = data['version_number'] ?? 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MilstdTheme.surface,
            borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
            border: Border.all(color: MilstdTheme.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (data['name'] as String).toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: MilstdTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  _Badge(text: 'v${version.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data['description'] as String? ?? 'No description available.',
                style: const TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: 14,
                  color: MilstdTheme.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatItem(label: 'DIFF', value: difficulty, color: _getDiffColor(difficulty)),
                  const Spacer(),
                  const Text(
                    'ENGAGE MISSION',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MilstdTheme.accentSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: MilstdTheme.accentSecondary, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDiffColor(String diff) {
    switch (diff) {
      case 'EASY': return MilstdTheme.statusOk;
      case 'HARD':
      case 'EXPERT': return MilstdTheme.statusCritical;
      default: return MilstdTheme.statusCaution;
    }
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 10,
            color: MilstdTheme.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: MilstdTheme.accentSecondary.withValues(alpha: 0.1),
        border: Border.all(color: MilstdTheme.accentSecondary.withValues(alpha: 0.3)),
        borderRadius: const BorderRadius.all(MilstdTheme.radiusXs),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'IBMPlexMono',
          fontSize: 10,
          color: MilstdTheme.accentSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

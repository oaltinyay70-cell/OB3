import 'package:flutter/material.dart';
import '../../core/theme/milstd_theme.dart';

/// Main Menu screen — the home hub of Drone Commander.
///
/// Provides navigation to Quick Game, Scenario, Campaign (disabled),
/// Load Game, Settings, and How-to-Play.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MilstdTheme.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Title
              const Text(
                'DRONE COMMANDER',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: MilstdTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              // Call sign
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'CALL SIGN: COMMANDER',
                    style: TextStyle(
                      fontFamily: 'IBMPlexMono',
                      fontSize: 14,
                      color: MilstdTheme.accentSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      // TODO: Navigate to call sign editor
                    },
                    child: const Icon(
                      Icons.edit,
                      size: 14,
                      color: MilstdTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Menu cards
              _MenuCard(
                icon: Icons.flight_takeoff,
                title: 'QUICK GAME',
                subtitle: 'Solitaire — select drone & engage',
                accentColor: MilstdTheme.accentPrimary,
                onTap: () {
                  // TODO: Navigate to drone selection
                },
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.gps_fixed,
                title: 'SCENARIO',
                subtitle: 'Mission-based with objectives',
                accentColor: MilstdTheme.accentSecondary,
                onTap: () {
                  // TODO: Navigate to scenario selection
                },
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.map,
                title: 'CAMPAIGN',
                subtitle: 'Territory control — v1.1',
                accentColor: MilstdTheme.accentWarm,
                isDisabled: true,
                badge: 'SOON',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Campaign mode coming in v1.1'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.save,
                title: 'LOAD GAME',
                subtitle: 'Resume a saved game',
                accentColor: MilstdTheme.textSecondary,
                isDisabled: true,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No saved games found'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              const Spacer(),

              // Bottom buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to settings
                      },
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('SETTINGS'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to how-to-play
                      },
                      icon: const Icon(Icons.help_outline, size: 18),
                      label: const Text('HOW TO PLAY'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'v3.1-D10',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 12,
                  color: MilstdTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single menu card with colored left border, icon, title, and subtitle.
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    this.isDisabled = false,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isDisabled;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Material(
        color: MilstdTheme.surface,
        borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
              border: Border(
                left: BorderSide(color: accentColor, width: 3),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: MilstdTheme.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexSans',
                          fontSize: 14,
                          color: MilstdTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.all(MilstdTheme.radiusXs),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSans',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: MilstdTheme.textInverse,
                      ),
                    ),
                  ),
                if (badge == null)
                  Icon(Icons.chevron_right, color: accentColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

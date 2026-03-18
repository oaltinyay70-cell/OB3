import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/milstd_theme.dart';
import 'data/database_service.dart';
import 'data/repositories/card_repository.dart';
import 'data/repositories/drone_repository.dart';
import 'data/repositories/scenario_repository.dart';
import 'data/repositories/weapon_repository.dart';
import 'engine/game_engine.dart';
import 'engine/game_state.dart';
import 'engine/scenario_loader.dart';
import 'features/briefing/mission_briefing_screen.dart';
import 'features/callsign/call_sign_screen.dart';
import 'features/drone_selection/drone_selection_screen.dart';
import 'features/game/bloc/game_bloc.dart';
import 'features/game/game_board_screen.dart';
import 'features/loadout/loadout_config_screen.dart';

import 'features/post_scenario/post_scenario_briefing_screen.dart';
import 'features/splash/splash_screen.dart';
import 'models/drone.dart';
import 'models/game_enums.dart';
import 'models/scenario.dart';

/// Root widget for the Drone Commander application.
///
/// Navigation flow:
///   Splash → Call Sign (first launch) → Main Menu
///   Quick Game:  Main Menu → Drone Selection → Loadout Config → Launch → Game
///   Scenario:    Main Menu → Mission Briefing (ACCEPT) → Drone Selection → Loadout Config → Launch → Game
class DroneCommanderApp extends StatelessWidget {
  const DroneCommanderApp({super.key});

  static void configureSystemUI() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drone Commander',
      debugShowCheckedModeBanner: false,
      theme: MilstdTheme.themeData,
      home: const _AppShell(),
    );
  }
}

// =============================================================================
// App Shell — manages full screen stack
// =============================================================================

enum _AppScreen {
  splash,
  callSign,
  mainMenu,
  droneSelection,
  loadoutConfig,
  missionBriefing,
  gameBoard,
  postScenario,
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  _AppScreen _currentScreen = _AppScreen.splash;
  String? _callSign = 'VIPER'; // DEV BYPASS: skip call sign screen
  String? _avatarAsset;

  // Game flow state
  Drone? _selectedDrone;
  LoadoutOption? _selectedLoadout;
  Scenario? _activeScenario; // Set when entering scenario flow (briefing first)
  bool _isQuickGame = false; // True when Quick Game bypasses briefing

  GameSetup? _gameSetup;
  GameState? _finalGameState;

  bool get _hasCallSign => _callSign != null;

  // ---------------------------------------------------------------------------
  // Navigation callbacks
  // ---------------------------------------------------------------------------

  void _onSplashComplete() {
    setState(() {
      _currentScreen =
          _hasCallSign ? _AppScreen.mainMenu : _AppScreen.callSign;
    });
  }

  void _onCallSignConfirmed(String callSign, {String? avatarAsset}) {
    setState(() {
      _callSign = callSign;
      _avatarAsset = avatarAsset;
      _currentScreen = _AppScreen.mainMenu;
    });
  }

  /// Quick Game: skip briefing, go straight to drone selection.
  void _onQuickGame() {
    setState(() {
      _isQuickGame = true;
      _activeScenario = null;
      _currentScreen = _AppScreen.droneSelection;
    });
  }

  /// Load available scenarios from DB and launch the first one.
  /// TODO: Replace with full ScenarioBrowserScreen when built.
  void _loadAndPlayScenario() async {
    try {
      final db = DatabaseService.instance;
      final repo = ScenarioRepository(db);
      final scenarios = await repo.listScenarios();
      if (scenarios.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No scenarios found in database')),
          );
        }
        return;
      }
      // Load full scenario data for the first one
      final scenario = await repo.getById(scenarios.first['id'] as int);
      if (scenario != null && mounted) {
        _onPlayScenario(scenario);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load scenario: $e')),
        );
      }
    }
  }

  /// Scenario flow: show briefing FIRST, then drone selection on accept.
  void _onPlayScenario(Scenario scenario) {
    setState(() {
      _isQuickGame = false;
      _activeScenario = scenario;
      _currentScreen = _AppScreen.missionBriefing;
    });
  }

  /// Player accepted the mission briefing → proceed to drone selection.
  ///
  /// Even for forced-drone scenarios, we still show drone selection so the
  /// player can pick their loadout (drone+loadout are merged on one screen).
  void _onAcceptMission() {
    setState(() {
      _currentScreen = _AppScreen.droneSelection;
    });
  }

  /// Drone + loadout selected on the combined screen → launch game.
  void _onDroneAndLoadoutSelected(Drone drone, LoadoutOption loadout) {
    _selectedDrone = drone;
    _onLoadoutConfirmed(loadout);
  }

  /// Loadout confirmed → build GameSetup and go straight to game board.
  void _onLoadoutConfirmed(LoadoutOption loadout) async {
    _selectedLoadout = loadout;

    try {
      final db = DatabaseService.instance;
      final loader = ScenarioLoader(
        droneRepo: DroneRepository(db),
        weaponRepo: WeaponRepository(db),
        cardRepo: CardRepository(db),
        scenarioRepo: ScenarioRepository(db),
      );

      final optionIndex = _selectedDrone!.loadoutOptions.indexOf(loadout);

      final setup = await loader.loadQuickGame(
        droneId: _selectedDrone!.id,
        loadoutOptionIndex: optionIndex >= 0 ? optionIndex : 0,
      );

      if (!mounted) return;
      setState(() {
        _gameSetup = setup;
        _currentScreen = _AppScreen.gameBoard;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load game: $e')),
      );
    }
  }

  // _onLaunchMission removed — loadout confirm now goes directly to gameBoard.

  void _onGameOver(GameState finalState) {
    setState(() {
      _finalGameState = finalState;
      _currentScreen = _AppScreen.postScenario;
    });
  }

  void _onReturnToMenu() {
    setState(() {
      _selectedDrone = null;
      _selectedLoadout = null;
      _activeScenario = null;
      _isQuickGame = false;
      _gameSetup = null;
      _finalGameState = null;
      _currentScreen = _AppScreen.mainMenu;
    });
  }

  void _onReplay() {
    setState(() {
      _finalGameState = null;
      _currentScreen = _AppScreen.loadoutConfig;
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    return switch (_currentScreen) {
      _AppScreen.splash => SplashScreen(
          key: const ValueKey('splash'),
          onComplete: _onSplashComplete,
        ),
      _AppScreen.callSign => CallSignScreen(
          key: const ValueKey('callsign'),
          onCallSignConfirmed: _onCallSignConfirmed,
        ),
      _AppScreen.mainMenu => _MainMenuWrapper(
          key: const ValueKey('menu'),
          callSign: _callSign ?? 'COMMANDER',
          avatarAsset: _avatarAsset,
          onQuickGame: _onQuickGame,
          onPlayScenario: _loadAndPlayScenario,
        ),
      // Briefing comes BEFORE drone selection in scenario mode.
      // Quick Game skips briefing (goes Menu → DroneSelection).
      _AppScreen.missionBriefing => MissionBriefingScreen(
          key: const ValueKey('briefing'),
          scenario: _activeScenario ?? _buildQuickGameScenario(),
          onAccept: _onAcceptMission,
          onBack: _onReturnToMenu,
        ),
      _AppScreen.droneSelection => DroneSelectionScreen(
          key: const ValueKey('drone_select'),
          onDroneAndLoadoutConfirmed: _onDroneAndLoadoutSelected,
          allowedDroneIds: _activeScenario?.allowedDroneIds ?? const [],
          onBack: () => setState(() {
            // Back from drone selection:
            //   - Scenario flow → return to briefing
            //   - Quick Game → return to menu
            _currentScreen = _isQuickGame
                ? _AppScreen.mainMenu
                : _AppScreen.missionBriefing;
          }),
        ),
      _AppScreen.loadoutConfig => LoadoutConfigScreen(
          key: const ValueKey('loadout'),
          drone: _selectedDrone!,
          onLoadoutConfirmed: _onLoadoutConfirmed,
          onBack: () => setState(() => _currentScreen = _AppScreen.droneSelection),
        ),
      _AppScreen.gameBoard => _buildGameBoard(),
      _AppScreen.postScenario => PostScenarioBriefingScreen(
          key: const ValueKey('post_scenario'),
          finalState: _finalGameState!,
          droneName: _selectedDrone!.name,
          onReturnToMenu: _onReturnToMenu,
          onReplay: _onReplay,
        ),
    };
  }

  /// Build a placeholder scenario for Quick Game mode.
  Scenario _buildQuickGameScenario() {
    return Scenario(
      id: 0,
      name: 'Quick Game',
      description: 'Solitaire engagement — maximum kill scoring. '
          'Destroy as many targets as possible before running out of fuel or ammo.',
      scoringMode: ScoringMode.maximumKill,
      combatNoEventCount: 42,
      combatEventCount: 8,
      zones: const [],
      loadouts: const [],
      targetDeckEntries: const [],
      threatDeckEntries: const [],
      targetRanges: const {},
      threatRanges: const {},
    );
  }

  /// Build the game board with BLoC provider.
  Widget _buildGameBoard() {
    return BlocProvider<GameBloc>(
      key: const ValueKey('game_board'),
      create: (context) {
        final engine = GameEngine(setup: _gameSetup!);
        final bloc = GameBloc(engine: engine);
        // Auto-start the game — no need for a separate "START GAME" screen
        bloc.add(const GameStarted());
        return bloc;
      },
      child: GameBoardScreen(
        droneName: _selectedDrone!.name,
        onGameOver: _onGameOver,
      ),
    );
  }
}

// =============================================================================
// Main Menu Wrapper — connects menu actions to app navigation
// =============================================================================

class _MainMenuWrapper extends StatelessWidget {
  const _MainMenuWrapper({
    super.key,
    required this.callSign,
    this.avatarAsset,
    required this.onQuickGame,
    required this.onPlayScenario,
  });

  final String callSign;
  final String? avatarAsset;
  final VoidCallback onQuickGame;
  final VoidCallback onPlayScenario;

  @override
  Widget build(BuildContext context) {
    return _QuickGameMenuScreen(
      callSign: callSign,
      avatarAsset: avatarAsset,
      onQuickGame: onQuickGame,
      onPlayScenario: onPlayScenario,
    );
  }
}

/// Lightweight menu screen that fires onQuickGame callback.
/// Replaces MainMenuScreen temporarily until it accepts navigation callbacks.
/// Lightweight menu screen matching mockup: main_menu.png
/// Radar icon, DRONE COMMANDER title, Welcome CALLSIGN, 5 menu items
class _QuickGameMenuScreen extends StatelessWidget {
  const _QuickGameMenuScreen({
    required this.callSign,
    this.avatarAsset,
    required this.onQuickGame,
    required this.onPlayScenario,
  });

  final String callSign;
  final String? avatarAsset;
  final VoidCallback onQuickGame;
  final VoidCallback onPlayScenario;

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
              const SizedBox(height: 32),

              // Player avatar (or fallback radar icon)
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MilstdTheme.accentPrimary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: MilstdTheme.accentPrimary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: avatarAsset != null
                    ? ClipOval(
                        child: Image.asset(
                          avatarAsset!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.radar,
                        color: MilstdTheme.accentPrimary, size: 32),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'DRONE\nCOMMANDER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: MilstdTheme.textPrimary,
                  letterSpacing: 0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),

              // Welcome call sign
              Text(
                'Welcome, $callSign',
                style: const TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: 14,
                  color: MilstdTheme.accentSecondary,
                ),
              ),
              const SizedBox(height: 36),

              // Menu items matching mockup
              _MenuBtn(
                icon: Icons.rocket_launch,
                title: 'PLAY SCENARIO',
                borderColor: const Color(0xFF06B6D4), // cyan
                onTap: onPlayScenario,
              ),
              const SizedBox(height: 10),
              _MenuBtn(
                icon: Icons.map_outlined,
                title: 'PLAY CAMPAIGN',
                borderColor: MilstdTheme.accentWarm, // orange
                badge: 'SOON',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Campaign mode coming soon')),
                  );
                },
              ),
              const SizedBox(height: 10),
              _MenuBtn(
                icon: Icons.folder_open,
                title: 'LOAD GAME',
                borderColor: const Color(0xFF8B5CF6), // purple
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Load game coming soon')),
                  );
                },
              ),
              const SizedBox(height: 10),
              _MenuBtn(
                icon: Icons.bar_chart,
                title: 'LEADERBOARD',
                borderColor: MilstdTheme.accentPrimary, // green
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Leaderboard coming soon')),
                  );
                },
              ),
              const SizedBox(height: 10),
              _MenuBtn(
                icon: Icons.settings,
                title: 'SETTINGS',
                borderColor: MilstdTheme.textSecondary, // gray
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings coming soon')),
                  );
                },
              ),

              const Spacer(),

              const Text(
                'v3.1-D10',
                style: TextStyle(
                  fontFamily: 'IBMPlexMono',
                  fontSize: 12,
                  color: MilstdTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width menu button matching the mockup style.
/// Colored left border, icon, bold title, optional SOON badge.
class _MenuBtn extends StatelessWidget {
  const _MenuBtn({
    required this.icon,
    required this.title,
    required this.borderColor,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final Color borderColor;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final isDisabled = badge != null;
    return Opacity(
      opacity: isDisabled ? 0.6 : 1.0,
      child: Material(
        color: MilstdTheme.surface,
        borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(MilstdTheme.radiusMd),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: borderColor, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: MilstdTheme.textPrimary,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius:
                          const BorderRadius.all(MilstdTheme.radiusXs),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

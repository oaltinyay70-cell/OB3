import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../engine/game_engine.dart';
import '../../../engine/game_state.dart';
import '../../../models/game_enums.dart';
import '../../../models/weapon.dart';

// =============================================================================
// Events
// =============================================================================

/// Base class for all game events.
abstract class GameEvent {
  const GameEvent();
}

class GameStarted extends GameEvent {
  const GameStarted();
}

class GameProcessB0 extends GameEvent {
  const GameProcessB0();
}

class GameChangeAltitude extends GameEvent {
  const GameChangeAltitude(this.altitude);
  final Altitude altitude;
}

class GameDrawCombatCard extends GameEvent {
  const GameDrawCombatCard();
}

class GameDrawAndResolveCombatCard extends GameEvent {
  const GameDrawAndResolveCombatCard();
}

class GameExecuteCombatCard extends GameEvent {
  const GameExecuteCombatCard();
}

class GameAdvanceFromB1 extends GameEvent {
  const GameAdvanceFromB1();
}

class GameRollTargetAcq extends GameEvent {
  const GameRollTargetAcq();
}

class GameRollThreatDetermination extends GameEvent {
  const GameRollThreatDetermination();
}

class GameDecideEngage extends GameEvent {
  const GameDecideEngage();
}

class GameDecideRetreat extends GameEvent {
  const GameDecideRetreat();
}

class GameAdvanceFromB3 extends GameEvent {
  const GameAdvanceFromB3();
}

class GameSelectAttack extends GameEvent {
  const GameSelectAttack({required this.mode, this.weapon});
  final AttackMode mode;
  final Weapon? weapon;
}

class GameExecuteAttack extends GameEvent {
  const GameExecuteAttack();
}

class GameExecuteEvasion extends GameEvent {
  const GameExecuteEvasion();
}

class GameDecideContinue extends GameEvent {
  const GameDecideContinue();
}

class GameDecideRTB extends GameEvent {
  const GameDecideRTB();
}

/// Internal event to push engine state updates.
class _EngineStateUpdated extends GameEvent {
  const _EngineStateUpdated(this.state);
  final GameState state;
}

// =============================================================================
// BLoC
// =============================================================================

/// Central BLoC managing game state via the GameEngine.
///
/// Wraps all engine actions as BLoC events, and re-emits engine state
/// snapshots to the UI layer.
class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc({required this.engine}) : super(engine.state) {
    // Listen to engine state changes
    engine.onStateChanged = (newState) {
      if (!isClosed) {
        add(_EngineStateUpdated(newState));
      }
    };

    on<_EngineStateUpdated>((event, emit) => emit(event.state));

    on<GameStarted>((event, emit) => engine.startGame());
    on<GameProcessB0>((event, emit) => engine.processB0());
    on<GameChangeAltitude>((event, emit) => engine.changeAltitude(event.altitude));
    on<GameDrawCombatCard>((event, emit) => engine.drawCombatCard());
    on<GameDrawAndResolveCombatCard>((event, emit) => engine.drawAndResolveCombatCard());
    on<GameExecuteCombatCard>((event, emit) => engine.executeCombatCard());
    on<GameAdvanceFromB1>((event, emit) => engine.advanceFromB1());
    on<GameRollTargetAcq>((event, emit) => engine.rollTargetAcquisition());
    on<GameRollThreatDetermination>((event, emit) => engine.rollThreatDetermination());
    on<GameDecideEngage>((event, emit) => engine.decideEngage());
    on<GameDecideRetreat>((event, emit) => engine.decideRetreat());
    on<GameAdvanceFromB3>((event, emit) => engine.advanceFromB3());
    on<GameSelectAttack>((event, emit) => engine.selectAttack(mode: event.mode, weapon: event.weapon));
    on<GameExecuteAttack>((event, emit) => engine.executeAttack());
    on<GameExecuteEvasion>((event, emit) => engine.executeEvasion());
    on<GameDecideContinue>((event, emit) => engine.decideContinue());
    on<GameDecideRTB>((event, emit) => engine.decideRTB());
  }

  final GameEngine engine;
}

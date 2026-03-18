import '../models/cards.dart';
import 'constants.dart';

class CardData {
  static List<TargetCard> get defaultTargets => [
    TargetCard(
      cardId: 't1',
      targetType: TargetCardType.truck,
      vpValue: 1,
      description: 'Unarmored supply truck.',
      imageUrl: 'assets/images/cards/target_truck.png',
    ),
    TargetCard(
      cardId: 't2',
      targetType: TargetCardType.personnel,
      vpValue: 1,
      description: 'Infantry squad in the open.',
      imageUrl: 'assets/images/cards/target_personnel.png',
    ),
    TargetCard(
      cardId: 't3',
      targetType: TargetCardType.afv,
      vpValue: 2,
      description: 'Lightly armored infantry fighting vehicle.',
      imageUrl: 'assets/images/cards/target_afv.png',
    ),
    TargetCard(
      cardId: 't4',
      targetType: TargetCardType.tank,
      vpValue: 3,
      description: 'Modern Main Battle Tank.',
      imageUrl: 'assets/images/cards/target_tank.png',
    ),
    TargetCard(
      cardId: 't5',
      targetType: TargetCardType.sam,
      vpValue: 4,
      specialRules: 'Counter-fire: SAM gets an immediate shot if not destroyed.',
      description: 'Mobile Surface-to-Air Missile system.',
      imageUrl: 'assets/images/cards/target_sam.png',
    ),
    TargetCard(
      cardId: 't6',
      targetType: TargetCardType.artillery,
      vpValue: 2,
      description: 'Self-propelled howitzer.',
      imageUrl: 'assets/images/cards/target_tank.png',
    ),
    TargetCard(
      cardId: 't7',
      targetType: TargetCardType.hqBunker,
      vpValue: 5,
      description: 'Command and control bunker.',
      imageUrl: 'assets/images/cards/target_hqbunker.png',
    ),
  ];

  static List<ThreatCard> get defaultThreats => [
    ThreatCard(
      cardId: 'th1',
      threatType: ThreatCardType.smallArms,
      drmModifier: 0,
      cardName: 'SMALL ARMS',
      description: 'Incidental small arms fire from ground troops.',
      imageUrl: 'assets/images/cards/threat_smallarms.png',
    ),
    ThreatCard(
      cardId: 'th2',
      threatType: ThreatCardType.aaa,
      drmModifier: 1,
      cardName: 'AAA',
      description: 'Anti-aircraft artillery batteries.',
      imageUrl: 'assets/images/cards/threat_aaa.png',
    ),
    ThreatCard(
      cardId: 'th3',
      threatType: ThreatCardType.sam,
      drmModifier: 2,
      cardName: 'RADAR SAM',
      specialRules: 'High Altitude Threat: Cannot be evaded at High altitude.',
      description: 'Radar-guided SAM battery.',
      imageUrl: 'assets/images/cards/threat_sam.png',
    ),
    ThreatCard(
      cardId: 'th4',
      threatType: ThreatCardType.cap,
      drmModifier: 3,
      cardName: 'CAP FIGHTERS',
      description: 'Enemy Combat Air Patrol fighters.',
      imageUrl: 'assets/images/cards/threat_cap.png',
    ),
    ThreatCard(
      cardId: 'th5',
      threatType: ThreatCardType.antiDrone,
      drmModifier: 1,
      cardName: 'EW JAMMER',
      description: 'Electronic warfare anti-drone jammer.',
      imageUrl: 'assets/images/cards/event_jammed.png',
    ),
  ];

  static List<CombatCard> get defaultCombatEvents => [
    CombatCard(
      cardId: 'ce1',
      description: 'Clear Skies: No atmospheric interference.',
      isNoEvent: true,
      imageUrl: 'assets/images/cards/event_generic.png',
    ),
    CombatCard(
      cardId: 'ce2',
      description: 'Cloud Cover: -1 to Target Acquisition rolls.',
      effect: 'target_acq_penalty_1',
      imageUrl: 'assets/images/cards/event_interference.png',
    ),
    CombatCard(
      cardId: 'ce3',
      description: 'Easy Target: Target is out in the open. +1 to Attack.',
      effect: 'attack_bonus_1',
      imageUrl: 'assets/images/cards/target_personnel.png',
    ),
    CombatCard(
      cardId: 'ce4',
      description: 'Sudden Gust: Difficult flight conditions. -1 to Evasion.',
      effect: 'evasion_penalty_1',
      imageUrl: 'assets/images/cards/combat_sample.png',
    ),
  ];

  static TargetCard? findTarget(String id) => 
    defaultTargets.where((c) => c.cardId == id).firstOrNull;
    
  static ThreatCard? findThreat(String id) => 
    defaultThreats.where((c) => c.cardId == id).firstOrNull;
    
  static CombatCard? findEvent(String id) => 
    defaultCombatEvents.where((c) => c.cardId == id).firstOrNull;
}

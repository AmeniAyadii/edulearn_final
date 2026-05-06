// lib/models/rhythm_movement.dart
import 'package:flutter/material.dart';

class RhythmMovement {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String poseType;
  final int duration;
  final int points;
  final int difficulty;
  final List<String> instructions;

  RhythmMovement({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.poseType,
    required this.duration,
    required this.points,
    required this.difficulty,
    required this.instructions,
  });

  static List<RhythmMovement> getAllMovements() {
    return [
      // ==================== NIVEAU 1 - Mouvements très simples (10 mouvements) ====================
      RhythmMovement(
        id: 'stand', name: 'Se tenir droit', emoji: '🧍',
        description: 'Tiens-toi bien droit',
        poseType: 'stand', duration: 2, points: 10, difficulty: 1,
        instructions: ['1. Redresse ton dos', '2. Regarde devant toi', '3. Reste immobile'],
      ),
      RhythmMovement(
        id: 'arms_up', name: 'Bras levés', emoji: '🙆', 
        description: 'Lève les bras au-dessus de la tête',
        poseType: 'arms_up', duration: 3, points: 20, difficulty: 1,
        instructions: ['1. Tiens-toi droit', '2. Lève les bras vers le ciel', '3. Reste comme ça 3 secondes'],
      ),
      RhythmMovement(
        id: 'arms_down', name: 'Bras baissés', emoji: '🙅',
        description: 'Baisse les bras le long du corps',
        poseType: 'arms_down', duration: 2, points: 20, difficulty: 1,
        instructions: ['1. Relâche les bras', '2. Laisse-les pendre naturellement', '3. Détends-toi'],
      ),
      RhythmMovement(
        id: 'clap', name: 'Applaudir', emoji: '👏',
        description: 'Applaudis des mains',
        poseType: 'clap', duration: 2, points: 20, difficulty: 1,
        instructions: ['1. Rapproche tes mains', '2. Tape dans tes mains', '3. Fais-le 3 fois'],
      ),
      RhythmMovement(
        id: 'jump', name: 'Sauter', emoji: '🦘',
        description: 'Fais un petit saut sur place',
        poseType: 'jump', duration: 1, points: 20, difficulty: 1,
        instructions: ['1. Fléchis légèrement les genoux', '2. Pousse sur tes jambes', '3. Atterris en douceur'],
      ),
      RhythmMovement(
        id: 'turn_left', name: 'Tourner à gauche', emoji: '🔄',
        description: 'Tourne-toi vers la gauche',
        poseType: 'turn_left', duration: 2, points: 20, difficulty: 1,
        instructions: ['1. Regarde ta gauche', '2. Tourne tout ton corps', '3. Reviens face caméra'],
      ),
      RhythmMovement(
        id: 'turn_right', name: 'Tourner à droite', emoji: '🔄',
        description: 'Tourne-toi vers la droite',
        poseType: 'turn_right', duration: 2, points: 20, difficulty: 1,
        instructions: ['1. Regarde ta droite', '2. Tourne tout ton corps', '3. Reviens face caméra'],
      ),
      RhythmMovement(
        id: 'head_left', name: 'Tourner la tête à gauche', emoji: '👈',
        description: 'Tourne la tête vers la gauche',
        poseType: 'head_left', duration: 2, points: 15, difficulty: 1,
        instructions: ['1. Regarde à gauche', '2. Tourne seulement la tête', '3. Reviens face caméra'],
      ),
      RhythmMovement(
        id: 'head_right', name: 'Tourner la tête à droite', emoji: '👉',
        description: 'Tourne la tête vers la droite',
        poseType: 'head_right', duration: 2, points: 15, difficulty: 1,
        instructions: ['1. Regarde à droite', '2. Tourne seulement la tête', '3. Reviens face caméra'],
      ),
      RhythmMovement(
        id: 'wave', name: 'Faire coucou', emoji: '👋',
        description: 'Fais coucou de la main',
        poseType: 'wave', duration: 2, points: 15, difficulty: 1,
        instructions: ['1. Lève une main', '2. Agite-la', '3. Souris à la caméra'],
      ),
      
      // ==================== NIVEAU 2 - Mouvements simples (10 mouvements) ====================
      RhythmMovement(
        id: 'arms_cross', name: 'Bras croisés', emoji: '🙅‍♂️',
        description: 'Croise les bras sur la poitrine',
        poseType: 'arms_cross', duration: 3, points: 30, difficulty: 2,
        instructions: ['1. Lève les bras', '2. Croise-les devant toi', '3. Tiens la position'],
      ),
      RhythmMovement(
        id: 'balance_left', name: 'Équilibre gauche', emoji: '🧘',
        description: 'Tiens-toi sur une jambe (gauche)',
        poseType: 'balance_left', duration: 4, points: 30, difficulty: 2,
        instructions: ['1. Lève ta jambe gauche', '2. Trouve ton équilibre', '3. Tiens la position'],
      ),
      RhythmMovement(
        id: 'balance_right', name: 'Équilibre droite', emoji: '🧘‍♀️',
        description: 'Tiens-toi sur une jambe (droite)',
        poseType: 'balance_right', duration: 4, points: 30, difficulty: 2,
        instructions: ['1. Lève ta jambe droite', '2. Trouve ton équilibre', '3. Tiens la position'],
      ),
      RhythmMovement(
        id: 'touch_toes', name: 'Toucher pieds', emoji: '🤸',
        description: 'Penche-toi pour toucher tes pieds',
        poseType: 'touch_toes', duration: 3, points: 30, difficulty: 2,
        instructions: ['1. Penche-toi lentement', '2. Tente de toucher tes pieds', '3. Remonte doucement'],
      ),
      RhythmMovement(
        id: 'wave_arms', name: 'Agiter bras', emoji: '👋',
        description: 'Agite les bras de haut en bas',
        poseType: 'wave_arms', duration: 3, points: 30, difficulty: 2,
        instructions: ['1. Lève un bras', '2. Agite-le de haut en bas', '3. Alterne avec l\'autre'],
      ),
      RhythmMovement(
        id: 'hands_on_hips', name: 'Mains sur les hanches', emoji: '💃',
        description: 'Mets les mains sur les hanches',
        poseType: 'hands_on_hips', duration: 3, points: 25, difficulty: 2,
        instructions: ['1. Place tes mains sur les hanches', '2. Tiens-toi droit', '3. Reste immobile'],
      ),
      RhythmMovement(
        id: 'look_up', name: 'Regarder en l\'air', emoji: '🙂↕️',
        description: 'Lève la tête vers le ciel',
        poseType: 'look_up', duration: 2, points: 20, difficulty: 2,
        instructions: ['1. Lève la tête', '2. Regarde vers le haut', '3. Ne bouge pas le corps'],
      ),
      RhythmMovement(
        id: 'look_down', name: 'Regarder par terre', emoji: '🙂↕️',
        description: 'Baisse la tête vers le sol',
        poseType: 'look_down', duration: 2, points: 20, difficulty: 2,
        instructions: ['1. Baisse la tête', '2. Regarde tes pieds', '3. Ne bouge pas le corps'],
      ),
      RhythmMovement(
        id: 'one_arm_up', name: 'Un bras levé', emoji: '💪',
        description: 'Lève un seul bras',
        poseType: 'one_arm_up', duration: 3, points: 25, difficulty: 2,
        instructions: ['1. Choisis un bras', '2. Lève-le vers le ciel', '3. L\'autre reste baissé'],
      ),
      RhythmMovement(
        id: 'victory', name: 'Signe de victoire', emoji: '✌️',
        description: 'Fais le signe V de la victoire',
        poseType: 'victory', duration: 3, points: 25, difficulty: 2,
        instructions: ['1. Lève deux doigts', '2. Fais le signe V', '3. Souris à la caméra'],
      ),
      
      // ==================== NIVEAU 3 - Mouvements moyens (10 mouvements) ====================
      RhythmMovement(
        id: 'squat', name: 'Squat', emoji: '🏋️',
        description: 'Fais un squat (position assise)',
        poseType: 'squat', duration: 4, points: 40, difficulty: 3,
        instructions: ['1. Écarte les jambes', '2. Fléchis les genoux', '3. Descends comme pour t\'asseoir'],
      ),
      RhythmMovement(
        id: 'lunges', name: 'Fente', emoji: '🤸‍♂️',
        description: 'Fais une fente avant',
        poseType: 'lunges', duration: 4, points: 40, difficulty: 3,
        instructions: ['1. Avance une jambe', '2. Fléchis les deux genoux', '3. Remonte en position'],
      ),
      RhythmMovement(
        id: 'star_jump', name: 'Étoile', emoji: '⭐',
        description: 'Fais un saut en étoile',
        poseType: 'star_jump', duration: 2, points: 40, difficulty: 3,
        instructions: ['1. Saute en écartant bras et jambes', '2. Forme une étoile', '3. Atterris en douceur'],
      ),
      RhythmMovement(
        id: 'bend_back', name: 'Cambrer', emoji: '🧘‍♂️',
        description: 'Cambre le dos vers l\'arrière',
        poseType: 'bend_back', duration: 3, points: 40, difficulty: 3,
        instructions: ['1. Place les mains sur les hanches', '2. Incline-toi doucement en arrière', '3. Reviens lentement'],
      ),
      RhythmMovement(
        id: 'circle_arms', name: 'Cercle bras', emoji: '🔄',
        description: 'Fais des cercles avec les bras',
        poseType: 'circle_arms', duration: 5, points: 40, difficulty: 3,
        instructions: ['1. Lève les bras sur les côtés', '2. Fais des petits cercles', '3. Accélère progressivement'],
      ),
      RhythmMovement(
        id: 'side_bend', name: 'Inclinaison latérale', emoji: '🧘',
        description: 'Incline-toi sur le côté',
        poseType: 'side_bend', duration: 4, points: 35, difficulty: 3,
        instructions: ['1. Lève un bras', '2. Incline-toi sur le côté', '3. Reviens au centre'],
      ),
      RhythmMovement(
        id: 'arms_out', name: 'Bras en croix', emoji: '✝️',
        description: 'Écarte les bras sur les côtés',
        poseType: 'arms_out', duration: 3, points: 30, difficulty: 3,
        instructions: ['1. Lève les bras sur les côtés', '2. Forme une croix', '3. Tiens la position'],
      ),
      RhythmMovement(
        id: 'leg_raise', name: 'Jambe levée', emoji: '🦵',
        description: 'Lève une jambe vers l\'avant',
        poseType: 'leg_raise', duration: 4, points: 35, difficulty: 3,
        instructions: ['1. Tiens-toi à un mur', '2. Lève une jambe', '3. Tiens l\'équilibre'],
      ),
      RhythmMovement(
        id: 'twist', name: 'Rotation du torse', emoji: '🔄',
        description: 'Tourne le haut du corps',
        poseType: 'twist', duration: 3, points: 30, difficulty: 3,
        instructions: ['1. Garde les jambes fixes', '2. Tourne le torse', '3. Alterne les côtés'],
      ),
      RhythmMovement(
        id: 'heel_raise', name: 'Sur la pointe des pieds', emoji: '🦶',
        description: 'Monte sur la pointe des pieds',
        poseType: 'heel_raise', duration: 3, points: 30, difficulty: 3,
        instructions: ['1. Monte sur la pointe des pieds', '2. Tiens l\'équilibre', '3. Redescends doucement'],
      ),
      
      // ==================== NIVEAU 4 - Mouvements avancés (10 mouvements) ====================
      RhythmMovement(
        id: 'push_up', name: 'Pompes', emoji: '💪',
        description: 'Fais une pompe',
        poseType: 'push_up', duration: 5, points: 50, difficulty: 4,
        instructions: ['1. Mets-toi à quatre pattes', '2. Plie les bras', '3. Remonte en poussant'],
      ),
      RhythmMovement(
        id: 'plank', name: 'Gainage', emoji: '🧘',
        description: 'Tiens la position de planche',
        poseType: 'plank', duration: 6, points: 50, difficulty: 4,
        instructions: ['1. Mets-toi sur les coudes', '2. Soulève le corps', '3. Tiens la position'],
      ),
      RhythmMovement(
        id: 'crunches', name: 'Abdos', emoji: '💪',
        description: 'Fais des abdos',
        poseType: 'crunches', duration: 5, points: 50, difficulty: 4,
        instructions: ['1. Allonge-toi sur le dos', '2. Plie les genoux', '3. Soulève la tête et les épaules'],
      ),
      RhythmMovement(
        id: 'mountain_climber', name: 'Mountain climber', emoji: '⛰️',
        description: 'Monte les genoux en position de pompe',
        poseType: 'mountain_climber', duration: 5, points: 55, difficulty: 4,
        instructions: ['1. Mets-toi en position de pompe', '2. Alterne les genoux', '3. Garde le dos droit'],
      ),
      RhythmMovement(
        id: 'burpee', name: 'Burpee', emoji: '🤸',
        description: 'Fais un burpee complet',
        poseType: 'burpee', duration: 6, points: 60, difficulty: 4,
        instructions: ['1. Accroupis-toi', '2. Mets-toi en pompe', '3. Saute en l\'air'],
      ),
      RhythmMovement(
        id: 'jumping_jack', name: 'Jumping jack', emoji: '⭐',
        description: 'Fais des jumping jacks',
        poseType: 'jumping_jack', duration: 4, points: 45, difficulty: 4,
        instructions: ['1. Saute en écartant les jambes', '2. Lève les bras', '3. Referme en sautant'],
      ),
      RhythmMovement(
        id: 'high_knees', name: 'Genoux hauts', emoji: '🏃',
        description: 'Monte les genoux en courant sur place',
        poseType: 'high_knees', duration: 5, points: 45, difficulty: 4,
        instructions: ['1. Cours sur place', '2. Monte les genoux haut', '3. Alterne rapidement'],
      ),
      RhythmMovement(
        id: 'butt_kicks', name: 'Talons fesses', emoji: '🦵',
        description: 'Touche tes fesses avec les talons',
        poseType: 'butt_kicks', duration: 5, points: 40, difficulty: 4,
        instructions: ['1. Cours sur place', '2. Ramène les talons aux fesses', '3. Alterne rapidement'],
      ),
      RhythmMovement(
        id: 'lateral_raise', name: 'Élévation latérale', emoji: '💪',
        description: 'Lève les bras sur les côtés avec des poids',
        poseType: 'lateral_raise', duration: 4, points: 40, difficulty: 4,
        instructions: ['1. Prends des petits poids', '2. Lève les bras sur les côtés', '3. Redescends doucement'],
      ),
      RhythmMovement(
        id: 'shoulder_press', name: 'Développé épaules', emoji: '🏋️',
        description: 'Pousse les bras vers le haut',
        poseType: 'shoulder_press', duration: 4, points: 40, difficulty: 4,
        instructions: ['1. Plie les coudes à 90°', '2. Pousse les bras vers le haut', '3. Redescends en contrôle'],
      ),
      
      // ==================== NIVEAU 5 - Mouvements experts (10 mouvements) ====================
      RhythmMovement(
        id: 'handstand', name: 'Poirier', emoji: '🤸',
        description: 'Tiens-toi sur les mains',
        poseType: 'handstand', duration: 8, points: 80, difficulty: 5,
        instructions: ['1. Place les mains au sol', '2. Lance les jambes en l\'air', '3. Tiens l\'équilibre'],
      ),
      RhythmMovement(
        id: 'cartwheel', name: 'Roue', emoji: '🤸‍♀️',
        description: 'Fais la roue',
        poseType: 'cartwheel', duration: 5, points: 75, difficulty: 5,
        instructions: ['1. Lève un bras', '2. Pose la main au sol', '3. Passe les jambes par-dessus'],
      ),
      RhythmMovement(
        id: 'bridge', name: 'Pont', emoji: '🌉',
        description: 'Fais le pont',
        poseType: 'bridge', duration: 6, points: 70, difficulty: 5,
        instructions: ['1. Allonge-toi sur le dos', '2. Plie les genoux', '3. Soulève le bassin'],
      ),
      RhythmMovement(
        id: 'split', name: 'Grand écart', emoji: '🧘',
        description: 'Fais le grand écart',
        poseType: 'split', duration: 6, points: 75, difficulty: 5,
        instructions: ['1. Glisse les jambes', '2. Écarte-les progressivement', '3. Tiens la position'],
      ),
      RhythmMovement(
        id: 'yoga_tree', name: 'Arbre (yoga)', emoji: '🌳',
        description: 'Fais la posture de l\'arbre',
        poseType: 'yoga_tree', duration: 5, points: 50, difficulty: 5,
        instructions: ['1. Lève un pied', '2. Place-le contre la cuisse', '3. Joins les mains'],
      ),
      RhythmMovement(
        id: 'yoga_down_dog', name: 'Chien tête en bas', emoji: '🐕',
        description: 'Fais la posture du chien',
        poseType: 'yoga_down_dog', duration: 5, points: 50, difficulty: 5,
        instructions: ['1. Mets-toi à quatre pattes', '2. Soulève le bassin', '3. Forme un V inversé'],
      ),
      RhythmMovement(
        id: 'yoga_cobra', name: 'Cobra', emoji: '🐍',
        description: 'Fais la posture du cobra',
        poseType: 'yoga_cobra', duration: 4, points: 45, difficulty: 5,
        instructions: ['1. Allonge-toi sur le ventre', '2. Pousse sur les mains', '3. Cambre le dos'],
      ),
      RhythmMovement(
        id: 'yoga_warrior', name: 'Guerrier', emoji: '⚔️',
        description: 'Fais la posture du guerrier',
        poseType: 'yoga_warrior', duration: 5, points: 50, difficulty: 5,
        instructions: ['1. Avance une jambe', '2. Plie le genou', '3. Lève les bras'],
      ),
      RhythmMovement(
        id: 'dance_twist', name: 'Twist de danse', emoji: '💃',
        description: 'Fais un mouvement de danse',
        poseType: 'dance_twist', duration: 4, points: 45, difficulty: 5,
        instructions: ['1. Bouge les hanches', '2. Tourne le corps', '3. Laisse-toi aller'],
      ),
      RhythmMovement(
        id: 'free_style', name: 'Style libre', emoji: '🎉',
        description: 'Crée ton propre mouvement',
        poseType: 'free_style', duration: 6, points: 60, difficulty: 5,
        instructions: ['1. Laisse parler ta créativité', '2. Fais un mouvement unique', '3. Prends la pose'],
      ),
      
      // ==================== NIVEAU 6 - Mouvements spéciaux (10 mouvements) ====================
      RhythmMovement(
        id: 'jump_rope', name: 'Corde à sauter', emoji: '🪢',
        description: 'Simule la corde à sauter',
        poseType: 'jump_rope', duration: 5, points: 55, difficulty: 6,
        instructions: ['1. Saute sur place', '2. Fais des petits sauts', '3. Tourne les poignets'],
      ),
      RhythmMovement(
        id: 'boxing_punch', name: 'Coup de poing', emoji: '🥊',
        description: 'Fais un mouvement de boxe',
        poseType: 'boxing_punch', duration: 4, points: 50, difficulty: 6,
        instructions: ['1. Garde les poings levés', '2. Lance un direct', '3. Alterne les bras'],
      ),
      RhythmMovement(
        id: 'karate_kick', name: 'Coup de pied', emoji: '🥋',
        description: 'Fais un coup de pied',
        poseType: 'karate_kick', duration: 4, points: 55, difficulty: 6,
        instructions: ['1. Trouve ton équilibre', '2. Lève la jambe', '3. Tire un coup de pied'],
      ),
      RhythmMovement(
        id: 'ballet_pose', name: 'Pose de ballet', emoji: '🩰',
        description: 'Fais une pose de danse classique',
        poseType: 'ballet_pose', duration: 5, points: 50, difficulty: 6,
        instructions: ['1. Tiens-toi droite', '2. Lève les bras en rond', '3. Mets-toi sur la pointe'],
      ),
      RhythmMovement(
        id: 'surfing', name: 'Surfer', emoji: '🏄',
        description: 'Fais le mouvement du surf',
        poseType: 'surfing', duration: 4, points: 50, difficulty: 6,
        instructions: ['1. Penche-toi légèrement', '2. Simule la planche', '3. Balance-toi doucement'],
      ),
      RhythmMovement(
        id: 'skiing', name: 'Skier', emoji: '⛷️',
        description: 'Fais le mouvement du ski',
        poseType: 'skiing', duration: 4, points: 50, difficulty: 6,
        instructions: ['1. Accroupis-toi légèrement', '2. Simule les bâtons', '3. Glisse d\'un côté à l\'autre'],
      ),
      RhythmMovement(
        id: 'swimming', name: 'Nager', emoji: '🏊',
        description: 'Fais le mouvement de nage',
        poseType: 'swimming', duration: 5, points: 50, difficulty: 6,
        instructions: ['1. Penche-toi en avant', '2. Alterne les bras', '3. Tourne la tête'],
      ),
      RhythmMovement(
        id: 'hula_hoop', name: 'Hula hoop', emoji: '🔄',
        description: 'Fais tourner un cerceau imaginaire',
        poseType: 'hula_hoop', duration: 5, points: 45, difficulty: 6,
        instructions: ['1. Bouge les hanches en rond', '2. Imagine un cerceau', '3. Accélère le mouvement'],
      ),
      RhythmMovement(
        id: 'robot_dance', name: 'Danse robot', emoji: '🤖',
        description: 'Fais le robot',
        poseType: 'robot_dance', duration: 4, points: 50, difficulty: 6,
        instructions: ['1. Bouge par à-coups', '2. Fais des angles', '3. Imite un robot'],
      ),
      RhythmMovement(
        id: 'moonwalk', name: 'Moonwalk', emoji: '🕺',
        description: 'Fais le moonwalk de Michael Jackson',
        poseType: 'moonwalk', duration: 5, points: 60, difficulty: 6,
        instructions: ['1. Glisse un pied en arrière', '2. Transfère le poids', '3. Glisse l\'autre pied'],
      ),
    ];
  }

  static List<RhythmMovement> getMovementsByDifficulty(int difficulty) {
    return getAllMovements().where((m) => m.difficulty == difficulty).toList();
  }
  
  static int getMaxDifficulty() {
    return 6;
  }
  
  static Map<int, List<RhythmMovement>> getMovementsByLevel() {
    final Map<int, List<RhythmMovement>> levels = {};
    for (int i = 1; i <= getMaxDifficulty(); i++) {
      levels[i] = getMovementsByDifficulty(i);
    }
    return levels;
  }
  
  static int getTotalMovementsCount() {
    return getAllMovements().length;
  }
  
  static Map<String, dynamic> getStatistics() {
    final movements = getAllMovements();
    return {
      'totalMovements': movements.length,
      'totalDifficulties': getMaxDifficulty(),
      'movementsByDifficulty': {
        for (int i = 1; i <= getMaxDifficulty(); i++)
          'Niveau $i': getMovementsByDifficulty(i).length,
      },
      'averagePoints': movements.fold(0, (sum, m) => sum + m.points) / movements.length,
    };
  }
}

class RhythmSequence {
  final int id;
  final int level;
  final List<RhythmMovement> movements;
  final int totalPoints;

  RhythmSequence({
    required this.id,
    required this.level,
    required this.movements,
    required this.totalPoints,
  });

  static List<RhythmSequence> generateSequences() {
    final sequences = <RhythmSequence>[];
    var id = 1;
    
    // Niveau 1: 5 séquences de 3 mouvements (15 mouvements)
    final level1Movements = RhythmMovement.getMovementsByDifficulty(1);
    sequences.add(RhythmSequence(
      id: id++, level: 1,
      movements: level1Movements.take(3).toList(),
      totalPoints: 60,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 1,
      movements: level1Movements.skip(2).take(3).toList(),
      totalPoints: 60,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 1,
      movements: level1Movements.skip(4).take(3).toList(),
      totalPoints: 60,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 1,
      movements: level1Movements.skip(6).take(3).toList(),
      totalPoints: 60,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 1,
      movements: level1Movements.skip(8).take(3).toList(),
      totalPoints: 60,
    ));
    
    // Niveau 2: 5 séquences de 4 mouvements (20 mouvements)
    final level2Movements = RhythmMovement.getMovementsByDifficulty(2);
    sequences.add(RhythmSequence(
      id: id++, level: 2,
      movements: level2Movements.take(4).toList(),
      totalPoints: 120,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 2,
      movements: level2Movements.skip(3).take(4).toList(),
      totalPoints: 120,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 2,
      movements: level2Movements.skip(6).take(4).toList(),
      totalPoints: 120,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 2,
      movements: level2Movements.skip(9).take(4).toList(),
      totalPoints: 120,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 2,
      movements: level2Movements.skip(12).take(4).toList(),
      totalPoints: 120,
    ));
    
    // Niveau 3: 5 séquences de 5 mouvements (25 mouvements)
    final level3Movements = RhythmMovement.getMovementsByDifficulty(3);
    sequences.add(RhythmSequence(
      id: id++, level: 3,
      movements: level3Movements.take(5).toList(),
      totalPoints: 200,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 3,
      movements: level3Movements.skip(4).take(5).toList(),
      totalPoints: 200,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 3,
      movements: level3Movements.skip(8).take(5).toList(),
      totalPoints: 200,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 3,
      movements: level3Movements.skip(12).take(5).toList(),
      totalPoints: 200,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 3,
      movements: level3Movements.skip(16).take(5).toList(),
      totalPoints: 200,
    ));
    
    // Niveau 4: 5 séquences de 6 mouvements (30 mouvements)
    final level4Movements = RhythmMovement.getMovementsByDifficulty(4);
    sequences.add(RhythmSequence(
      id: id++, level: 4,
      movements: level4Movements.take(6).toList(),
      totalPoints: 300,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 4,
      movements: level4Movements.skip(5).take(6).toList(),
      totalPoints: 300,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 4,
      movements: level4Movements.skip(10).take(6).toList(),
      totalPoints: 300,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 4,
      movements: level4Movements.skip(15).take(6).toList(),
      totalPoints: 300,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 4,
      movements: level4Movements.skip(20).take(6).toList(),
      totalPoints: 300,
    ));
    
    // Niveau 5: 5 séquences de 7 mouvements (35 mouvements)
    final level5Movements = RhythmMovement.getMovementsByDifficulty(5);
    sequences.add(RhythmSequence(
      id: id++, level: 5,
      movements: level5Movements.take(7).toList(),
      totalPoints: 350,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 5,
      movements: level5Movements.skip(6).take(7).toList(),
      totalPoints: 350,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 5,
      movements: level5Movements.skip(12).take(7).toList(),
      totalPoints: 350,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 5,
      movements: level5Movements.skip(18).take(7).toList(),
      totalPoints: 350,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 5,
      movements: level5Movements.skip(24).take(7).toList(),
      totalPoints: 350,
    ));
    
    // Niveau 6: 5 séquences de 8 mouvements (40 mouvements)
    final level6Movements = RhythmMovement.getMovementsByDifficulty(6);
    sequences.add(RhythmSequence(
      id: id++, level: 6,
      movements: level6Movements.take(8).toList(),
      totalPoints: 400,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 6,
      movements: level6Movements.skip(7).take(8).toList(),
      totalPoints: 400,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 6,
      movements: level6Movements.skip(14).take(8).toList(),
      totalPoints: 400,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 6,
      movements: level6Movements.skip(21).take(8).toList(),
      totalPoints: 400,
    ));
    sequences.add(RhythmSequence(
      id: id++, level: 6,
      movements: level6Movements.skip(28).take(8).toList(),
      totalPoints: 400,
    ));
    
    return sequences;
  }
  
  static List<RhythmSequence> getSequencesByLevel(int level) {
    return generateSequences().where((s) => s.level == level).toList();
  }
  
  static int getTotalSequencesCount() {
    return generateSequences().length;
  }
}
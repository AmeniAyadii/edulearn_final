// lib/services/pose_detection_service.dart
import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/rhythm_movement.dart';

class PoseDetectionService {
  final PoseDetector _poseDetector;
  
  PoseDetectionService()
      : _poseDetector = PoseDetector(
          options: PoseDetectorOptions(
            mode: PoseDetectionMode.stream,
          ),
        );

  Future<Map<String, dynamic>> detectPose(File imageFile, RhythmMovement targetMovement) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final List<Pose> poses = await _poseDetector.processImage(inputImage);
      
      if (poses.isEmpty) {
        return {
          'isMatch': false,
          'confidence': 0.0,
          'message': 'Aucun corps détecté',
          'suggestions': ['📸 Place-toi bien dans le cadre', '💡 Assure-toi d\'être bien éclairé'],
        };
      }
      
      final pose = poses.first;
      final isMatch = _analyzePose(pose, targetMovement);
      final confidence = _calculateConfidence(pose, targetMovement);
      
      if (isMatch) {
        return {
          'isMatch': true,
          'confidence': confidence,
          'message': '🎯 Parfait ! Mouvement correct !',
          'bonus': confidence > 0.8 ? 15 : (confidence > 0.6 ? 10 : 5),
        };
      } else {
        return {
          'isMatch': false,
          'confidence': confidence,
          'message': '❌ Mouvement incorrect',
          'suggestions': targetMovement.instructions,
          'detectedPose': _getDetectedPoseDescription(pose),
        };
      }
    } catch (e) {
      print('Erreur détection pose: $e');
      return {
        'isMatch': false,
        'confidence': 0.0,
        'message': 'Erreur de détection',
        'error': e.toString(),
      };
    }
  }

  bool _analyzePose(Pose pose, RhythmMovement targetMovement) {
    switch (targetMovement.poseType) {
      case 'arms_up':
        return _isArmsUp(pose);
      case 'arms_down':
        return _isArmsDown(pose);
      case 'clap':
        return _isClapping(pose);
      case 'jump':
        return _isJumping(pose);
      case 'turn_left':
        return _isTurningLeft(pose);
      case 'arms_cross':
        return _isArmsCrossed(pose);
      case 'balance_left':
        return _isBalancingLeft(pose);
      case 'balance_right':
        return _isBalancingRight(pose);
      case 'touch_toes':
        return _isTouchingToes(pose);
      case 'wave_arms':
        return _isWavingArms(pose);
      case 'squat':
        return _isSquatting(pose);
      case 'lunges':
        return _isLunging(pose);
      case 'star_jump':
        return _isStarJumping(pose);
      case 'bend_back':
        return _isBendingBack(pose);
      case 'circle_arms':
        return _isCirclingArms(pose);
      default:
        return false;
    }
  }

  double _calculateConfidence(Pose pose, RhythmMovement targetMovement) {
    double confidence = 0.7;
    
    switch (targetMovement.poseType) {
      case 'arms_up':
        if (_getArmAngle(pose) > 150) confidence += 0.2;
        break;
      case 'clap':
        if (_getHandDistance(pose) < 0.1) confidence += 0.2;
        break;
      case 'jump':
        if (_getLegAngle(pose) > 30) confidence += 0.2;
        break;
      case 'squat':
        if (_getLegAngle(pose) < 120) confidence += 0.2;
        break;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  bool _isArmsUp(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    
    if (leftShoulder == null || leftWrist == null || rightShoulder == null || rightWrist == null) {
      return false;
    }
    
    return leftWrist.y < leftShoulder.y && rightWrist.y < rightShoulder.y;
  }

  bool _isArmsDown(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    
    if (leftShoulder == null || leftWrist == null || rightShoulder == null || rightWrist == null) {
      return false;
    }
    
    return leftWrist.y > leftShoulder.y && rightWrist.y > rightShoulder.y;
  }

  bool _isClapping(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    
    if (leftWrist == null || rightWrist == null) return false;
    
    final distance = (leftWrist.x - rightWrist.x).abs();
    return distance < 0.1;
  }

  bool _isJumping(Pose pose) {
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    
    if (leftAnkle == null || rightAnkle == null || leftHip == null) return false;
    
    return leftAnkle.y < leftHip.y && rightAnkle.y < leftHip.y;
  }

  bool _isTurningLeft(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    
    if (leftShoulder == null || rightShoulder == null) return false;
    
    return leftShoulder.x < rightShoulder.x;
  }

  bool _isArmsCrossed(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    
    if (leftWrist == null || rightWrist == null) return false;
    
    return leftWrist.x > rightWrist.x;
  }

  bool _isBalancingLeft(Pose pose) {
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    
    if (leftAnkle == null || rightAnkle == null) return false;
    
    return leftAnkle.y > rightAnkle.y + 0.1;
  }

  bool _isBalancingRight(Pose pose) {
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    
    if (leftAnkle == null || rightAnkle == null) return false;
    
    return rightAnkle.y > leftAnkle.y + 0.1;
  }

  bool _isTouchingToes(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    
    if (leftWrist == null || leftAnkle == null || rightWrist == null || rightAnkle == null) {
      return false;
    }
    
    return (leftWrist.y - leftAnkle.y).abs() < 0.1 || (rightWrist.y - rightAnkle.y).abs() < 0.1;
  }

  bool _isWavingArms(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    
    if (leftWrist == null || rightWrist == null || leftShoulder == null || rightShoulder == null) {
      return false;
    }
    
    return (leftWrist.y < leftShoulder.y - 0.2) && (rightWrist.y < rightShoulder.y - 0.2);
  }

  bool _isSquatting(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    
    if (leftHip == null || leftKnee == null || leftAnkle == null || 
        rightHip == null || rightKnee == null || rightAnkle == null) {
      return false;
    }
    
    final leftAngle = _calculateAngleFromLandmarks(leftHip, leftKnee, leftAnkle);
    final rightAngle = _calculateAngleFromLandmarks(rightHip, rightKnee, rightAnkle);
    
    return leftAngle < 120 && rightAngle < 120;
  }

  bool _isLunging(Pose pose) {
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    
    if (leftKnee == null || rightKnee == null || leftHip == null || rightHip == null) {
      return false;
    }
    
    final leftAngle = _calculateAngleFromLandmarks(leftHip, leftKnee, leftKnee);
    final rightAngle = _calculateAngleFromLandmarks(rightHip, rightKnee, rightKnee);
    
    return (leftAngle < 100 && rightAngle > 160) || (rightAngle < 100 && leftAngle > 160);
  }

  bool _isStarJumping(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    
    if (leftWrist == null || rightWrist == null || leftAnkle == null || rightAnkle == null ||
        leftShoulder == null || rightShoulder == null) {
      return false;
    }
    
    final armsSpread = leftWrist.x < leftShoulder.x - 0.3 && rightWrist.x > rightShoulder.x + 0.3;
    final legsSpread = leftAnkle.x < leftShoulder.x - 0.2 && rightAnkle.x > rightShoulder.x + 0.2;
    
    return armsSpread && legsSpread;
  }

  bool _isBendingBack(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    
    if (leftShoulder == null || leftHip == null || rightShoulder == null || rightHip == null) {
      return false;
    }
    
    return leftShoulder.y > leftHip.y && rightShoulder.y > rightHip.y;
  }

  bool _isCirclingArms(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    
    if (leftWrist == null || rightWrist == null || leftShoulder == null || rightShoulder == null) {
      return false;
    }
    
    return (leftWrist.y < leftShoulder.y - 0.1) && (rightWrist.y < rightShoulder.y - 0.1);
  }

  double _getArmAngle(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    
    if (leftShoulder == null || leftElbow == null || leftWrist == null) return 0;
    
    return _calculateAngleFromLandmarks(leftShoulder, leftElbow, leftWrist);
  }

  double _getLegAngle(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    
    if (leftHip == null || leftKnee == null || leftAnkle == null) return 0;
    
    return _calculateAngleFromLandmarks(leftHip, leftKnee, leftAnkle);
  }

  double _getHandDistance(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    
    if (leftWrist == null || rightWrist == null) return double.infinity;
    
    return (leftWrist.x - rightWrist.x).abs();
  }

  // Méthode principale pour calculer l'angle entre trois landmarks
  double _calculateAngleFromLandmarks(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    // Vecteur AB
    final abX = a.x - b.x;
    final abY = a.y - b.y;
    
    // Vecteur CB
    final cbX = c.x - b.x;
    final cbY = c.y - b.y;
    
    // Produit scalaire
    final dot = abX * cbX + abY * cbY;
    
    // Normes
    final abNorm = sqrt(abX * abX + abY * abY);
    final cbNorm = sqrt(cbX * cbX + cbY * cbY);
    
    if (abNorm == 0 || cbNorm == 0) return 0;
    
    // Cosinus de l'angle
    final cosAngle = dot / (abNorm * cbNorm);
    
    // Angle en radians puis en degrés
    final angleRad = acos(cosAngle.clamp(-1.0, 1.0));
    return angleRad * 180 / pi;
  }

  String _getDetectedPoseDescription(Pose pose) {
    if (_isArmsUp(pose)) return 'bras levés';
    if (_isClapping(pose)) return 'applaudissements';
    if (_isJumping(pose)) return 'saut';
    if (_isSquatting(pose)) return 'squat';
    if (_isArmsDown(pose)) return 'bras baissés';
    if (_isArmsCrossed(pose)) return 'bras croisés';
    if (_isWavingArms(pose)) return 'bras qui bougent';
    if (_isBendingBack(pose)) return 'cambré';
    return 'position détectée';
  }

  Future<Map<String, dynamic>> detectSequence(List<File> images, List<RhythmMovement> targetMovements) async {
    int successCount = 0;
    for (int i = 0; i < images.length && i < targetMovements.length; i++) {
      final result = await detectPose(images[i], targetMovements[i]);
      if (result['isMatch'] == true) successCount++;
    }
    
    final accuracy = successCount / targetMovements.length;
    
    return {
      'success': true,
      'accuracy': accuracy,
      'message': accuracy > 0.8 ? '🌟 Séquence parfaite !' : '👍 Bon travail !',
      'bonusPoints': (accuracy * 50).toInt(),
    };
  }

  void dispose() {
    _poseDetector.close();
  }
}
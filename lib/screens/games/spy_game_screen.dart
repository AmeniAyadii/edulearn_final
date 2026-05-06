// lib/screens/games/spy_game_screen.dart
// VERSION CORRIGÉE AVEC GESTION PROPRE DE LA CAMÉRA

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class SpyGameScreen extends StatefulWidget {
  const SpyGameScreen({Key? key}) : super(key: key);

  @override
  State<SpyGameScreen> createState() => _SpyGameScreenState();
}

class _SpyGameScreenState extends State<SpyGameScreen> with TickerProviderStateMixin {
  // Services ML Kit
  late FaceDetector _faceDetector;
  late PoseDetector _poseDetector;
  
  // Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _isCameraInitializing = false;
  
  // États du jeu
  int _score = 0;
  int _combo = 0;
  int _level = 1;
  int _maxCombo = 0;
  String _currentMission = "Détecter un visage";
  String _feedback = "Placez votre visage devant la caméra";
  
  // Données détectées
  bool _faceDetected = false;
  bool _poseDetected = false;
  String _detectedPose = "";
  String _currentExpression = "";
  
  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Son et préférences
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _soundEnabled = true;
  
  // Statistiques
  int _successfulMissions = 0;
  int _totalDetections = 0;
  
  // Timer pour les missions
  double _missionProgress = 0.0;
  int _timeLeft = 30;
  
  // Contrôle de taux
  DateTime _lastProcessTime = DateTime.now();
  bool _isProcessing = false;
  
  // Cache des derniers résultats
  bool _lastFaceState = false;
  String _lastPoseState = "";
  int _lastScoreIncrementFrame = 0;
  
  Timer? _gameTimer;
  bool _isGameActive = true;
  
  // Missions disponibles
  final List<Mission> _missions = [
    Mission(id: 'face', title: 'Détecter un visage', description: 'Place ton visage devant la caméra', icon: Icons.face, points: 100, color: Colors.blue),
    Mission(id: 'smile', title: 'Faire un sourire', description: 'Montre ton plus beau sourire', icon: Icons.emoji_emotions, points: 150, color: Colors.amber),
    Mission(id: 'spy_pose', title: 'Posture d\'espion', description: 'Penche-toi comme un agent secret', icon: Icons.shield, points: 200, color: Colors.purple),
    Mission(id: 'arms_up', title: 'Bras levés', description: 'Lève les deux bras en l\'air', icon: Icons.accessibility_new, points: 120, color: Colors.orange),
  ];
  
  Mission get _currentMissionObject => _missions.firstWhere(
    (m) => m.title == _currentMission,
    orElse: () => _missions[0],
  );

  @override
  void initState() {
    super.initState();
    _initializeMLServices();
    _initializeCamera();
    _loadSettings();
    _initializeAnimations();
    _startGameTimer();
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isGameActive) {
        timer.cancel();
        return;
      }
      
      if (_timeLeft > 0 && _isCameraReady) {
        setState(() {
          _timeLeft--;
          _missionProgress = (30 - _timeLeft) / 30;
        });
        
        if (_timeLeft == 10 && _combo > 0) {
          setState(() {
            _feedback = "⚠️ Plus que 10 secondes !";
            _combo = 0;
          });
        }
      } else if (_timeLeft == 0 && mounted) {
        timer.cancel();
        _endMission();
      }
    });
  }
  
  Future<void> _initializeMLServices() async {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);
    
    final poseOptions = PoseDetectorOptions(
      mode: PoseDetectionMode.single,
    );
    _poseDetector = PoseDetector(options: poseOptions);
  }
  
  Future<void> _initializeCamera() async {
    if (_isCameraInitializing) return;
    _isCameraInitializing = true;
    
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // ✅ Choisir la caméra avant (selfie) pour meilleure expérience
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras![0],
        );
        
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        
        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isCameraReady = true;
            _isCameraInitializing = false;
          });
          _startImageStream();
        }
      }
    } catch (e) {
      debugPrint("Erreur caméra: $e");
      if (mounted) {
        setState(() {
          _feedback = "Erreur: Impossible d'accéder à la caméra";
          _isCameraInitializing = false;
        });
      }
    }
  }
  
  void _startImageStream() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      _cameraController?.startImageStream(_processCameraImage);
    }
  }
  
  void _stopImageStream() {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController?.stopImageStream();
    }
  }
  
  Future<void> _processCameraImage(CameraImage image) async {
    if (!_isGameActive || _isProcessing) return;
    
    final now = DateTime.now();
    if (now.difference(_lastProcessTime).inMilliseconds < 200) return;
    
    _isProcessing = true;
    _lastProcessTime = now;
    
    try {
      final inputImage = await _convertCameraImageToInputImage(image);
      if (inputImage == null) return;
      
      final results = await Future.wait([
        _faceDetector.processImage(inputImage),
        _poseDetector.processImage(inputImage),
      ]);
      
      final faces = results[0] as List<Face>;
      final poses = results[1] as List<Pose>;
      
      if (mounted && _isGameActive) {
        _updateGameState(faces, poses);
      }
    } catch (e) {
      // Ignorer les erreurs de traitement
    } finally {
      _isProcessing = false;
    }
  }
  
  Future<InputImage?> _convertCameraImageToInputImage(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation90deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }
  
  void _updateGameState(List<Face> faces, List<Pose> poses) {
    final bool hasFace = faces.isNotEmpty;
    final bool hasPose = poses.isNotEmpty;
    
    String faceExpression = "";
    if (hasFace) {
      final face = faces.first;
      if (face.smilingProbability != null && face.smilingProbability! > 0.7) {
        faceExpression = "sourire";
      }
    }
    
    String detectedPoseType = "";
    if (hasPose && poses.first.landmarks.isNotEmpty) {
      detectedPoseType = _analyzePose(poses.first);
    }
    
    setState(() {
      _faceDetected = hasFace;
      _poseDetected = hasPose;
      _detectedPose = detectedPoseType;
      _currentExpression = faceExpression;
    });
    
    _checkMissionCompletion(hasFace, faceExpression, hasPose, detectedPoseType);
  }
  
  String _analyzePose(Pose pose) {
    try {
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
      final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
      
      if (leftWrist != null && rightWrist != null && leftShoulder != null && rightShoulder != null) {
        if (leftWrist.y < leftShoulder.y - 0.1 && rightWrist.y < rightShoulder.y - 0.1) {
          return "bras_levés";
        }
      }
      return "standard";
    } catch (e) {
      return "standard";
    }
  }
  
  void _checkMissionCompletion(bool hasFace, String expression, bool hasPose, String poseType) {
    bool missionComplete = false;
    int frameKey = DateTime.now().millisecondsSinceEpoch ~/ 500;
    
    if (_lastScoreIncrementFrame == frameKey) return;
    _lastScoreIncrementFrame = frameKey;
    
    switch (_currentMission) {
      case "Détecter un visage":
        if (hasFace && !_lastFaceState) {
          missionComplete = true;
          _updateFeedback("✅ Visage détecté !", Colors.green);
          _addScore(100);
        }
        break;
        
      case "Faire un sourire":
        if (expression == "sourire") {
          missionComplete = true;
          _updateFeedback("😊 Magnifique sourire !", Colors.amber);
          _addScore(150);
        }
        break;
        
      case "Posture d'espion":
        if (poseType == "bras_levés" && _lastPoseState != "bras_levés") {
          missionComplete = true;
          _updateFeedback("🕵️ Posture parfaite !", Colors.purple);
          _addScore(200);
        }
        break;
        
      case "Bras levés":
        if (poseType == "bras_levés" && _lastPoseState != "bras_levés") {
          missionComplete = true;
          _updateFeedback("🙌 Excellent !", Colors.orange);
          _addScore(120);
        }
        break;
    }
    
    if (missionComplete) {
      _pulseController.forward().then((_) => _pulseController.reverse());
      _successfulMissions++;
      _totalDetections++;
      
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _isGameActive) {
          setState(() {
            _nextMission();
          });
        }
      });
    }
    
    _lastFaceState = hasFace;
    _lastPoseState = poseType;
  }
  
  void _updateFeedback(String message, Color color) {
    setState(() {
      _feedback = message;
    });
    
    _playSound('success.mp3');
    _triggerVibration();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _feedback == message) {
        setState(() {
          _feedback = "En mission... Continuez !";
        });
      }
    });
  }
  
  void _addScore(int points) {
    setState(() {
      _score += points;
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;
      
      if (_combo > 1) {
        int bonus = points * (_combo - 1);
        _score += bonus;
        _feedback += " 🔥 Combo x$_combo ! +$bonus";
      }
      
      if (_score >= _level * 500) {
        _level++;
        _feedback = "🎉 PROMOTION ! Niveau $_level atteint 🎉";
        _playSound('levelup.mp3');
      }
    });
  }
  
  void _nextMission() {
    final List<String> missions = _missions.map((m) => m.title).toList();
    
    String newMission;
    do {
      newMission = missions[DateTime.now().millisecondsSinceEpoch % missions.length];
    } while (newMission == _currentMission && missions.length > 1);
    
    setState(() {
      _currentMission = newMission;
      _timeLeft = 30;
      _missionProgress = 0;
      _feedback = "🎯 Nouvelle mission : $_currentMission !";
    });
  }
  
  void _endMission() {
    _isGameActive = false;
    _stopImageStream();
    _playSound('mission_end.mp3');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: Colors.grey[900],
        title: const Text("Mission Terminée", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.cyan.shade800, Colors.cyan.shade600]),
                shape: BoxShape.circle,
              ),
              child: Text("$_score", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            _buildResultStat(Icons.emoji_events, "Niveau", "$_level", Colors.amber),
            const SizedBox(height: 10),
            _buildResultStat(Icons.check_circle, "Succès", "$_successfulMissions/${_totalDetections == 0 ? 1 : _totalDetections}", Colors.green),
            const SizedBox(height: 10),
            _buildResultStat(Icons.local_fire_department, "Meilleur combo", "x$_maxCombo", Colors.orange),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            icon: const Icon(Icons.replay, color: Colors.cyan),
            label: const Text("Rejouer", style: TextStyle(color: Colors.cyan)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.exit_to_app),
            label: const Text("Quitter"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultStat(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 15),
          Text(label, style: TextStyle(color: Colors.grey[400])),
          const Spacer(),
          Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
  
  void _resetGame() {
    _isGameActive = true;
    setState(() {
      _score = 0;
      _combo = 0;
      _level = 1;
      _maxCombo = 0;
      _successfulMissions = 0;
      _totalDetections = 0;
      _timeLeft = 30;
      _missionProgress = 0;
      _feedback = "Nouvelle mission ! Prêt ?";
      _lastFaceState = false;
      _lastPoseState = "";
      _currentMission = "Détecter un visage";
    });
    _startGameTimer();
    _startImageStream();
  }
  
  Future<void> _playSound(String soundFile) async {
    if (_soundEnabled) {
      try {
        await _audioPlayer.play(AssetSource('sounds/$soundFile'));
      } catch (e) {}
    }
  }
  
  Future<void> _triggerVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50);
    }
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    });
  }
  
  @override
  void dispose() {
    _isGameActive = false;
    _gameTimer?.cancel();
    _stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    _poseDetector.close();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildCameraSection()),
            _buildMissionPanel(),
            _buildStatsPanel(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.cyan.shade900, Colors.cyan.shade800]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.psychology, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("AGENT SECRET", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
                  Text("NIVEAU $_level", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 5),
                Text("$_score", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.cyan.shade900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCameraSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: (_faceDetected ? Colors.green : Colors.cyan).withOpacity(0.5), blurRadius: 20, spreadRadius: 5)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            if (_isCameraReady && _cameraController != null)
              CameraPreview(_cameraController!)
            else
              Container(
                color: Colors.grey[900],
                child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Initialisation de la caméra..."),
                ])),
              ),
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _faceDetected ? Colors.green : Colors.cyan, width: 3),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _faceDetected ? _pulseAnimation.value : 1.0,
                        child: Container(
                          margin: const EdgeInsets.all(15),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _faceDetected ? Colors.green : Colors.grey, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_faceDetected ? Icons.face : Icons.face_outlined, color: _faceDetected ? Colors.green : Colors.grey, size: 18),
                              const SizedBox(width: 5),
                              Icon(_poseDetected ? Icons.accessibility_new : Icons.accessibility, color: _poseDetected ? Colors.green : Colors.grey, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMissionPanel() {
    final mission = _currentMissionObject;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.grey[850]!, Colors.grey[900]!]),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: mission.color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: mission.color.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
                child: Icon(mission.icon, color: mission.color, size: 28),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mission.title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(mission.description, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _timeLeft < 10 ? Colors.red : mission.color, borderRadius: BorderRadius.circular(15)),
                child: Text("$_timeLeft", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _missionProgress,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation(_timeLeft < 10 ? Colors.red : mission.color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(_feedback, style: TextStyle(color: Colors.grey[400], fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
  
  Widget _buildStatsPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(color: Colors.grey[850]!.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.local_fire_department, "$_combo", "COMBO", Colors.orange),
          _buildStatItem(Icons.accessibility_new, _detectedPose, "POSTURE", Colors.cyan),
          _buildStatItem(Icons.emoji_emotions, _currentExpression.isEmpty ? "-" : _currentExpression, "EXPRESSION", Colors.amber),
          _buildStatItem(Icons.assignment, "$_successfulMissions/${_totalDetections == 0 ? 1 : _totalDetections}", "SUCCÈS", Colors.green),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(value.isNotEmpty ? value : "-", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
      ],
    );
  }
}

class Mission {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int points;
  final Color color;
  
  Mission({required this.id, required this.title, required this.description, required this.icon, required this.points, required this.color});
}
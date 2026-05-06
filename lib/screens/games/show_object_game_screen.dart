// lib/screens/games/show_object_game_screen.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/game_object_model.dart';
import '../../services/object_detection_service.dart';
import '../../services/sound_service.dart';
import '../../services/activity_history_service.dart';

class ShowObjectGameScreen extends StatefulWidget {
  final String? childId;
  const ShowObjectGameScreen({super.key, this.childId});

  @override
  State<ShowObjectGameScreen> createState() => _ShowObjectGameScreenState();
}

class _ShowObjectGameScreenState extends State<ShowObjectGameScreen>
    with TickerProviderStateMixin {
  final ObjectDetectionService _detectionService = ObjectDetectionService();
  final ImagePicker _imagePicker = ImagePicker();
  final SoundService _soundService = SoundService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  List<GameObjectModel> _objects = [];
  GameObjectModel? _currentObject;
  File? _capturedImage;
  
  int _score = 0;
  int _level = 1;
  int _combo = 0;
  int _bestScore = 0;
  int _completedChallenges = 0;
  int _timeRemaining = 30;
  int _remainingChallenges = 10;
  bool _isPlaying = false;
  bool _isProcessing = false;
  bool _showResult = false;
  bool _isCameraActive = false;
  String _resultMessage = '';
  bool _isVictory = false;
  double _confidence = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadBestScore();
    _objects = GameObjectModel.getAllObjects(); // ✅ Correction ici
    _selectNewObject();
    _initCamera();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraActive = true);
    }
  }

  Future<void> _importFromGallery() async {
  if (_isProcessing || !_isPlaying) return;
  
  await _soundService.playClick();
  
  setState(() {
    _isProcessing = true;
  });

  try {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      final imagePath = image.path;
      setState(() => _capturedImage = File(imagePath));
      await _analyzeObject(File(imagePath));
    } else {
      setState(() => _isProcessing = false);
      _showMessage('Aucune image sélectionnée', isError: true);
    }
  } catch (e) {
    setState(() => _isProcessing = false);
    _showMessage('Erreur lors de l\'import: $e', isError: true);
    print('Erreur import: $e');
  }
}

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('show_object_best_score') ?? 0;
    });
  }

  Future<void> _saveBestScore() async {
    if (_score > _bestScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('show_object_best_score', _score);
      setState(() => _bestScore = _score);
    }
  }

  void _selectNewObject() {
    final availableObjects = GameObjectModel.getObjectsByLevel(_level);
    if (availableObjects.isNotEmpty) {
      setState(() {
        _currentObject = availableObjects[
            Random().nextInt(availableObjects.length)];
        _timeRemaining = 30;
        _showResult = false;
        _confidence = 0.0;
        _capturedImage = null;
      });
    }
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _score = 0;
      _level = 1;
      _combo = 0;
      _completedChallenges = 0;
      _remainingChallenges = 10;
      _selectNewObject();
      _startTimer();
    });
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_isPlaying && !_isProcessing && !_showResult && mounted) {
        setState(() {
          if (_timeRemaining > 0) {
            _timeRemaining--;
          } else {
            _gameOver();
          }
        });
        return _timeRemaining > 0 && _isPlaying;
      }
      return false;
    });
  }

  Future<void> _captureAndAnalyze() async {
    if (_isProcessing || !_isPlaying) return;
    
    await _soundService.playClick();
    
    setState(() {
      _isProcessing = true;
    });

    try {
      XFile? image;
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        image = await _cameraController!.takePicture();
      } else {
        image = await _imagePicker.pickImage(source: ImageSource.camera);
      }

      if (image != null) {
        final imagePath = image.path;
        setState(() => _capturedImage = File(imagePath));
        await _analyzeObject(File(imagePath));
      } else {
        setState(() => _isProcessing = false);
        _showMessage('Aucune image capturée', isError: true);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showMessage('Erreur lors de la capture: $e', isError: true);
      print('Erreur capture: $e');
    }
  }

  Future<void> _analyzeObject(File imageFile) async {
    final result = await _detectionService.detectObjectWithDetails(imageFile);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() => _isProcessing = false);

    if (result['success'] == true && result['detectedObject'] != null) {
      final detectedLabel = result['detectedObject'] as String;
      final confidence = result['confidence'] as double;
      final isMatch = _detectionService.matchesObject(detectedLabel, _currentObject!);
      
      if (isMatch) {
        await _onCorrectAnswer(confidence);
      } else {
        await _onWrongAnswer();
      }
    } else {
      await _onNoObjectDetected();
    }
  }

  Future<void> _onCorrectAnswer(double confidence) async {
    setState(() => _showResult = true);
    
    int timeBonus = (_timeRemaining ~/ 5) * 5;
    int comboBonus = _combo * 5;
    int confidenceBonus = (confidence * 10).toInt();
    int totalEarned = _currentObject!.basePoints + timeBonus + comboBonus + confidenceBonus;
    
    setState(() {
      _score += totalEarned;
      _combo++;
      _completedChallenges++;
      _remainingChallenges--;
      _confidence = confidence;
      _resultMessage = '+$totalEarned points ! 🔥 Combo x${_combo}\nConfiance: ${(confidence * 100).toInt()}%';
      _isVictory = true;
    });
    
    await _playSuccessSound();
    _progressController.forward(from: 0);
    
    if (_score >= _level * 150) {
      await _levelUp();
    }
    
    if (_remainingChallenges <= 0) {
      await _gameComplete();
    } else {
      await _saveActivity();
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isPlaying) {
          _selectNewObject();
        }
      });
    }
  }

  Future<void> _onWrongAnswer() async {
    setState(() {
      _showResult = true;
      _combo = 0;
      _resultMessage = '😕 Ce n\'est pas le bon objet...\nEssayez encore !';
      _isVictory = false;
    });
    
    await _playErrorSound();
    _shakeController.forward();
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        _selectNewObject();
      }
    });
  }

  Future<void> _onNoObjectDetected() async {
    setState(() {
      _showResult = true;
      _combo = 0;
      _resultMessage = '🔍 Aucun objet détecté\nPlacez bien l\'objet devant la caméra !';
      _isVictory = false;
    });
    
    await _playErrorSound();
    _shakeController.forward();
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        _selectNewObject();
      }
    });
  }

  Future<void> _levelUp() async {
    setState(() {
      _level++;
      _combo = 0;
    });
    
    await _playLevelUpSound();
    _showMessage('🎉 Félicitations ! Niveau $_level atteint !', isSuccess: true);
  }

  Future<void> _gameComplete() async {
    setState(() {
      _isPlaying = false;
      _showResult = true;
      _resultMessage = '🏆 BRAVO ! Vous avez terminé le jeu !\nScore final: $_score';
      _isVictory = true;
    });
    
    await _saveBestScore();
    await _playGameCompleteSound();
    await _saveFinalActivity();
  }

  Future<void> _gameOver() async {
    setState(() {
      _isPlaying = false;
      _showResult = true;
      _resultMessage = '⏰ Temps écoulé ! Score final: $_score';
      _isVictory = false;
    });
    
    await _saveBestScore();
    await _playGameOverSound();
  }

  Future<void> _saveActivity() async {
    if (widget.childId != null) {
      final historyService = ActivityHistoryService();
      await historyService.addActivitySimple(
        childId: widget.childId!,
        activityType: 'show_object_game',
        title: 'Jeu "Montre-moi l\'objet"',
        description: 'Objet "${_currentObject?.name}" trouvé ! +${_currentObject?.basePoints} points',
                points: _currentObject?.basePoints ?? 20,
      );
    }
  }

  Future<void> _saveFinalActivity() async {
    if (widget.childId != null) {
      final historyService = ActivityHistoryService();
      await historyService.addActivitySimple(
        childId: widget.childId!,
        activityType: 'show_object_game_complete',
        title: '🎉 Jeu "Montre-moi l\'objet" terminé !',
        description: 'Score final: $_score points - Bravo !',
        points: _score,
      );
    }
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      await _soundService.playSuccess();
      if (await Vibrate.canVibrate) {
        Vibrate.feedback(FeedbackType.light);
      }
    } catch (e) {
      print('Erreur son succès: $e');
    }
  }

  Future<void> _playErrorSound() async {
    try {
      await _soundService.playError();
      if (await Vibrate.canVibrate) {
        Vibrate.feedback(FeedbackType.heavy);
      }
    } catch (e) {
      print('Erreur son erreur: $e');
    }
  }

  Future<void> _playLevelUpSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/level_up.mp3'));
    } catch (e) {
      print('Erreur son level up: $e');
    }
  }

  Future<void> _playGameCompleteSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/game_complete.mp3'));
    } catch (e) {
      print('Erreur son game complete: $e');
    }
  }

  Future<void> _playGameOverSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/game_over.mp3'));
    } catch (e) {
      print('Erreur son game over: $e');
    }
  }

  void _showMessage(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : (isSuccess ? Colors.green : const Color(0xFF4CAF50)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Comment jouer ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem('1️⃣', 'Regarde l\'objet demandé'),
            _buildHelpItem('2️⃣', 'Place l\'objet devant la caméra'),
            _buildHelpItem('3️⃣', 'Prends une photo'),
            _buildHelpItem('4️⃣', 'Gagne des points si l\'objet est reconnu'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildHelpItem('🎯', 'Plus tu es rapide, plus tu gagnes de points'),
            _buildHelpItem('🔥', 'Enchaîne les bonnes réponses pour un combo'),
            _buildHelpItem('⭐', 'Monte de niveau pour débloquer + d\'objets'),
            _buildHelpItem('📸', 'Bien éclaire l\'objet pour une meilleure détection'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: Text(
          '🎯 Montre-moi l\'objet',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _isCameraActive ? null : _initCamera,
            tooltip: 'Activer caméra',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: _isPlaying ? _buildGameScreen(isDarkMode) : _buildStartScreen(isDarkMode),
    );
  }

  Widget _buildStartScreen(bool isDarkMode) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('🎯', style: TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: 24),
            Text(
              'Montre-moi l\'objet',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Place l\'objet demandé devant la caméra !\nGagne des points et monte de niveau.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('🏆', 'Meilleur', '$_bestScore'),
                  _buildStatItem('🎯', 'Objets', '${_objects.length}'),
                  _buildStatItem('⭐', 'Niveaux', '3'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      '🎮 COMMENCER LE JEU',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildGameScreen(bool isDarkMode) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGameStat('🏆', 'Score', '$_score'),
              _buildGameStat('⭐', 'Niveau', '$_level'),
              _buildGameStat('🔥', 'Combo', 'x${_combo > 0 ? _combo : 1}'),
              _buildGameStat('🎯', 'Restants', '$_remainingChallenges'),
            ],
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_remainingChallenges}/10 défis', style: GoogleFonts.poppins(fontSize: 12)),
                  Text('⏰ ${_timeRemaining}s', style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange)),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: _remainingChallenges / 10,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF4CAF50),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _isProcessing
              ? _buildProcessingScreen()
              : _showResult
                  ? _buildResultScreen(isDarkMode)
                  : _buildObjectChallenge(isDarkMode),
        ),
      ],
    );
  }

  Widget _buildGameStat(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20, color: Colors.white)),
        Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  Widget _buildObjectChallenge(bool isDarkMode) {
  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Aperçu caméra
          if (_isCameraActive && _cameraController != null && _cameraController!.value.isInitialized)
            Container(
              height: 250,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF4CAF50), width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CameraPreview(_cameraController!),
              ),
            ),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              _currentObject?.emoji ?? '🎯',
              style: const TextStyle(fontSize: 80),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _currentObject?.name ?? 'Objet',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _currentObject?.description ?? 'Montre-moi cet objet !',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 40),
          
          // ✅ Boutons caméra et galerie
          Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: ElevatedButton.icon(
                        onPressed: _captureAndAnalyze,
                        icon: const Icon(Icons.camera_alt_rounded, size: 24),
                        label: const Text('Prendre photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _importFromGallery,
                  icon: const Icon(Icons.photo_library_rounded, size: 24),
                  label: const Text('Galerie'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Color(0xFF4CAF50)),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          Text(
            'Prenez une photo ou choisissez une image de votre galerie',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

  Widget _buildProcessingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                    strokeWidth: 3,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Analyse en cours...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Reconnaissance de l\'objet',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value * 10, 0),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _isVictory ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _isVictory ? '🎉' : '😢',
                      style: const TextStyle(fontSize: 60),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isVictory ? 'BRAVO !' : 'OUPS...',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _isVictory ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _resultMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_capturedImage != null)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: FileImage(_capturedImage!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (_confidence > 0 && _isVictory)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.trending_up, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Confiance: ${(_confidence * 100).toInt()}%',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  if (_remainingChallenges > 0)
                    LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.grey.shade200,
                      color: const Color(0xFF4CAF50),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  if (_remainingChallenges > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Progression: ${10 - _remainingChallenges}/10 défis',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _detectionService.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    _progressController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
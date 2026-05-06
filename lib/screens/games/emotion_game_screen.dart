// lib/screens/games/emotion_game_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/emotion_model.dart';
import '../../services/emotion_detection_service.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../services/activity_history_service.dart';

class EmotionGameScreen extends StatefulWidget {
  final String? childId;
  const EmotionGameScreen({super.key, this.childId});

  @override
  State<EmotionGameScreen> createState() => _EmotionGameScreenState();
}

class _EmotionGameScreenState extends State<EmotionGameScreen>
    with TickerProviderStateMixin {
  final EmotionDetectionService _detectionService = EmotionDetectionService();
  final ImagePicker _imagePicker = ImagePicker();
  final SoundService _soundService = SoundService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<EmotionModel> _emotions = [];
  EmotionModel? _currentEmotion;
  File? _capturedImage;
  
  int _score = 0;
  int _level = 1;
  int _combo = 0;
  int _bestScore = 0;
  int _completedChallenges = 0;
  int _timeRemaining = 20;
  bool _isPlaying = false;
  bool _isProcessing = false;
  bool _showResult = false;
  String _resultMessage = '';
  bool _isVictory = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadBestScore();
    _emotions = EmotionModel.getEmotions();
    _selectNewEmotion();
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

    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('emotion_game_best_score') ?? 0;
    });
  }

  Future<void> _saveBestScore() async {
    if (_score > _bestScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('emotion_game_best_score', _score);
      setState(() => _bestScore = _score);
    }
  }

  void _selectNewEmotion() {
    final availableEmotions = _emotions.where((e) => e.minLevel <= _level).toList();
    if (availableEmotions.isNotEmpty) {
      setState(() {
        _currentEmotion = availableEmotions[
            DateTime.now().millisecondsSinceEpoch % availableEmotions.length];
        _timeRemaining = 20;
        _showResult = false;
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
      _selectNewEmotion();
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
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _capturedImage = File(image.path));
        await _analyzeEmotion(File(image.path));
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showMessage('Erreur lors de la capture', isError: true);
    }
  }

  Future<void> _analyzeEmotion(File imageFile) async {
    final detectedEmotionId = await _detectionService.detectEmotion(imageFile);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() => _isProcessing = false);

    if (detectedEmotionId == _currentEmotion?.id) {
      await _onCorrectAnswer();
    } else {
      await _onWrongAnswer();
    }
  }

  Future<void> _onCorrectAnswer() async {
    setState(() => _showResult = true);
    
    // Calcul des points
    int pointsEarned = _currentEmotion!.points;
    int timeBonus = (_timeRemaining ~/ 5) * 5;
    int comboBonus = _combo * 5;
    int totalEarned = pointsEarned + timeBonus + comboBonus;
    
    setState(() {
      _score += totalEarned;
      _combo++;
      _completedChallenges++;
      _resultMessage = '+$totalEarned points ! 🔥 Combo x${_combo}';
      _isVictory = true;
    });
    
    await _playSuccessSound();
    _shakeController.forward();
    
    // Vérifier progression niveau
    if (_score >= _level * 100) {
      await _levelUp();
    }
    
    await _saveActivity();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isPlaying) {
        _selectNewEmotion();
      }
    });
  }

  Future<void> _onWrongAnswer() async {
    setState(() {
      _showResult = true;
      _combo = 0;
      _resultMessage = '😕 Ce n\'est pas la bonne émotion... Essaye encore !';
      _isVictory = false;
    });
    
    await _playErrorSound();
    _shakeController.forward();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isPlaying) {
        _selectNewEmotion();
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

  Future<void> _gameOver() async {
    setState(() {
      _isPlaying = false;
      _showResult = true;
      _resultMessage = '⏰ Temps écoulé ! Score final: $_score';
    });
    
    await _saveBestScore();
    await _playGameOverSound();
  }

  Future<void> _saveActivity() async {
    if (widget.childId != null) {
      final historyService = ActivityHistoryService();
      await historyService.addActivitySimple(
        childId: widget.childId!,
        activityType: 'emotion_game',
        title: 'Jeu des émotions',
        description: 'Émotion "${_currentEmotion?.name}" reconnue ! +${_currentEmotion?.points} points',
        points: _currentEmotion?.points ?? 20,
      );
    }
  }

  Future<void> _playSuccessSound() async {
    await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    await _soundService.playSuccess();
    if (await Vibrate.canVibrate) {
      Vibrate.feedback(FeedbackType.light);
    }
  }

  Future<void> _playErrorSound() async {
    await _soundService.playError();
    if (await Vibrate.canVibrate) {
      Vibrate.feedback(FeedbackType.heavy);
    }
  }

  Future<void> _playLevelUpSound() async {
    await _audioPlayer.play(AssetSource('sounds/level_up.mp3'));
  }

  Future<void> _playGameOverSound() async {
    await _audioPlayer.play(AssetSource('sounds/game_over.mp3'));
  }

  void _showMessage(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : (isSuccess ? Colors.green : AppTheme.primaryColor),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF0F5),
      appBar: AppBar(
        title: Text(
          '🎭 Devine l\'Émotion',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
                color: const Color(0xFFE91E63).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('🎭', style: TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: 24),
            Text(
              'Devine l\'Émotion',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Fais l\'émotion demandée devant la caméra !\nGagne des points et monte de niveau.',
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
                  _buildStatItem('🎯', 'Émotions', '${_emotions.length}'),
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
                      backgroundColor: const Color(0xFFE91E63),
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
        // Header du jeu
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE91E63),
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
              _buildGameStat('⏰', 'Temps', '${_timeRemaining}s'),
            ],
          ),
        ),
        
        // Zone principale du jeu
        Expanded(
          child: _isProcessing
              ? _buildProcessingScreen()
              : _showResult
                  ? _buildResultScreen(isDarkMode)
                  : _buildEmotionChallenge(isDarkMode),
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

  Widget _buildEmotionChallenge(bool isDarkMode) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE91E63).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                _currentEmotion?.emoji ?? '😊',
                style: const TextStyle(fontSize: 80),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _currentEmotion?.name ?? 'Heureux',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE91E63),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentEmotion?.description ?? 'Fais un grand sourire !',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: ElevatedButton.icon(
                    onPressed: _captureAndAnalyze,
                    icon: const Icon(Icons.camera_alt_rounded, size: 28),
                    label: const Text('Prendre la photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Place ton visage bien éclairé devant la caméra',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500,
              ),
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
                    color: const Color(0xFFE91E63).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
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
              color: const Color(0xFFE91E63),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Reconnaissance de l\'émotion',
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
                  const SizedBox(height: 32),
                  LinearProgressIndicator(
                    value: _score / (_level * 100),
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFFE91E63),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Niveau $_level - ${_score}/${_level * 100} points',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
            _buildHelpItem('1️⃣', 'Regarde l\'émotion demandée'),
            _buildHelpItem('2️⃣', 'Fais cette expression devant la caméra'),
            _buildHelpItem('3️⃣', 'Prends une photo'),
            _buildHelpItem('4️⃣', 'Gagne des points si l\'émotion est reconnue'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildHelpItem('🎯', 'Plus tu es rapide, plus tu gagnes de points'),
            _buildHelpItem('🔥', 'Enchaîne les bonnes réponses pour un combo'),
            _buildHelpItem('⭐', 'Monte de niveau pour débloquer + d\'émotions'),
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
  void dispose() {
    _detectionService.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
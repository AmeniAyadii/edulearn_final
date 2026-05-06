// lib/screens/games/rhythm_game_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/rhythm_movement.dart';
import '../../services/pose_detection_service.dart';
import '../../services/sound_service.dart';
import '../../services/activity_history_service.dart';

class RhythmGameScreen extends StatefulWidget {
  final String? childId;
  const RhythmGameScreen({super.key, this.childId});

  @override
  State<RhythmGameScreen> createState() => _RhythmGameScreenState();
}

class _RhythmGameScreenState extends State<RhythmGameScreen>
    with TickerProviderStateMixin {
  final PoseDetectionService _poseService = PoseDetectionService();
  final ImagePicker _imagePicker = ImagePicker();
  final SoundService _soundService = SoundService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<RhythmSequence> _sequences = [];
  RhythmSequence? _currentSequence;
  int _currentMovementIndex = 0;
  RhythmMovement? _currentMovement;
  
  int _score = 0;
  int _level = 1;
  int _combo = 0;
  int _bestScore = 0;
  int _remainingSequences = 3;
  bool _isPlaying = false;
  bool _isProcessing = false;
  bool _showResult = false;
  bool _isCorrect = false;
  String _resultMessage = '';
  int _sequenceProgress = 0;
  int _timerCountdown = 5;
  Timer? _countdownTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _timerController;
  late Animation<double> _timerAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadBestScore();
    _sequences = RhythmSequence.generateSequences();
    _selectNextSequence();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _timerController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _timerAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _timerController, curve: Curves.linear),
    )..addListener(() {
      if (mounted && _isPlaying && !_isProcessing && !_showResult) {
        setState(() {
          _timerCountdown = (5 * _timerAnimation.value).ceil();
        });
      }
    });
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('rhythm_best_score') ?? 0;
    });
  }

  Future<void> _saveBestScore() async {
    if (_score > _bestScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('rhythm_best_score', _score);
      setState(() => _bestScore = _score);
    }
  }

  void _selectNextSequence() {
    final availableSequences = _sequences.where((s) => s.level == _level).toList();
    if (availableSequences.isNotEmpty && _remainingSequences > 0) {
      setState(() {
        _currentSequence = availableSequences[
            DateTime.now().millisecondsSinceEpoch % availableSequences.length];
        _currentMovementIndex = 0;
        _sequenceProgress = 0;
        _selectCurrentMovement();
      });
    } else if (_remainingSequences <= 0) {
      _levelComplete();
    } else {
      _gameComplete();
    }
  }

  void _selectCurrentMovement() {
    if (_currentSequence != null && _currentMovementIndex < _currentSequence!.movements.length) {
      setState(() {
        _currentMovement = _currentSequence!.movements[_currentMovementIndex];
        _showResult = false;
        _isProcessing = false;
        _timerCountdown = 5;
        _timerController.forward(from: 0);
        _startCountdown();
      });
    } else {
      _sequenceComplete();
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerCountdown <= 1) {
        timer.cancel();
      } else if (mounted && _isPlaying && !_showResult) {
        setState(() => _timerCountdown--);
      }
    });
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _score = 0;
      _level = 1;
      _combo = 0;
      _remainingSequences = 3;
      _selectNextSequence();
    });
  }

  Future<void> _capturePose() async {
    if (_isProcessing || !_isPlaying || _showResult) return;
    
    await _soundService.playClick();
    
    setState(() {
      _isProcessing = true;
      _timerController.stop();
    });

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final result = await _poseService.detectPose(File(image.path), _currentMovement!);
        
        if (result['isMatch']) {
          await _onCorrectAnswer(result['confidence'], result['bonus']);
        } else {
          await _onWrongAnswer(result);
        }
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showMessage('Erreur lors de la capture', isError: true);
    }
  }

  Future<void> _onCorrectAnswer(double confidence, int bonus) async {
    final timeBonus = (_timerCountdown ~/ 2) * 2;
    final comboBonus = _combo * 10;
    final difficultyBonus = _currentMovement!.difficulty * 5;
    final totalEarned = _currentMovement!.points + timeBonus + comboBonus + difficultyBonus + bonus;
    
    setState(() {
      _showResult = true;
      _score += totalEarned;
      _combo++;
      _currentMovementIndex++;
      _sequenceProgress++;
      _resultMessage = '+$totalEarned points ! 🔥 Combo x$_combo\n🎯 Précision: ${(confidence * 100).toInt()}%\n⚡ Bonus combo: +$comboBonus\n⭐ Bonus difficulté: +$difficultyBonus';
      if (bonus > 0) _resultMessage += '\n✨ Bonus précision ! +$bonus';
      _isCorrect = true;
      _isProcessing = false;
    });
    
    await _playSuccessSound();
    _progressController.forward(from: 0);
    _timerController.stop();
    
    if (_currentMovementIndex >= _currentSequence!.movements.length) {
      await _sequenceComplete();
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isPlaying) {
          _selectCurrentMovement();
        }
      });
    }
  }

  Future<void> _onWrongAnswer(Map<String, dynamic> result) async {
    setState(() {
      _showResult = true;
      _combo = 0;
      _resultMessage = '❌ Mouvement incorrect\n\n💡 Conseils:\n${_currentMovement!.instructions.join('\n')}\n\nDétecté: ${result['detectedPose'] ?? 'position inconnue'}\n📸 Réessaie !';
      _isCorrect = false;
      _isProcessing = false;
    });
    
    await _playErrorSound();
    _shakeController.forward();
    _timerController.stop();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isPlaying) {
        _selectCurrentMovement();
      }
    });
  }

  Future<void> _sequenceComplete() async {
    final bonus = _currentSequence!.totalPoints;
    setState(() {
      _score += bonus;
      _resultMessage = '🎉 SÉQUENCE COMPLÉTÉE ! 🎉\n\n+$bonus points bonus !\nProgression: $_sequenceProgress/${_currentSequence!.movements.length} mouvements';
      _showResult = true;
      _isCorrect = true;
    });
    
    await _playLevelUpSound();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isPlaying) {
        if (_remainingSequences > 1) {
          setState(() {
            _remainingSequences--;
            _selectNextSequence();
          });
        } else {
          _levelComplete();
        }
      }
    });
  }

  Future<void> _levelComplete() async {
    setState(() {
      _isPlaying = false;
      _showResult = true;
      _resultMessage = '🌟 FÉLICITATIONS ! 🌟\n\n🎉 Niveau $_level terminé ! 🎉\nScore: $_score points\nCombo max: x$_combo\n\nPasse au niveau suivant !';
      _isCorrect = true;
    });
    
    await _saveActivity();
    
    if (_level < 3) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _level++;
            _remainingSequences = 3;
            _combo = 0;
            _selectNextSequence();
            _isPlaying = true;
          });
        }
      });
    } else {
      _gameComplete();
    }
  }

  Future<void> _gameComplete() async {
    setState(() {
      _isPlaying = false;
      _showResult = true;
      _resultMessage = '🏆 VICTOIRE ! 🏆\n\n🎉 Jeu terminé ! 🎉\nScore final: $_score points\nNiveaux complétés: 3/3\nCombo max: x$_combo\n\nTu es un champion du rythme ! 🕺✨';
      _isCorrect = true;
    });
    
    await _saveBestScore();
    await _playGameCompleteSound();
    await _saveFinalActivity();
  }

  Future<void> _saveActivity() async {
    if (widget.childId != null) {
      final historyService = ActivityHistoryService();
      await historyService.addActivitySimple(
        childId: widget.childId!,
        activityType: 'rhythm_game',
        title: 'Jeu Le Bon Rythme',
        description: 'Niveau $_level terminé !',
        points: _score,
      );
    }
  }

  Future<void> _saveFinalActivity() async {
    if (widget.childId != null) {
      final historyService = ActivityHistoryService();
      await historyService.addActivitySimple(
        childId: widget.childId!,
        activityType: 'rhythm_game_complete',
        title: '🎉 Jeu Le Bon Rythme terminé !',
        description: 'Score final: $_score points - Champion du rythme !',
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
    } catch (e) {}
  }

  Future<void> _playErrorSound() async {
    try {
      await _soundService.playError();
      if (await Vibrate.canVibrate) {
        Vibrate.feedback(FeedbackType.medium);
      }
    } catch (e) {}
  }

  Future<void> _playLevelUpSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/level_up.mp3'));
    } catch (e) {}
  }

  Future<void> _playGameCompleteSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/game_complete.mp3'));
    } catch (e) {}
  }

  void _showMessage(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : (isSuccess ? Colors.green : const Color(0xFF9C27B0)),
        behavior: SnackBarBehavior.floating,
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
            _buildHelpItem('1️⃣', 'Regarde le mouvement à reproduire'),
            _buildHelpItem('2️⃣', 'Prépare-toi (5 secondes)'),
            _buildHelpItem('3️⃣', 'Appuie sur "Prendre la photo"'),
            _buildHelpItem('4️⃣', 'Fais le mouvement devant la caméra'),
            _buildHelpItem('5️⃣', 'Gagne des points si le mouvement est reconnu'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildHelpItem('🕺', 'Bien éclaire-toi pour la caméra'),
            _buildHelpItem('🎯', 'Sois précis dans tes mouvements'),
            _buildHelpItem('📸', 'Tiens la pose 2-3 secondes'),
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
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF3E5F5),
      appBar: AppBar(
        title: Text(
          '🕺 Le Bon Rythme',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF9C27B0),
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
                color: const Color(0xFF9C27B0).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('🕺', style: TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: 24),
            Text(
              'Le Bon Rythme',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Reproduis les mouvements devant la caméra !\nGagne des points et deviens champion du rythme.',
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
                  _buildStatItem('🕺', 'Mouvements', '${RhythmMovement.getAllMovements().length}'),
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
                      backgroundColor: const Color(0xFF9C27B0),
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
    final sequenceProgress = _currentSequence != null 
        ? (_currentMovementIndex / _currentSequence!.movements.length)
        : 0.0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGameStat('🏆', 'Score', '$_score'),
              _buildGameStat('⭐', 'Niveau', '$_level/3'),
              _buildGameStat('🔥', 'Combo', 'x${_combo > 0 ? _combo : 1}'),
              _buildGameStat('📝', 'Séquences', '$_remainingSequences'),
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
                  Text('Séquence $_sequenceProgress/${_currentSequence?.movements.length ?? 0}', 
                      style: GoogleFonts.poppins(fontSize: 12)),
                  Text('⏰ $_timerCountdown s', style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange)),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: sequenceProgress,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF9C27B0),
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
                  : _buildMovementScreen(isDarkMode),
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

  Widget _buildMovementScreen(bool isDarkMode) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _currentMovement?.emoji ?? '🕺',
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentMovement?.name ?? 'Mouvement',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9C27B0),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentMovement?.description ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 32),
                  ...(_currentMovement?.instructions.map((instruction) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Color(0xFF9C27B0)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(instruction)),
                      ],
                    ),
                  )).toList() ?? []),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            AnimatedBuilder(
              animation: _timerAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    if (_timerCountdown > 0)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$_timerCountdown',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _capturePose,
                      icon: const Icon(Icons.camera_alt, size: 28),
                      label: const Text('📸 Prendre la photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 20),
            Text(
              'Place-toi bien dans le cadre\net reproduis le mouvement',
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
                    color: const Color(0xFF9C27B0).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
                    strokeWidth: 3,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Analyse du mouvement...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9C27B0),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Détection de la pose',
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
                      color: _isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _isCorrect ? '🎉' : '😢',
                      style: const TextStyle(fontSize: 60),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isCorrect ? 'BRAVO !' : 'OUPS...',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _resultMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_currentMovementIndex < (_currentSequence?.movements.length ?? 0))
                    LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.grey.shade200,
                      color: const Color(0xFF9C27B0),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  if (_currentMovementIndex < (_currentSequence?.movements.length ?? 0))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Prochain mouvement dans 2 secondes...',
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
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    _progressController.dispose();
    _timerController.dispose();
    _audioPlayer.dispose();
    _poseService.dispose();
    super.dispose();
  }
}
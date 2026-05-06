// lib/screens/games/drawing_game_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/drawing_object.dart';
import '../../services/drawing_recognition_service.dart';
import '../../services/sound_service.dart';
import '../../services/activity_history_service.dart';

class DrawingGameScreen extends StatefulWidget {
  final String? childId;
  const DrawingGameScreen({super.key, this.childId});

  @override
  State<DrawingGameScreen> createState() => _DrawingGameScreenState();
}

class _DrawingGameScreenState extends State<DrawingGameScreen>
    with TickerProviderStateMixin {
  final DrawingRecognitionService _recognitionService = DrawingRecognitionService();
  final ImagePicker _imagePicker = ImagePicker();
  final SoundService _soundService = SoundService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<DrawingObject> _objects = [];
  DrawingObject? _currentObject;
  List<DrawingObject> _availableObjects = [];
  
  int _score = 0;
  int _level = 1;
  int _combo = 0;
  int _bestScore = 0;
  int _remainingDrawings = 10;
  bool _isPlaying = false;
  bool _isProcessing = false;
  bool _showResult = false;
  String _resultMessage = '';
  bool _isCorrect = false;
  String _tip = '';
  File? _capturedImage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _confettiController;
  late Animation<double> _confettiAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadBestScore();
    _objects = DrawingObject.getAllObjects();
    _availableObjects = List.from(_objects);
    _selectNewObject();
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

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _confettiAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('drawing_best_score') ?? 0;
    });
  }

  Future<void> _saveBestScore() async {
    if (_score > _bestScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('drawing_best_score', _score);
      setState(() => _bestScore = _score);
    }
  }

  void _selectNewObject() {
    if (_availableObjects.isEmpty) {
      _availableObjects = List.from(_objects);
    }
    
    final available = _availableObjects.where((w) => w.difficulty <= _level).toList();
    if (available.isNotEmpty) {
      setState(() {
        _currentObject = available[DateTime.now().millisecondsSinceEpoch % available.length];
        _availableObjects.remove(_currentObject);
        _tip = _currentObject!.drawingTip;
        _showResult = false;
        _capturedImage = null;
      });
    } else {
      _gameComplete();
    }
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _score = 0;
      _level = 1;
      _combo = 0;
      _remainingDrawings = 10;
      _availableObjects = List.from(_objects);
      _selectNewObject();
    });
  }

  Future<void> _captureDrawing() async {
    if (_isProcessing || !_isPlaying) return;
    
    await _soundService.playClick();
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (image != null) {
      setState(() => _capturedImage = File(image.path));
      
      // Utilisation de la version rapide
      final result = await DrawingRecognitionService.instance.checkDrawingFast(
        File(image.path), 
        _currentObject!
      );
      
      setState(() => _isProcessing = false);
      
      if (result['isMatch']) {
        await _onCorrectAnswer(result['confidence'], result['bonus']);
      } else {
        await _onWrongAnswer();
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
    final timeBonus = 0;
    final comboBonus = _combo * 10;
    final difficultyBonus = _currentObject!.difficulty * 5;
    final confidenceBonus = (confidence * 10).toInt();
    final totalEarned = _currentObject!.points + timeBonus + comboBonus + difficultyBonus + confidenceBonus + bonus;
    
    setState(() {
      _showResult = true;
      _score += totalEarned;
      _combo++;
      _remainingDrawings--;
      _resultMessage = '+$totalEarned points ! 🔥 Combo x$_combo\n🎨 Qualité: +$confidenceBonus\n⚡ Bonus combo: +$comboBonus\n📚 Difficulté: +$difficultyBonus';
      if (bonus > 0) _resultMessage += '\n✨ Bonus artiste ! +$bonus';
      _isCorrect = true;
    });
    
    await _playSuccessSound();
    _progressController.forward(from: 0);
    _confettiController.forward(from: 0);
    
    await _saveActivity();
    
    if (_score >= _level * 300) {
      await _levelUp();
    }
    
    if (_remainingDrawings <= 0) {
      await _gameComplete();
    } else {
      Future.delayed(const Duration(seconds: 2), () {
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
      _resultMessage = '❌ Ce n\'est pas ${_currentObject!.name}\n💡 Conseils: ${_currentObject!.drawingTip}\n📸 Réessaie !';
      _isCorrect = false;
    });
    
    await _playErrorSound();
    _shakeController.forward();
    
    Future.delayed(const Duration(seconds: 2), () {
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
    _showMessage('🎉 Niveau $_level atteint ! Nouveaux dessins débloqués', isSuccess: true);
  }

  Future<void> _gameComplete() async {
    setState(() {
      _isPlaying = false;
      _showResult = true;
      _resultMessage = '🏆 FÉLICITATIONS ! 🏆\n\n🎉 Jeu terminé ! 🎉\nScore final: $_score points\nNiveau atteint: $_level\n\nTu es un grand artiste ! 🎨✨';
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
        activityType: 'drawing_game',
        title: 'Jeu Dessine et Détecte',
        description: 'Dessin de "${_currentObject?.name}" reconnu !',
        points: _currentObject?.points ?? 20,
      );
    }
  }

  Future<void> _saveFinalActivity() async {
    if (widget.childId != null) {
      final historyService = ActivityHistoryService();
      await historyService.addActivitySimple(
        childId: widget.childId!,
        activityType: 'drawing_game_complete',
        title: '🎉 Jeu Dessine et Détecte terminé !',
        description: 'Score final: $_score points - Grand artiste !',
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
            _buildHelpItem('1️⃣', 'Regarde l\'objet à dessiner'),
            _buildHelpItem('2️⃣', 'Dessine l\'objet sur une feuille'),
            _buildHelpItem('3️⃣', 'Prends une photo de ton dessin'),
            _buildHelpItem('4️⃣', 'Gagne des points si ton dessin est reconnu'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildHelpItem('✏️', 'Dessine gros et bien visible'),
            _buildHelpItem('🎨', 'Utilise des couleurs contrastées'),
            _buildHelpItem('📸', 'Bien éclaire ton dessin'),
            _buildHelpItem('🔥', 'Enchaîne les bonnes réponses pour un combo'),
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
          '🎨 Dessine et Détecte',
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
    final totalDrawings = DrawingObject.getAllObjects().length;

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
              child: const Text('🎨', style: TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: 24),
            Text(
              'Dessine et Détecte',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dessine l\'objet demandé, prends une photo\net gagne des points !',
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
                  _buildStatItem('🎨', 'Dessins', '$totalDrawings'),
                  _buildStatItem('⭐', 'Niveaux', '5'),
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
              _buildGameStat('⭐', 'Niveau', '$_level'),
              _buildGameStat('🔥', 'Combo', 'x${_combo > 0 ? _combo : 1}'),
              _buildGameStat('🎨', 'Restants', '$_remainingDrawings'),
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
                  Text('${_remainingDrawings}/10 dessins', style: GoogleFonts.poppins(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: _remainingDrawings / 10,
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
                  : _buildDrawingScreen(isDarkMode),
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

  Widget _buildDrawingScreen(bool isDarkMode) {
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
                    _currentObject?.emoji ?? '🎨',
                    style: const TextStyle(fontSize: 60),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'À dessiner :',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentObject?.name ?? 'Objet',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9C27B0),
                    ),
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Icon(Icons.lightbulb_outline, size: 32, color: const Color(0xFF9C27B0)),
                            const SizedBox(height: 8),
                            Text(
                              '💡 Astuce',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _tip,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF9C27B0),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            if (_capturedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: FileImage(_capturedImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: ElevatedButton.icon(
                    onPressed: _captureDrawing,
                    icon: const Icon(Icons.camera_alt, size: 28),
                    label: const Text('Prendre la photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
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
              'Dessine l\'objet sur une feuille\npuis prends une photo',
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
            'Reconnaissance du dessin...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9C27B0),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyse de ton chef-d\'œuvre',
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
          child: Stack(
            children: [
              Center(
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
                      const SizedBox(height: 24),
                      if (_capturedImage != null && !_isCorrect)
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: FileImage(_capturedImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),
                      if (_remainingDrawings > 0)
                        LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Colors.grey.shade200,
                          color: const Color(0xFF9C27B0),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      if (_remainingDrawings > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Prochain dessin dans 2 secondes...',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_isCorrect)
                AnimatedBuilder(
                  animation: _confettiAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 1 - _confettiAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.yellow.withOpacity(0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _recognitionService.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    _progressController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
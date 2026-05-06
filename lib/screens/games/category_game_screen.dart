// lib/screens/games/category_game_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/category_word.dart';
import '../../services/word_recognition_service.dart';
import '../../services/sound_service.dart';
import '../../services/activity_history_service.dart';

class CategoryGameScreen extends StatefulWidget {
  final String? childId;
  const CategoryGameScreen({super.key, this.childId});

  @override
  State<CategoryGameScreen> createState() => _CategoryGameScreenState();
}

class _CategoryGameScreenState extends State<CategoryGameScreen>
    with TickerProviderStateMixin {
  final WordRecognitionService _recognitionService = WordRecognitionService();
  final ImagePicker _imagePicker = ImagePicker();
  final SoundService _soundService = SoundService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<CategoryWord> _words = [];
  CategoryWord? _currentWord;
  List<CategoryWord> _availableWords = [];
  List<WordCategory> _activeCategories = [];
  
  int _score = 0;
  int _level = 1;
  int _combo = 0;
  int _bestScore = 0;
  int _remainingQuestions = 10;
  int _timeRemaining = 30;
  bool _isPlaying = false;
  bool _isProcessing = false;
  bool _showResult = false;
  String _recognizedWord = '';
  String _resultMessage = '';
  bool _isCorrect = false;
  WordCategory? _selectedCategory;
  WordCategory? _correctCategory;

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
    _words = CategoryWord.getAllWords();
    _availableWords = List.from(_words);
    _activeCategories = [WordCategory.fruit, WordCategory.animal, WordCategory.color];
    _selectNewWord();
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
      _bestScore = prefs.getInt('category_best_score') ?? 0;
    });
  }

  Future<void> _saveBestScore() async {
    if (_score > _bestScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('category_best_score', _score);
      setState(() => _bestScore = _score);
    }
  }

  void _selectNewWord() {
    if (_availableWords.isEmpty) {
      _availableWords = List.from(_words);
    }
    
    final available = _availableWords.where((w) => w.difficulty <= _level).toList();
    if (available.isNotEmpty) {
      setState(() {
        _currentWord = available[DateTime.now().millisecondsSinceEpoch % available.length];
        _availableWords.remove(_currentWord);
        _recognizedWord = '';
        _showResult = false;
        _selectedCategory = null;
        _correctCategory = null;
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
      _remainingQuestions = 10;
      _availableWords = List.from(_words);
      _selectNewWord();
    });
  }

  Future<void> _scanWord() async {
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
        final result = await _recognitionService.recognizeWithConfidence(File(image.path));
        
        if (result['success'] == true && result['word'] != null) {
          setState(() {
            _recognizedWord = result['word'];
            _isProcessing = false;
            _correctCategory = _currentWord?.category;
          });
        } else {
          setState(() => _isProcessing = false);
          _showMessage('Mot non reconnu, réessayez', isError: true);
        }
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showMessage('Erreur lors du scan', isError: true);
    }
  }

  Future<void> _checkCategory(WordCategory selected) async {
    if (_isProcessing || !_isPlaying || _currentWord == null) return;
    
    setState(() {
      _selectedCategory = selected;
      _isProcessing = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    
    final isMatch = selected == _currentWord!.category;
    
    if (isMatch) {
      await _onCorrectAnswer();
    } else {
      await _onWrongAnswer();
    }
    
    setState(() => _isProcessing = false);
  }

  Future<void> _onCorrectAnswer() async {
    _setCategoriesForLevel();
    
    final timeBonus = (_timeRemaining ~/ 5) * 2;
    final comboBonus = _combo * 10;
    final difficultyBonus = _currentWord!.difficulty * 5;
    final totalEarned = _currentWord!.points + timeBonus + comboBonus + difficultyBonus;
    
    setState(() {
      _showResult = true;
      _score += totalEarned;
      _combo++;
      _remainingQuestions--;
      _resultMessage = '+$totalEarned points ! 🔥 Combo x$_combo\n⭐ Bonus rapidité: +$timeBonus\n🔥 Bonus combo: +$comboBonus\n📚 Difficulté: +$difficultyBonus';
      _isCorrect = true;
    });
    
    await _playSuccessSound();
    _progressController.forward(from: 0);
    _confettiController.forward(from: 0);
    
    await _saveActivity();
    
    if (_score >= _level * 200) {
      await _levelUp();
    }
    
    if (_remainingQuestions <= 0) {
      await _gameComplete();
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isPlaying) {
          _selectNewWord();
        }
      });
    }
  }

  Future<void> _onWrongAnswer() async {
    setState(() {
      _showResult = true;
      _combo = 0;
      _resultMessage = '❌ "${_currentWord!.word}" appartient à la catégorie ${_currentWord!.category.label}\n💡 Continue à t\'entraîner !';
      _isCorrect = false;
    });
    
    await _playErrorSound();
    _shakeController.forward();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isPlaying) {
        _selectNewWord();
      }
    });
  }

  void _setCategoriesForLevel() {
    if (_level == 1) {
      _activeCategories = [WordCategory.fruit, WordCategory.animal, WordCategory.color];
    } else if (_level == 2) {
      _activeCategories = [WordCategory.fruit, WordCategory.animal, WordCategory.color, WordCategory.vehicle, WordCategory.food];
    } else if (_level == 3) {
      _activeCategories = [WordCategory.fruit, WordCategory.animal, WordCategory.color, WordCategory.vehicle, WordCategory.food, WordCategory.clothing];
    } else {
      _activeCategories = WordCategory.values;
    }
    setState(() {});
  }

  Future<void> _levelUp() async {
    setState(() {
      _level++;
      _combo = 0;
      _setCategoriesForLevel();
    });
    
    await _playLevelUpSound();
    _showMessage('🎉 Niveau $_level atteint ! Nouvelles catégories débloquées', isSuccess: true);
  }

  Future<void> _gameComplete() async {
    setState(() {
      _isPlaying = false;
      _showResult = true;
      _resultMessage = '🏆 FÉLICITATIONS ! 🏆\n\nScore final: $_score points\nCombo max: x$_combo\nNiveau atteint: $_level\n\nBravo champion ! 🎉';
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
        activityType: 'category_game',
        title: 'Jeu des Catégories',
        description: 'Mot "${_currentWord?.word}" classé dans ${_currentWord?.category.label}',
        points: _currentWord?.points ?? 15,
      );
    }
  }

  Future<void> _saveFinalActivity() async {
    if (widget.childId != null) {
      final historyService = ActivityHistoryService();
      await historyService.addActivitySimple(
        childId: widget.childId!,
        activityType: 'category_game_complete',
        title: '🎉 Jeu des Catégories terminé !',
        description: 'Score final: $_score points - Super classement !',
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
            _buildHelpItem('1️⃣', 'Scanne le mot affiché avec la caméra'),
            _buildHelpItem('2️⃣', 'ML Kit reconnaît le mot'),
            _buildHelpItem('3️⃣', 'Choisis la bonne catégorie'),
            _buildHelpItem('4️⃣', 'Gagne 15 points par bonne réponse'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildHelpItem('⚡', 'Réponds vite pour un bonus de rapidité'),
            _buildHelpItem('🔥', 'Enchaîne les bonnes réponses pour un combo'),
            _buildHelpItem('⭐', 'Monte de niveau pour débloquer + de catégories'),
            _buildHelpItem('🏆', 'Termine les 10 mots pour un bonus final'),
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
          '🎯 Jeu des Catégories',
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
              child: const Text('🎯', style: TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: 24),
            Text(
              'Jeu des Catégories',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scanne le mot et place-le dans la bonne catégorie !\nGagne des points et monte de niveau.',
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
                  _buildStatItem('📚', 'Mots', '${_words.length}'),
                  _buildStatItem('⭐', 'Niveaux', '4'),
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
              _buildGameStat('📝', 'Restants', '$_remainingQuestions'),
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
                  Text('${_remainingQuestions}/10 mots', style: GoogleFonts.poppins(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: _remainingQuestions / 10,
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
                  : _buildGamePlayScreen(isDarkMode),
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

  Widget _buildGamePlayScreen(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(30),
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
                  _currentWord?.emoji ?? '📖',
                  style: const TextStyle(fontSize: 60),
                ),
                const SizedBox(height: 16),
                if (_recognizedWord.isNotEmpty)
                  Text(
                    _recognizedWord.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9C27B0),
                    ),
                  )
                else
                  Text(
                    'Scanner le mot',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_recognizedWord.isEmpty)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: ElevatedButton.icon(
                    onPressed: _scanWord,
                    icon: const Icon(Icons.camera_alt, size: 28),
                    label: const Text('Scanner le mot', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            )
          else
            Column(
              children: [
                Text(
                  'Choisis la bonne catégorie',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: _activeCategories.map((category) {
                    return GestureDetector(
                      onTap: () => _checkCategory(category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [category.categoryColor, category.categoryColor.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: category.categoryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(category.emoji, style: const TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            Text(
                              category.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
        ],
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
            'Analyse en cours...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9C27B0),
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
                      if (!_isCorrect && _correctCategory != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _correctCategory!.categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _correctCategory!.categoryColor.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Bonne catégorie :',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_correctCategory!.emoji, style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 8),
                                  Text(
                                    _correctCategory!.label,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _correctCategory!.categoryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),
                      if (_remainingQuestions > 0)
                        LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Colors.grey.shade200,
                          color: const Color(0xFF9C27B0),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      if (_remainingQuestions > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Prochain mot dans 2 secondes...',
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
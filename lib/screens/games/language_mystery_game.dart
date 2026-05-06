// lib/screens/games/language_mystery_game.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/language_mystery.dart';
import '../../services/sound_service.dart';
import '../../services/activity_history_service.dart';

class LanguageMysteryGame extends StatefulWidget {
  final String? childId;
  const LanguageMysteryGame({super.key, this.childId});

  @override
  State<LanguageMysteryGame> createState() => _LanguageMysteryGameState();
}

class _LanguageMysteryGameState extends State<LanguageMysteryGame>
    with TickerProviderStateMixin {
  final SoundService _soundService = SoundService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<MysteryPhrase> _phrases = [];
  MysteryPhrase? _currentPhrase;
  List<MysteryPhrase> _availablePhrases = [];
  List<MysteryLanguage> _languages = [];
  
  int _score = 0;
  int _level = 1;
  int _combo = 0;
  int _bestScore = 0;
  int _remainingQuestions = 10;
  int _totalQuestions = 0;
  bool _isPlaying = false;
  bool _isProcessing = false;
  bool _showResult = false;
  bool _isCorrect = false;
  String _resultMessage = '';
  String? _selectedLanguageCode;

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
    _phrases = MysteryPhrase.getAllPhrases();
    _availablePhrases = List.from(_phrases);
    _languages = MysteryLanguage.getLanguages();
    _totalQuestions = _phrases.length;
    _selectNewPhrase();
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
      _bestScore = prefs.getInt('language_best_score') ?? 0;
    });
  }

  Future<void> _saveBestScore() async {
    if (_score > _bestScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('language_best_score', _score);
      setState(() => _bestScore = _score);
    }
  }

  void _selectNewPhrase() {
    if (_availablePhrases.isEmpty) {
      _availablePhrases = List.from(_phrases);
    }
    
    final available = _availablePhrases.where((p) => p.difficulty <= _level).toList();
    if (available.isNotEmpty) {
      setState(() {
        _currentPhrase = available[DateTime.now().millisecondsSinceEpoch % available.length];
        _availablePhrases.remove(_currentPhrase);
        _showResult = false;
        _selectedLanguageCode = null;
        _isProcessing = false;
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
      _availablePhrases = List.from(_phrases);
      _selectNewPhrase();
    });
  }

  Future<void> _checkAnswer(String languageCode) async {
    if (_showResult || _isProcessing) return;
    
    await _soundService.playClick();
    
    setState(() {
      _selectedLanguageCode = languageCode;
      _isProcessing = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    
    final isCorrect = languageCode == _currentPhrase!.languageCode;
    
    if (isCorrect) {
      await _onCorrectAnswer();
    } else {
      await _onWrongAnswer(languageCode);
    }
    
    setState(() => _isProcessing = false);
  }

  Future<void> _onCorrectAnswer() async {
    final difficultyBonus = _currentPhrase!.difficulty * 5;
    final comboBonus = _combo * 10;
    final totalEarned = _currentPhrase!.points + difficultyBonus + comboBonus;
    
    setState(() {
      _showResult = true;
      _score += totalEarned;
      _combo++;
      _remainingQuestions--;
      _resultMessage = '+$totalEarned points ! 🔥 Combo x$_combo\n📚 +${_currentPhrase!.points} points\n⚡ Bonus combo: +$comboBonus\n⭐ Bonus difficulté: +$difficultyBonus\n\n📖 Traduction: "${_currentPhrase!.translation}"';
      _isCorrect = true;
    });
    
    await _playSuccessSound();
    _progressController.forward(from: 0);
    _confettiController.forward(from: 0);
    
    await _saveActivity();
    
    if (_score >= _level * 400) {
      await _levelUp();
    }
    
    if (_remainingQuestions <= 0) {
      await _levelComplete();
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isPlaying) {
          _selectNewPhrase();
        }
      });
    }
  }

  Future<void> _onWrongAnswer(String guessedCode) async {
    final guessedLanguage = _languages.firstWhere(
      (l) => l.code == guessedCode,
      orElse: () => _languages.first,
    );
    
    setState(() {
      _showResult = true;
      _combo = 0;
      _resultMessage = '❌ Ce n\'est pas ${guessedLanguage.name} !\n\n📖 La bonne réponse était : ${_currentPhrase!.languageName} ${_currentPhrase!.flag}\n📖 Traduction: "${_currentPhrase!.translation}"\n\n💡 Indice: ${_currentPhrase!.hint}';
      _isCorrect = false;
    });
    
    await _playErrorSound();
    _shakeController.forward();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isPlaying) {
        _selectNewPhrase();
      }
    });
  }

  Future<void> _levelUp() async {
    if (_level < MysteryPhrase.getMaxDifficulty()) {
      setState(() {
        _level++;
        _combo = 0;
        _remainingQuestions = 10;
      });
      await _playLevelUpSound();
      _showMessage('🎉 Niveau $_level atteint ! Nouvelles langues débloquées', isSuccess: true);
    } else if (_level == MysteryPhrase.getMaxDifficulty()) {
      await _gameComplete();
    }
  }

  Future<void> _levelComplete() async {
    final bonusPoints = _level * 100;
    setState(() {
      _score += bonusPoints;
      _resultMessage = '🌟 NIVEAU $_level COMPLÉTÉ ! 🌟\n\n+$bonusPoints points bonus !\n\nPasse au niveau suivant !';
      _showResult = true;
      _isCorrect = true;
    });
    
    await _playLevelUpSound();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isPlaying) {
        if (_level < MysteryPhrase.getMaxDifficulty()) {
          _levelUp();
          _selectNewPhrase();
        } else {
          _gameComplete();
        }
      }
    });
  }

  Future<void> _gameComplete() async {
    setState(() {
      _isPlaying = false;
      _showResult = true;
      _resultMessage = '🏆 FÉLICITATIONS ! 🏆\n\n🌍 VOUS AVEZ TERMINÉ LE JEU ! 🌍\n\nScore final: $_score points\nNiveaux complétés: $_level/${MysteryPhrase.getMaxDifficulty()}\nLangues découvertes: ${_level * 5}\nCombo max: x$_combo\n\nTu es un véritable expert des langues ! 🕵️‍♂️✨';
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
        activityType: 'language_mystery',
        title: 'Jeu Langue Mystère',
        description: 'Phrase "${_currentPhrase?.text}" devinée en ${_currentPhrase?.languageName}',
        points: _currentPhrase?.points ?? 20,
      );
    }
  }

  Future<void> _saveFinalActivity() async {
    if (widget.childId != null) {
      final historyService = ActivityHistoryService();
      await historyService.addActivitySimple(
        childId: widget.childId!,
        activityType: 'language_mystery_complete',
        title: '🎉 Jeu Langue Mystère terminé !',
        description: 'Score final: $_score points - Maître des langues !',
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
        backgroundColor: isError ? Colors.red : (isSuccess ? Colors.green : const Color(0xFF2196F3)),
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
            _buildHelpItem('1️⃣', 'Lis la phrase mystère'),
            _buildHelpItem('2️⃣', 'Observe les caractères'),
            _buildHelpItem('3️⃣', 'Devine la langue'),
            _buildHelpItem('4️⃣', 'Clique sur le drapeau pour répondre'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildHelpItem('💡', 'Utilise l\'indice pour t\'aider'),
            _buildHelpItem('🌍', 'Découvre la traduction après ta réponse'),
            _buildHelpItem('🔥', 'Enchaîne les bonnes réponses pour un combo'),
            _buildHelpItem('⭐', 'Monte de niveau pour découvrir + de langues'),
            _buildHelpItem('🏆', 'Termine tous les niveaux pour devenir expert'),
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
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFE3F2FD),
      appBar: AppBar(
        title: Text(
          '🌍 Langue Mystère',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF2196F3),
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
    final totalLanguages = MysteryLanguage.getLanguages().length;
    final maxDifficulty = MysteryPhrase.getMaxDifficulty();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('🌍', style: TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: 24),
            Text(
              'Langue Mystère',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Devine la langue mystère !\nDécouvre des langues du monde entier.',
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
                  _buildStatItem('🌍', 'Langues', '$totalLanguages'),
                  _buildStatItem('⭐', 'Niveaux', '$maxDifficulty'),
                  _buildStatItem('📚', 'Phrases', '${_totalQuestions}'),
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
                      backgroundColor: const Color(0xFF2196F3),
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
    final maxDifficulty = MysteryPhrase.getMaxDifficulty();
    final levelProgress = _level / maxDifficulty;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGameStat('🏆', 'Score', '$_score'),
              _buildGameStat('⭐', 'Niveau', '$_level/$maxDifficulty'),
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
                  Text('Niveau $_level', style: GoogleFonts.poppins(fontSize: 12)),
                  Text('${_remainingQuestions}/10 défis', style: GoogleFonts.poppins(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: levelProgress,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF2196F3),
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
                  : _buildMysteryScreen(isDarkMode),
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

  Widget _buildMysteryScreen(bool isDarkMode) {
    final availableLanguages = _languages.where((l) => l.difficulty <= _level).toList();

    return Center(
      child: SingleChildScrollView(
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
                    color: const Color(0xFF2196F3).withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '🔍 Quelle est cette langue ?',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _currentPhrase?.text ?? '???',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2196F3),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '💡 Indice: ${_currentPhrase?.hint ?? ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Choisis la bonne langue :',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: availableLanguages.map((language) {
                final isSelected = _selectedLanguageCode == language.code;
                return GestureDetector(
                  onTap: () => _checkAnswer(language.code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 100,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          language.color,
                          language.color.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: language.color.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(language.flag, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          language.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                    strokeWidth: 3,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Vérification...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2196F3),
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
                      const SizedBox(height: 32),
                      if (_remainingQuestions > 0 || _level < MysteryPhrase.getMaxDifficulty())
                        LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Colors.grey.shade200,
                          color: const Color(0xFF2196F3),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      if (_remainingQuestions > 0 || _level < MysteryPhrase.getMaxDifficulty())
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _remainingQuestions > 0 ? 'Prochain défi dans 2 secondes...' : 'Chargement du niveau suivant...',
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
    _pulseController.dispose();
    _shakeController.dispose();
    _progressController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
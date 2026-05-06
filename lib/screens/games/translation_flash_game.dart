// lib/screens/games/translation_flash_game.dart
import 'dart:async';
import 'package:edulearn_final/screens/history/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/translation_word.dart';
import '../../services/translation_game_service.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../services/activity_history_service.dart';

class TranslationFlashGame extends StatefulWidget {
  final String? childId;
  const TranslationFlashGame({super.key, this.childId});

  @override
  State<TranslationFlashGame> createState() => _TranslationFlashGameState();
}

class SeriesCategorySelector extends StatefulWidget {
  final Function(String series, String category) onSelected;
  
  const SeriesCategorySelector({super.key, required this.onSelected});

  @override
  State<SeriesCategorySelector> createState() => _SeriesCategorySelectorState();
}

class _SeriesCategorySelectorState extends State<SeriesCategorySelector> {
  String _selectedSeries = 'Série 1';
  String _selectedCategory = 'Animaux';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sélecteur de série
          DropdownButtonFormField<String>(
            value: _selectedSeries,
            items: TranslationWord.getSeriesList().map((series) {
              return DropdownMenuItem(value: series, child: Text(series));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedSeries = value);
              }
            },
            decoration: const InputDecoration(
              labelText: 'Série',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Sélecteur de catégorie
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: TranslationWord.getCategories().map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
            },
            decoration: const InputDecoration(
              labelText: 'Catégorie',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSelected(_selectedSeries, _selectedCategory);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Commencer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranslationFlashGameState extends State<TranslationFlashGame>
    with TickerProviderStateMixin {
  final TranslationGameService _translationService = TranslationGameService();
  final SoundService _soundService = SoundService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<TranslationWord> _words = [];
  TranslationWord? _currentWord;
  List<TranslationWord> _availableWords = [];
  
  int _score = 0;
  int _level = 1;
  int _combo = 0;
  int _bestScore = 0;
  int _remainingQuestions = 10;
  int _timeRemaining = 20;
  bool _isPlaying = false;
  bool _isProcessing = false;
  bool _showResult = false;
  String _resultMessage = '';
  bool _isCorrect = false;
  String _userAnswer = '';

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
    _words = TranslationWord.getAllWords();
    _availableWords = List.from(_words);
    _selectNewWord();
    _showSeriesCategoryDialog();
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
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _timerAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _timerController, curve: Curves.linear),
    )..addListener(() {
      if (mounted && _isPlaying) {
        setState(() {
          _timeRemaining = (20 * _timerAnimation.value).ceil();
        });
      }
    });
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('translation_best_score') ?? 0;
    });
  }

  Future<void> _saveBestScore() async {
    if (_score > _bestScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('translation_best_score', _score);
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
        _timeRemaining = 20;
        _showResult = false;
        _userAnswer = '';
        _answerController.clear();
        _timerController.forward(from: 0);
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
    _focusNode.requestFocus();
  }

  void _loadWordsBySelection(String series, String category) {
    setState(() {
      _words = TranslationWord.getWordsBySeriesAndCategory(series, category);
      if (_words.isEmpty) {
        _words = TranslationWord.getAllWords();
      }
      _availableWords = List.from(_words);
      _selectNewWord();
    });
  }

  void _showSeriesCategoryDialog() {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Choisis ta série et catégorie'),
          content: SeriesCategorySelector(
            onSelected: (series, category) {
              _loadWordsBySelection(series, category);
              Navigator.pop(context);
              _startGame();
            },
          ),
        ),
      );
    });
  }

  Future<void> _checkAnswer() async {
    if (_isProcessing || !_isPlaying || _currentWord == null) return;
    
    final userAnswer = _answerController.text.trim();
    if (userAnswer.isEmpty) {
      _showMessage('✏️ Entrez votre réponse', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _userAnswer = userAnswer;
    });

    await _soundService.playClick();
    
    final isCorrect = await _translationService.checkTranslation(
      userAnswer, 
      _currentWord!,
    );

    await Future.delayed(const Duration(milliseconds: 500));
    
    if (isCorrect) {
      await _onCorrectAnswer();
    } else {
      await _onWrongAnswer();
    }
    
    setState(() => _isProcessing = false);
  }

  

  // Modifiez _onCorrectAnswer pour sauvegarder le combo et le niveau
Future<void> _onCorrectAnswer() async {
  _timerController.stop();
  
  final timeBonus = (_timeRemaining ~/ 2) * 2;
  final comboBonus = _combo * 5;
  final difficultyBonus = _currentWord!.difficulty * 2;
  final totalEarned = _currentWord!.basePoints + timeBonus + comboBonus + difficultyBonus;
  
  setState(() {
    _showResult = true;
    _score += totalEarned;
    _combo++;
    _remainingQuestions--;
    _resultMessage = '+$totalEarned points ! 🔥 Combo x$_combo\n⭐ Bonus rapidité: +$timeBonus\n⚡ Bonus combo: +$comboBonus\n📚 Difficulté: +$difficultyBonus';
    _isCorrect = true;
  });
  
  await _playSuccessSound();
  _progressController.forward(from: 0);
  
  // Sauvegarder l'activité dans l'historique
  await _saveActivity();
  
  if (_score >= _level * 100) {
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
    _timerController.stop();
    
    setState(() {
      _showResult = true;
      _combo = 0;
      _resultMessage = '❌ La bonne réponse était : "${_currentWord!.translation}"\n💡 Continue à t\'entraîner !';
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

  Future<void> _levelUp() async {
    setState(() {
      _level++;
      _combo = 0;
    });
    
    await _playLevelUpSound();
    _showMessage('🎉 Niveau $_level atteint ! Nouvelles difficultés débloquées', isSuccess: true);
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

  // Modifiez la méthode _saveActivity
Future<void> _saveActivity() async {
  if (widget.childId != null) {
    try {
      final historyService = HistoryFirebaseService();
      await historyService.saveHistoryItem(
        HistoryItem(
          id: 'translation_${DateTime.now().millisecondsSinceEpoch}_${widget.childId}',
          type: 'translation_game',
          category: 'game',  // ← AJOUTER CETTE LIGNE (c'est un jeu)
          title: '✨ Mot traduit: ${_currentWord?.word}',
          subtitle: 'Traduction: ${_currentWord?.translation}',
          timestamp: DateTime.now(),
          points: _currentWord?.basePoints ?? 10,
          details: {
            'Mot': _currentWord?.word ?? '',
            'Traduction': _currentWord?.translation ?? '',
            'Points gagnés': _currentWord?.basePoints ?? 10,
            'Bonus rapidité': (_timeRemaining ~/ 2) * 2,
            'Bonus combo': _combo * 5,
            'Niveau': _level,
            'Temps restant': '${_timeRemaining}s',
            'Combo': 'x${_combo + 1}',
          },
          childId: widget.childId!,
          childName: await _getChildName(),
        ),
      );
    } catch (e) {
      print('Erreur sauvegarde historique: $e');
    }
  }
}

  // Modifiez la méthode _saveFinalActivity
Future<void> _saveFinalActivity() async {
  if (widget.childId != null) {
    try {
      final historyService = HistoryFirebaseService();
      await historyService.saveHistoryItem(
        HistoryItem(
          id: 'translation_complete_${DateTime.now().millisecondsSinceEpoch}_${widget.childId}',
          type: 'translation_game',
          category: 'game',  // ← AJOUTER CETTE LIGNE (c'est un jeu)
          title: '🏆 Jeu Traduction Flash terminé !',
          subtitle: 'Score final: $_score points - Niveau $_level atteint',
          timestamp: DateTime.now(),
          points: _score,
          details: {
            'Score total': _score,
            'Niveau atteint': _level,
            'Combo maximum': _combo,
            'Meilleur score': _bestScore,
            'Mots traduits': (10 - _remainingQuestions),
            'Total mots': 10,
            'Date': DateTime.now().toString(),
          },
          childId: widget.childId!,
          childName: await _getChildName(),
        ),
      );
    } catch (e) {
      print('Erreur sauvegarde historique final: $e');
    }
  }
}

// Ajoutez cette méthode pour récupérer le nom de l'enfant
Future<String> _getChildName() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('child_name_${widget.childId}') ?? 'Enfant';
  } catch (e) {
    return 'Enfant';
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
            _buildHelpItem('1️⃣', 'Regarde le mot en français'),
            _buildHelpItem('2️⃣', 'Écris sa traduction en anglais'),
            _buildHelpItem('3️⃣', 'Valide ta réponse'),
            _buildHelpItem('4️⃣', 'Gagne des points selon la rapidité'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildHelpItem('⚡', 'Plus tu réponds vite, plus tu gagnes de points'),
            _buildHelpItem('🔥', 'Enchaîne les bonnes réponses pour un combo'),
            _buildHelpItem('⭐', 'Monte de niveau pour débloquer des mots difficiles'),
            _buildHelpItem('🏆', 'Termine les 10 mots pour gagner un bonus'),
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
          '🌍 Traduction Flash',
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
              'Traduction Flash',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Traduis les mots du français vers l\'anglais\nle plus rapidement possible !',
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
                    onPressed: _showSeriesCategoryDialog,
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
    return Column(
      children: [
        // Header
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
              _buildGameStat('⭐', 'Niveau', '$_level'),
              _buildGameStat('🔥', 'Combo', 'x${_combo > 0 ? _combo : 1}'),
              _buildGameStat('📝', 'Restants', '$_remainingQuestions'),
            ],
          ),
        ),
        
        // Progression
        Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_remainingQuestions}/10 mots', style: GoogleFonts.poppins(fontSize: 12)),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('⏰ $_timeRemaining s', style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: _remainingQuestions / 10,
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF2196F3),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
        
        // Zone de jeu
        Expanded(
          child: _showResult
              ? _buildResultScreen(isDarkMode)
              : _buildQuestionScreen(isDarkMode),
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

  Widget _buildQuestionScreen(bool isDarkMode) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
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
                  Text(
                    _currentWord?.emoji ?? '📖',
                    style: const TextStyle(fontSize: 60),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentWord?.word ?? 'Mot',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Traduis en anglais',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _answerController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Écris la traduction ici...',
                  prefixIcon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                style: GoogleFonts.poppins(fontSize: 16),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _checkAnswer(),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _checkAnswer,
                      icon: const Icon(Icons.check_circle, size: 24),
                      label: const Text('VALIDER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Appuie sur Entrée pour valider ou clique sur le bouton',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
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
                  const SizedBox(height: 24),
                  if (_userAnswer.isNotEmpty && !_isCorrect)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Ta réponse : "$_userAnswer"',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bonne réponse : "${_currentWord?.translation}"',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  if (_remainingQuestions > 0)
                    LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.grey.shade200,
                      color: const Color(0xFF2196F3),
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
        );
      },
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    _focusNode.dispose();
    _timerController.dispose();
    _pulseController.dispose();
    _shakeController.dispose();
    _progressController.dispose();
    _audioPlayer.dispose();
    _translationService.dispose();
    super.dispose();
  }
}
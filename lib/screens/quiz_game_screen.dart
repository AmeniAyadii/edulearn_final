import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import '../services/quiz_service.dart';
import '../theme/app_theme.dart';
import 'dart:async';

// ============================================================================
// CONSTANTES
// ============================================================================

class QuizConstants {
  static const int pointsPerQuestion = 10;
  static const int bonusForCombo = 5;
  static const int levelUpScore = 100;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const List<String> medals = ['🥉', '🥈', '🥇', '🏆'];
  static const List<String> celebrations = ['🎉', '🎊', '✨', '⭐', '🌟'];
}

// ============================================================================
// MODÈLES
// ============================================================================

class QuizStats {
  int correctAnswers;
  int totalQuestions;
  int currentStreak;
  int bestStreak;
  int totalScore;

  QuizStats({
    this.correctAnswers = 0,
    this.totalQuestions = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.totalScore = 0,
  });

  double get percentage => totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;
  int get remainingQuestions => totalQuestions - (correctAnswers + (totalQuestions - (correctAnswers + (totalQuestions - (correctAnswers)))));
}

// ============================================================================
// ÉCRAN PRINCIPAL
// ============================================================================

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen>
    with TickerProviderStateMixin {
  // Services
  final QuizService _quizService = QuizService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  // État du jeu
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int _currentLevel = 1;
  QuizStats _stats = QuizStats();
  bool _isLoading = true;
  bool _isAnswered = false;
  bool _isCorrect = false;
  int? _selectedOptionIndex;
  String _childName = 'Petit Génie';

  // Animations
  late AnimationController _shakeController;
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;

  // Timer
  Timer? _timer;
  int _timeLeft = 15;
  static const int maxTime = 15;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadQuestions();
    _preloadSounds();
  }

  void _initAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  Future<void> _preloadSounds() async {
    await _audioPlayer.setSource(AssetSource('sounds/success.mp3'));
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final data = await _quizService.getQuestionsByLevel(_currentLevel);
    _questions = List.from(data['questions']);
    _stats = QuizStats(totalQuestions: _questions.length);
    _startTimer();
    setState(() => _isLoading = false);
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = maxTime;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft <= 1 && !_isAnswered) {
        timer.cancel();
        if (!_isAnswered) {
          _handleTimeOut();
        }
      } else if (!_isAnswered) {
        setState(() => _timeLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  void _handleTimeOut() {
    setState(() {
      _isAnswered = true;
      _isCorrect = false;
    });
    _shakeController.forward();
    _playFeedback(isCorrect: false);
    _showSnackBar('⏰ Temps écoulé !', isError: true);
    
    Future.delayed(const Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _answerQuestion(int index) {
    if (_isAnswered) return;
    
    setState(() {
      _isAnswered = true;
      _selectedOptionIndex = index;
      final selectedAnswer = _questions[_currentQuestionIndex]['options'][index];
      _isCorrect = selectedAnswer == _questions[_currentQuestionIndex]['correctAnswer'];
    });

    _timer?.cancel();

    if (_isCorrect) {
      _handleCorrectAnswer();
    } else {
      _handleWrongAnswer();
    }
  }

  void _handleCorrectAnswer() {
    final points = QuizConstants.pointsPerQuestion + 
        (_stats.currentStreak * QuizConstants.bonusForCombo);
    
    setState(() {
      _stats.correctAnswers++;
      _stats.totalScore += points;
      _stats.currentStreak++;
      if (_stats.currentStreak > _stats.bestStreak) {
        _stats.bestStreak = _stats.currentStreak;
      }
    });

    _scaleController.forward();
    _playFeedback(isCorrect: true);
    _showCelebration();

    // Sauvegarder le score
    _quizService.saveScore(_currentLevel, _stats.totalScore, 
        _questions.length, _childName);

    // Vérifier passage au niveau supérieur
    _checkLevelUp();

    _showSnackBar('✅ +$points points ! (Série de ${_stats.currentStreak})', 
        isSuccess: true);
    
    Future.delayed(const Duration(seconds: 1), () => _nextQuestion());
  }

  void _handleWrongAnswer() {
    setState(() {
      _stats.currentStreak = 0;
    });
    _shakeController.forward();
    _playFeedback(isCorrect: false);
    
    final correctAnswer = _questions[_currentQuestionIndex]['correctAnswer'];
    _showSnackBar('❌ La bonne réponse était : $correctAnswer', isError: true);
    
    Future.delayed(const Duration(seconds: 2), () => _nextQuestion());
  }

  void _checkLevelUp() {
    if (_stats.totalScore >= QuizConstants.levelUpScore && _currentLevel < 3) {
      setState(() => _currentLevel++);
      _showSnackBar('🎉 FÉLICITATIONS ! NIVEAU ${_currentLevel} DÉVERROUILLÉ ! 🎉', 
          isSuccess: true);
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex + 1 >= _questions.length) {
      _endGame();
      return;
    }

    setState(() {
      _currentQuestionIndex++;
      _isAnswered = false;
      _isCorrect = false;
      _selectedOptionIndex = null;
    });
    _startTimer();
  }

  void _endGame() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildEndGameDialog(),
    );
  }

  void _resetGame() {
    setState(() {
      _currentQuestionIndex = 0;
      _stats = QuizStats(totalQuestions: _questions.length);
      _isAnswered = false;
      _selectedOptionIndex = null;
      _timeLeft = maxTime;
    });
    _startTimer();
    Navigator.pop(context);
  }

  void _playFeedback({required bool isCorrect}) async {
    try {
      if (isCorrect) {
        await _audioPlayer.play(AssetSource('sounds/success.mp3'));
        if (await Vibrate.canVibrate) {
          Vibrate.feedback(FeedbackType.heavy);
        }
      } else {
        if (await Vibrate.canVibrate) {
          Vibrate.feedback(FeedbackType.error);
        }
      }
    } catch (e) {}
  }

  void _showCelebration() {
    // Animation de célébration
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    Color backgroundColor;
    if (isError) backgroundColor = AppTheme.errorColor;
    else if (isSuccess) backgroundColor = AppTheme.successColor;
    else backgroundColor = AppTheme.infoColor;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Chargement des questions...',
                style: GoogleFonts.poppins(color: AppTheme.textLight),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec stats
            _buildHeader(),
            
            // Barre de progression
            _buildProgressBar(),
            
            // Timer
            _buildTimer(),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Catégorie
                    _buildCategory(currentQuestion),
                    
                    const SizedBox(height: 20),
                    
                    // Question
                    _buildQuestion(currentQuestion),
                    
                    const SizedBox(height: 24),
                    
                    // Options
                    ..._buildOptions(currentQuestion),
                  ],
                ),
              ),
            ),
            
            // Navigation
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Niveau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  'Niveau $_currentLevel',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${_stats.totalScore} pts',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Série
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  '${_stats.currentStreak}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.grey.shade200,
      color: AppTheme.primaryColor,
      minHeight: 4,
    );
  }

  Widget _buildTimer() {
    final isUrgent = _timeLeft <= 5;
    return Container(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isUrgent ? Colors.red.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: _timeLeft / maxTime,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey.shade200,
                  color: isUrgent ? Colors.red : AppTheme.primaryColor,
                ),
              ),
              Text(
                '$_timeLeft',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isUrgent ? Colors.red : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategory(Map<String, dynamic> question) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(question['category'], style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildQuestion(Map<String, dynamic> question) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                Text(
                  question['imageIcon'],
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 12),
                Text(
                  question['question'],
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildOptions(Map<String, dynamic> question) {
    final options = List<String>.from(question['options']);
    return options.asMap().entries.map((entry) {
      final index = entry.key;
      final option = entry.value;
      bool isSelected = _selectedOptionIndex == index;
      bool isCorrectAnswer = option == question['correctAnswer'];
      
      Color getOptionColor() {
        if (!_isAnswered) return Colors.white;
        if (isSelected && _isCorrect) return AppTheme.successColor.withOpacity(0.9);
        if (isSelected && !_isCorrect) return AppTheme.errorColor.withOpacity(0.9);
        if (_isAnswered && isCorrectAnswer) return AppTheme.successColor.withOpacity(0.7);
        return Colors.white;
      }
      
      return AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isAnswered ? null : () => _answerQuestion(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: getOptionColor(),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (_isAnswered && isCorrectAnswer) 
                            ? AppTheme.successColor 
                            : Colors.grey.shade200,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              decoration: _isAnswered && isCorrectAnswer && !isSelected
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: (_isAnswered && isCorrectAnswer && !isSelected)
                                  ? Colors.grey
                                  : AppTheme.text,
                            ),
                          ),
                        ),
                        if (_isAnswered && isCorrectAnswer)
                          const Icon(Icons.check_circle, color: Colors.green),
                        if (_isAnswered && isSelected && !_isCorrect)
                          const Icon(Icons.cancel, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Question ${_currentQuestionIndex + 1}/${_questions.length}',
            style: TextStyle(color: AppTheme.textLight),
          ),
          Text(
            '${_stats.correctAnswers} ✅',
            style: TextStyle(
              color: AppTheme.successColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndGameDialog() {
    final percentage = _stats.percentage;
    String medal = QuizConstants.medals[0];
    if (percentage >= 90) medal = QuizConstants.medals[3];
    else if (percentage >= 70) medal = QuizConstants.medals[2];
    else if (percentage >= 50) medal = QuizConstants.medals[1];
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Partie terminée !', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(medal, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Score final : ${_stats.totalScore} points',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Bonnes réponses : ${_stats.correctAnswers}/${_stats.totalQuestions}',
          ),
          const SizedBox(height: 8),
          Text(
            'Meilleure série : ${_stats.bestStreak}',
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade200,
            color: AppTheme.successColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text('${percentage.toStringAsFixed(0)}% de réussite'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: const Text('Quitter'),
        ),
        ElevatedButton(
          onPressed: _resetGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Rejouer'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    _scaleController.dispose();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
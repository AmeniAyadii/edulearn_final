// lib/games/guess_game/screens/solo_game_screen.dart

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/scheduler.dart';
import '../providers/guess_game_provider.dart';
import '../models/game_session.dart';
import 'game_result_screen.dart';

enum VibrationType { light, success, error }

class SoloGameScreen extends StatefulWidget {
  final GameSession session;
  final String childId;
  
  const SoloGameScreen({
    Key? key,
    required this.session,
    required this.childId,
  }) : super(key: key);
  
  @override
  State<SoloGameScreen> createState() => _SoloGameScreenState();
}

class _SoloGameScreenState extends State<SoloGameScreen> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _celebrationController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _celebrationAnimation;
  
  // Controllers
  final TextEditingController _guessController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  // Game State
  int currentClueIndex = 0;
  int attempts = 0;
  int hintsUsed = 0;
  bool isSubmitting = false;
  bool isGameFinished = false;
  bool isRevealingClue = false;
  List<String> wrongGuesses = [];
  
  // Timer
  static const int gameDuration = 90;
  int remainingSeconds = gameDuration;
  Timer? _timer;
  bool isTimeOut = false;
  
  // UI State
  bool showConfetti = false;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startTimer();
    _focusNode.requestFocus();
    _showWelcomeAnimation();
  }
  
  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
    
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _celebrationAnimation = CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    );
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !isGameFinished && !isTimeOut) {
        setState(() {
          if (remainingSeconds > 0) {
            remainingSeconds--;
            _updateProgress(remainingSeconds);
          }
          if (remainingSeconds == 0) {
            timer.cancel();
            setState(() => isTimeOut = true);
            _handleTimeOut();
          }
        });
      }
    });
  }
  
  void _updateProgress(int seconds) {
    final progress = seconds / gameDuration;
    _progressController.animateTo(progress,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }
  
  void _showWelcomeAnimation() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _showSnackBar(
          message: 'Partie commencée ! Bonne chance !',
          icon: Icons.play_arrow,
          color: Colors.green,
        );
      }
    });
  }
  
  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color color,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
  
  void _handleTimeOut() {
    if (!mounted) return;
    
    SchedulerBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildTimeOutDialog(),
      );
    });
  }
  
  Widget _buildTimeOutDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.timer_off, size: 64, color: Colors.red.shade400),
            ),
            const SizedBox(height: 24),
            const Text(
              'Time\'s Up!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The mystery object was:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.purple.shade50],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                widget.session.secretObjectLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text('Quit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.replay, size: 18),
                        SizedBox(width: 8),
                        Text('Play Again'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _revealNextClue() async {
    if (currentClueIndex >= 3 || isRevealingClue) return;
    
    setState(() => isRevealingClue = true);
    await _vibrate(VibrationType.light);
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    setState(() {
      currentClueIndex++;
      hintsUsed++;
      isRevealingClue = false;
    });
    
    _showSnackBar(
      message: 'Clue ${currentClueIndex}/3 revealed!',
      icon: Icons.lightbulb_outline,
      color: Colors.amber,
      duration: const Duration(milliseconds: 800),
    );
  }
  
  Future<void> _submitGuess() async {
    final guess = _guessController.text.trim();
    
    if (guess.isEmpty) {
      await _shakeError();
      _showSnackBar(
        message: 'Please enter a guess!',
        icon: Icons.warning_amber_rounded,
        color: Colors.orange,
        duration: const Duration(seconds: 1),
      );
      return;
    }
    
    if (isSubmitting) return;
    
    setState(() {
      isSubmitting = true;
      attempts++;
    });
    
    await _vibrate(VibrationType.light);
    
    final provider = Provider.of<GuessGameProvider>(context, listen: false);
    final result = await provider.makeGuess(guess, widget.childId);
    
    if (result == GuessResult.correct) {
      await _handleVictory(provider);
    } else {
      await _handleWrongGuess(guess);
    }
    
    setState(() => isSubmitting = false);
  }
  
  Future<void> _handleVictory(GuessGameProvider provider) async {
  final pointsDetails = _calculatePoints();
  
  await _vibrate(VibrationType.success);
  _timer?.cancel();
  setState(() {
    isGameFinished = true;
    showConfetti = true;
  });
  
  _celebrationController.forward();
  
  if (mounted) {
    Future.delayed(const Duration(milliseconds: 800), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameResultScreen(
            points: pointsDetails['total']!, // Correction ici
            attemptsUsed: attempts,
            objectName: widget.session.secretObjectLabel,
            childId: widget.childId,
          ),
        ),
      );
    });
  }
}
  Map<String, int> _calculatePoints() {
    int basePoints = 0;
    if (attempts == 1) basePoints = 15;
    else if (attempts == 2) basePoints = 10;
    else if (attempts >= 3) basePoints = 5;
    
    final multiplier = _getPointsMultiplier();
    final totalPoints = basePoints * multiplier;
    
    int hintBonus = 0;
    if (hintsUsed == 0) hintBonus = 30;
    else if (hintsUsed == 1) hintBonus = 15;
    else if (hintsUsed == 2) hintBonus = 5;
    
    return {
      'total': totalPoints + hintBonus,
      'base': basePoints,
      'multiplier': multiplier,
      'hintBonus': hintBonus,
    };
  }
  
  Future<void> _handleWrongGuess(String guess) async {
    setState(() {
      wrongGuesses.insert(0, guess);
      if (wrongGuesses.length > 3) wrongGuesses.removeLast();
    });
    
    await _vibrate(VibrationType.error);
    await _shakeError();
    
    _showSnackBar(
      message: '"$guess" is not correct! Try again!',
      icon: Icons.close,
      color: Colors.red,
      duration: const Duration(seconds: 2),
    );
    
    _guessController.clear();
    _focusNode.requestFocus();
  }
  
  Future<void> _shakeError() async {
    _shakeController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 300));
    _shakeController.reset();
  }
  
  Future<void> _vibrate(VibrationType type) async {
    if (await Vibration.hasVibrator() ?? false) {
      switch (type) {
        case VibrationType.light:
          await Vibration.vibrate(duration: 30);
          break;
        case VibrationType.success:
          await Vibration.vibrate(pattern: [0, 50, 30, 50]);
          break;
        case VibrationType.error:
          await Vibration.vibrate(pattern: [0, 100, 50, 100]);
          break;
      }
    }
  }
  
  int _getPointsMultiplier() {
    switch (widget.session.difficulty) {
      case Difficulty.easy: return 1;
      case Difficulty.medium: return 2;
      case Difficulty.hard: return 3;
    }
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }
  
  double _getTimeProgress() {
    return remainingSeconds / gameDuration;
  }
  
  Color _getTimerColor() {
    if (remainingSeconds < 10) return Colors.red.shade400;
    if (remainingSeconds < 30) return Colors.orange.shade400;
    return Colors.blue.shade600;
  }
  
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: _buildModernAppBar(),
        body: isTimeOut 
            ? _buildTimeOutWidget() 
            : _buildModernGameContent(),
      ),
    );
  }
  
  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.purple.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text(
            'Solo Mode',
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 18,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey.shade800,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 18),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _getTimerColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: _getTimerColor().withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.timer, size: 18, color: _getTimerColor()),
              const SizedBox(width: 6),
              Text(
                _formatTime(remainingSeconds),
                style: TextStyle(
                  color: _getTimerColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildModernGameContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _getTimeProgress(),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_getTimerColor()),
                    minHeight: 3,
                  );
                },
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatsCard(),
                  const SizedBox(height: 20),
                  _buildDifficultyChip(),
                  const SizedBox(height: 24),
                  _buildMysteryCard(),
                  const SizedBox(height: 24),
                  if (currentClueIndex > 0) _buildCluesTimeline(),
                  const SizedBox(height: 20),
                  if (currentClueIndex < 3 && !isGameFinished)
                    _buildRevealButton(),
                  const SizedBox(height: 24),
                  _buildInputSection(),
                  const SizedBox(height: 16),
                  if (wrongGuesses.isNotEmpty) _buildWrongGuesses(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsCard() {
    final pointsDetails = attempts > 0 ? _calculatePoints() : null;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.quiz_rounded,
            label: 'Attempts',
            value: attempts.toString(),
            color: Colors.blue.shade600,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade200,
          ),
          _buildStatItem(
            icon: Icons.lightbulb_rounded,
            label: 'Hints',
            value: '$currentClueIndex/3',
            color: Colors.amber.shade600,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade200,
          ),
          _buildStatItem(
            icon: Icons.emoji_events_rounded,
            label: 'Potential',
            value: '${_getMaxPoints()} pts',
            color: Colors.orange.shade600,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }
  
  Widget _buildDifficultyChip() {
    final color = _getDifficultyColor();
    final icon = _getDifficultyIcon();
    final text = _getDifficultyText();
    
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              'Difficulty: $text',
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '×${_getPointsMultiplier()}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMysteryCard() {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + (_celebrationAnimation.value * 0.1),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.purple.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200.withOpacity(0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    size: 60,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '❓ What is this object? ❓',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI has selected a mystery object for you',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Use clues to guess correctly',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCluesTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.lightbulb_rounded, size: 16, color: Colors.amber.shade700),
              ),
              const SizedBox(width: 12),
              Text(
                'Available Clues',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '$currentClueIndex/3',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(currentClueIndex, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.session.clues[index].clueText,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildRevealButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton.icon(
        onPressed: _revealNextClue,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isRevealingClue
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.lightbulb_outline, size: 18),
        ),
        label: Text(
          isRevealingClue 
              ? 'Revealing...' 
              : 'Reveal Clue ${currentClueIndex + 1}/3',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          elevation: 2,
        ),
      ),
    );
  }
  
  Widget _buildInputSection() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeController.value * 4, 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _guessController,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Type your answer...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      prefixIcon: Icon(Icons.edit_note_rounded, color: Colors.blue.shade600, size: 22),
                    ),
                    onSubmitted: (_) => _submitGuess(),
                    enabled: !isGameFinished && !isSubmitting,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(6),
                  child: ElevatedButton(
                    onPressed: isSubmitting || isGameFinished ? null : _submitGuess,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.all(18),
                      shape: const CircleBorder(),
                      minimumSize: const Size(56, 56),
                      elevation: 0,
                    ),
                    child: isSubmitting
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildWrongGuesses() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 16, color: Colors.red.shade400),
              const SizedBox(width: 8),
              Text(
                'Wrong guesses',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: wrongGuesses.map((guess) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  guess,
                  style: TextStyle(color: Colors.red.shade600, fontSize: 13),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeOutWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.timer_off_rounded, size: 80, color: Colors.red.shade400),
            ),
            const SizedBox(height: 32),
            const Text(
              'Time\'s Up!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            Text(
              'The mystery object was:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.purple.shade100],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                widget.session.secretObjectLabel,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('New Game', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  int _getMaxPoints() {
    final multiplier = _getPointsMultiplier();
    int basePoints = 0;
    if (attempts == 0) basePoints = 15;
    else if (attempts == 1) basePoints = 10;
    else basePoints = 5;
    
    int hintBonus = 0;
    if (hintsUsed == 0) hintBonus = 30;
    else if (hintsUsed == 1) hintBonus = 15;
    else if (hintsUsed == 2) hintBonus = 5;
    
    return (basePoints * multiplier) + hintBonus;
  }
  
  Color _getDifficultyColor() {
    switch (widget.session.difficulty) {
      case Difficulty.easy: return Colors.green.shade600;
      case Difficulty.medium: return Colors.orange.shade600;
      case Difficulty.hard: return Colors.red.shade600;
    }
  }
  
  IconData _getDifficultyIcon() {
    switch (widget.session.difficulty) {
      case Difficulty.easy: return Icons.star_rounded;
      case Difficulty.medium: return Icons.star_half_rounded;
      case Difficulty.hard: return Icons.star_outline_rounded;
    }
  }
  
  String _getDifficultyText() {
    switch (widget.session.difficulty) {
      case Difficulty.easy: return 'Easy';
      case Difficulty.medium: return 'Medium';
      case Difficulty.hard: return 'Hard';
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _celebrationController.dispose();
    _guessController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
// lib/games/guess_game/screens/guess_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../providers/guess_game_provider.dart';
import '../models/game_session.dart';
import '../widgets/clue_card.dart';
import '../widgets/timer_widget.dart';
import 'game_result_screen.dart';

enum VibrationType { light, success, error }

class GuessScreen extends StatefulWidget {
  final String sessionId;
  final String childId;
  
  const GuessScreen({
    Key? key,
    required this.sessionId,
    required this.childId,
  }) : super(key: key);
  
  @override
  State<GuessScreen> createState() => _GuessScreenState();
}

class _GuessScreenState extends State<GuessScreen> with SingleTickerProviderStateMixin {
  // Animation
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  
  // Controllers
  final TextEditingController _guessController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  // Game state
  int _currentClueIndex = 0;
  int _attempts = 0;
  int _currentPoints = 0;
  bool _isGameFinished = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _lastWrongGuess;
  bool _hasInitialized = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _validateAndJoinGame();
  }
  
  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticIn,
      ),
    );
  }
  
  Future<void> _validateAndJoinGame() async {
    if (widget.sessionId.isEmpty || widget.sessionId == 'null' || widget.sessionId == 'undefined') {
      _showErrorAndExit('❌ ID de session invalide. Veuillez créer une nouvelle partie.');
      return;
    }
    
    if (widget.childId.isEmpty || widget.childId == 'null' || widget.childId == 'undefined') {
      _showErrorAndExit('❌ ID enfant invalide. Veuillez sélectionner un enfant.');
      return;
    }
    
    _focusNode.requestFocus();
    await _joinGame();
  }
  
  void _showErrorAndExit(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showErrorDialog(message);
    });
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Erreur'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
            child: const Text('Retour au menu'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _joinGame() async {
    if (_hasInitialized) return;
    _hasInitialized = true;
    
    setState(() => _isLoading = true);
    
    try {
      final provider = Provider.of<GuessGameProvider>(context, listen: false);
      
      if (provider == null) {
        throw Exception('Provider non initialisé');
      }
      
      print('🔵 Tentative de connexion - Session: ${widget.sessionId}');
      
      await provider.joinGameSession(widget.sessionId, widget.childId);
      
      if (!mounted) return;
      
      final session = provider.currentSession;
      if (session != null) {
        setState(() {
          _currentClueIndex = session.currentClueIndex;
          _attempts = session.attemptsUsed;
          _currentPoints = session.pointsEarned;
          _isGameFinished = session.status == GameStatus.finished;
        });
        print('🟢 Session chargée - Objet: ${session.secretObjectLabel}');
      } else {
        throw Exception('Session non trouvée');
      }
      
      setState(() => _isLoading = false);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showWelcomeMessage();
      });
    } catch (e) {
      print('🔴 Erreur joinGame: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _errorMessage = e.toString();
        
        String userMessage;
        if (e.toString().contains('Session non trouvée')) {
          userMessage = 'Cette partie n\'existe plus. Veuillez en créer une nouvelle.';
        } else if (e.toString().contains('Provider non initialisé')) {
          userMessage = 'Erreur technique. Veuillez redémarrer le jeu.';
        } else {
          userMessage = 'Impossible de charger la partie. Vérifie ta connexion.';
        }
        
        _showErrorDialog(userMessage);
      }
    }
  }
  
  void _showWelcomeMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.play_arrow, color: Theme.of(context).brightness == Brightness.dark ? Colors.green : Colors.green.shade700),
            const SizedBox(width: 10),
            const Text('🎮 Partie chargée ! Bonne chance !'),
          ],
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.green : Colors.green.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
  
  void _revealNextClue() async {
    if (_currentClueIndex >= 3 || _isGameFinished) return;
    
    await _vibrate(VibrationType.light);
    
    setState(() {
      _currentClueIndex++;
      _attempts++;
    });
    
    final provider = Provider.of<GuessGameProvider>(context, listen: false);
    if (provider.currentSession != null) {
      provider.currentSession!.currentClueIndex = _currentClueIndex;
      provider.currentSession!.attemptsUsed = _attempts;
      provider.notifyListeners();
    }
    
    _animationController.forward(from: 0);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber),
            const SizedBox(width: 10),
            Text('💡 Indice $_currentClueIndex/3 dévoilé !'),
          ],
        ),
        backgroundColor: Colors.amber.shade800,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  Future<void> _submitGuess() async {
    final guess = _guessController.text.trim();
    
    if (guess.isEmpty) {
      _shakeError();
      _showErrorSnackBar('Entre une réponse !');
      return;
    }
    
    if (_isSubmitting || _isGameFinished) return;
    
    setState(() {
      _isSubmitting = true;
      _attempts++;
    });
    
    await _vibrate(VibrationType.light);
    
    final provider = Provider.of<GuessGameProvider>(context, listen: false);
    
    try {
      final result = await provider.makeGuess(guess, widget.childId);
      
      if (result == GuessResult.correct) {
        await _handleVictory(provider);
      } else {
        await _handleWrongGuess(guess);
      }
    } catch (e) {
      print('❌ Erreur soumission: $e');
      _showErrorSnackBar('Erreur lors de la vérification. Réessaie.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
  
  Future<void> _handleVictory(GuessGameProvider provider) async {
    final pointsEarned = provider.currentSession?.pointsEarned ?? 0;
    
    await _vibrate(VibrationType.success);
    
    setState(() {
      _isGameFinished = true;
      _currentPoints = pointsEarned;
    });
    
    _animationController.repeat(reverse: true);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber),
            const SizedBox(width: 10),
            const Text('🎉 Félicitations ! Bonne réponse !'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameResultScreen(
            points: pointsEarned,
            attemptsUsed: _attempts,
            objectName: provider.currentSession?.secretObjectLabel ?? '?',
            childId: widget.childId,
          ),
        ),
      );
    }
  }
  
  Future<void> _handleWrongGuess(String guess) async {
    await _vibrate(VibrationType.error);
    _shakeError();
    
    setState(() {
      _lastWrongGuess = guess;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.close, color: Colors.white),
            const SizedBox(width: 10),
            Text('❌ "$guess" n\'est pas correct ! Essaie encore.'),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    _guessController.clear();
    _focusNode.requestFocus();
  }
  
  void _shakeError() {
    if (_animationController.isAnimating) return;
    _animationController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 200), () {
      _animationController.reset();
    });
  }
  
  int _getPointsForAttempts() {
    if (_attempts == 0) return 15;
    if (_attempts == 1) return 10;
    return 5;
  }
  
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GuessGameProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (_errorMessage != null && !_isLoading) {
      return _buildErrorScreen(isDarkMode);
    }
    
    if (_isLoading || provider.currentSession == null) {
      return _buildLoadingScreen(isDarkMode);
    }
    
    final session = provider.currentSession!;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: _buildAppBar(isDarkMode),
      body: Container(
        decoration: _buildBackgroundGradient(isDarkMode),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDarkMode),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 24 : 16),
                  child: Column(
                    children: [
                      _buildMysteryImage(isDarkMode),
                      const SizedBox(height: 20),
                      _buildGameTitle(isDarkMode),
                      const SizedBox(height: 20),
                      if (_currentClueIndex > 0) _buildRevealedClues(session, isDarkMode),
                      const SizedBox(height: 20),
                      if (_currentClueIndex < 3 && !_isGameFinished)
                        _buildRevealClueButton(isDarkMode),
                      const SizedBox(height: 20),
                      _buildInputSection(isDarkMode),
                      const SizedBox(height: 20),
                      _buildPointsHint(isDarkMode),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildErrorScreen(bool isDarkMode) {
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text('Erreur', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                _errorMessage ?? 'Une erreur inattendue est survenue',
                textAlign: TextAlign.center,
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour au menu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingScreen(bool isDarkMode) {
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF))),
            const SizedBox(height: 20),
            Text(
              'Chargement de la partie...',
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.quiz, size: 20, color: Color(0xFF6C63FF)),
          ),
          const SizedBox(width: 10),
          Text(
            'Devine l\'objet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDarkMode ? Colors.white : Colors.grey.shade800,
            ),
          ),
        ],
      ),
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.close, size: 18, color: isDarkMode ? Colors.white : Colors.grey.shade800),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                _getPointsForAttempts().toString(),
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
              ),
              Text(' pts max', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeader(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoChip(icon: Icons.quiz, label: 'Essais', value: '$_attempts', color: Colors.blue, isDarkMode: isDarkMode),
          _buildInfoChip(
            icon: Icons.timer,
            label: 'Temps',
            value: '60s',
            color: Colors.orange,
            isDarkMode: isDarkMode,
            child: const TimerWidget(duration: 60, onTimeout: _onTimeout),
          ),
          _buildInfoChip(icon: Icons.lightbulb, label: 'Indices', value: '$_currentClueIndex/3', color: Colors.amber, isDarkMode: isDarkMode),
        ],
      ),
    );
  }
  
  static void _onTimeout() {}
  
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDarkMode,
    Widget? child,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
            shape: BoxShape.circle,
          ),
          child: child ?? Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.grey.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMysteryImage(bool isDarkMode) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF).withOpacity(isDarkMode ? 0.3 : 0.15),
            const Color(0xFF4A3AFF).withOpacity(isDarkMode ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(isDarkMode ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C63FF), Color(0xFF4A3AFF)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.image_search,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '🔍 Objet Mystère',
            style: TextStyle(
              color: isDarkMode ? Colors.white.withOpacity(0.9) : Colors.grey.shade800,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(isDarkMode ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '✨ Utilise les indices pour deviner ! ✨',
              style: TextStyle(
                color: isDarkMode ? Colors.amber : Colors.amber.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGameTitle(bool isDarkMode) {
    return Column(
      children: [
        Text(
          '❓ Quel est cet objet ? ❓',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.grey.shade800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Observe attentivement les indices et trouve la bonne réponse',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildRevealedClues(GameSession session, bool isDarkMode) {
    if (session.clues.isEmpty || _currentClueIndex == 0) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.15) : Colors.grey.shade200,
        ),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.shade100,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
                  color: Colors.amber.withOpacity(isDarkMode ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb, size: 18, color: Colors.amber),
              ),
              const SizedBox(width: 12),
              Text(
                'Indices révélés',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.grey.shade800,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(isDarkMode ? 0.3 : 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_currentClueIndex/3',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_currentClueIndex, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClueCard(clue: session.clues[index], isRevealed: true),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildRevealClueButton(bool isDarkMode) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.amber, Colors.orange],
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _revealNextClue,
        icon: const Icon(Icons.lightbulb_outline, size: 22, color: Colors.white),
        label: Text(
          '🔓 Dévoiler l\'indice ${_currentClueIndex + 1}/3',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        ),
      ),
    );
  }
  
  Widget _buildInputSection(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.15) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _guessController,
              focusNode: _focusNode,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.grey.shade800,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: '✍️ Écris ta réponse...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white.withOpacity(0.5) : Colors.grey.shade500,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                prefixIcon: Icon(
                  Icons.edit_note,
                  color: isDarkMode ? Colors.white.withOpacity(0.7) : Colors.grey.shade600,
                  size: 22,
                ),
              ),
              onSubmitted: (_) => _submitGuess(),
              enabled: !_isGameFinished && !_isSubmitting,
            ),
          ),
          Container(
            margin: const EdgeInsets.all(5),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSubmitting || _isGameFinished ? null : _submitGuess,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPointsHint(bool isDarkMode) {
    String hint;
    if (_attempts == 0) hint = "🏆 15 points si trouvé du premier coup !";
    else if (_attempts == 1) hint = "⭐ 10 points si trouvé au 2ème essai";
    else if (_attempts == 2) hint = "💪 5 points au 3ème essai";
    else hint = "🎯 Continue d'essayer !";
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.15) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Text(
            hint,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  BoxDecoration _buildBackgroundGradient(bool isDarkMode) {
    if (isDarkMode) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      );
    } else {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _guessController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
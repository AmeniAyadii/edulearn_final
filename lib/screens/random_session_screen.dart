// lib/games/guess_game/screens/random_object_game_screen.dart

import 'package:edulearn_final/screens/games/guess_game/data/objects_database.dart';
import 'package:flutter/material.dart';

import '../models/game_session.dart';

class RandomObjectGameScreen extends StatefulWidget {
  final List<GameObject> objects;
  final String childId;
  final String childName;
  final Difficulty difficulty;
  
  const RandomObjectGameScreen({
    Key? key,
    required this.objects,
    required this.childId,
    required this.childName,
    required this.difficulty,
  }) : super(key: key);
  
  @override
  State<RandomObjectGameScreen> createState() => _RandomObjectGameScreenState();
}

class _RandomObjectGameScreenState extends State<RandomObjectGameScreen> {
  final TextEditingController _guessController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  int _currentObjectIndex = 0;
  int _currentClueIndex = 0;
  int _attempts = 0;
  int _hintsUsed = 0;
  int _totalScore = 0;
  bool _isSubmitting = false;
  List<int> _objectScores = [];
  
  @override
  void initState() {
    super.initState();
    _objectScores = List.filled(widget.objects.length, 0);
    _focusNode.requestFocus();
  }
  
  GameObject get _currentObject => widget.objects[_currentObjectIndex];
  
  double get _progress => (_currentObjectIndex + 1) / widget.objects.length;
  
  void _revealNextClue() {
    if (_currentClueIndex >= 3) return;
    setState(() {
      _currentClueIndex++;
      _hintsUsed++;
    });
  }
  
  Future<void> _submitGuess() async {
    final guess = _guessController.text.trim().toLowerCase();
    
    if (guess.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre une réponse !'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    if (_isSubmitting) return;
    
    setState(() {
      _isSubmitting = true;
      _attempts++;
    });
    
    final isCorrect = guess == _currentObject.name.toLowerCase();
    
    if (isCorrect) {
      int points = 0;
      if (_attempts == 1) points = 15;
      else if (_attempts == 2) points = 10;
      else points = 5;
      
      int hintBonus = 0;
      if (_hintsUsed == 0) hintBonus = 10;
      else if (_hintsUsed == 1) hintBonus = 5;
      
      final totalPoints = points + hintBonus;
      _objectScores[_currentObjectIndex] = totalPoints;
      _totalScore += totalPoints;
      
      if (_currentObjectIndex + 1 >= widget.objects.length) {
        _showSessionComplete();
      } else {
        _showNextObjectDialog(totalPoints);
      }
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ "$guess" n\'est pas correct !'), backgroundColor: Colors.red),
      );
      _guessController.clear();
      _focusNode.requestFocus();
    }
  }
  
  void _showNextObjectDialog(int points) {
    final nextObject = widget.objects[_currentObjectIndex + 1];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('Objet trouvé !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('+$points points', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
            const SizedBox(height: 16),
            Text(
              'Prochain objet : ${nextObject.displayName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${_currentObjectIndex + 2}/${widget.objects.length}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForNextObject();
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }
  
  void _showSessionComplete() {
    final percentage = (_totalScore / (widget.objects.length * 25) * 100).toInt();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber),
            SizedBox(width: 12),
            Text('Session terminée !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Score final : $_totalScore pts',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Objets trouvés : ${_objectScores.where((s) => s > 0).length}/${widget.objects.length}',
            ),
            const SizedBox(height: 8),
            Text(
              'Précision : $percentage%',
              style: TextStyle(
                color: percentage >= 80 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }
  
  void _resetForNextObject() {
    setState(() {
      _currentObjectIndex++;
      _currentClueIndex = 0;
      _attempts = 0;
      _hintsUsed = 0;
      _isSubmitting = false;
      _guessController.clear();
    });
    _focusNode.requestFocus();
  }
  
  String _getDifficultyText() {
    switch (widget.difficulty) {
      case Difficulty.easy: return 'Facile';
      case Difficulty.medium: return 'Moyen';
      case Difficulty.hard: return 'Difficile';
    }
  }
  
  Color _getDifficultyColor() {
    switch (widget.difficulty) {
      case Difficulty.easy: return Colors.green;
      case Difficulty.medium: return Colors.orange;
      case Difficulty.hard: return Colors.red;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatsHeader(),
            const SizedBox(height: 20),
            _buildDifficultyBadge(),
            const SizedBox(height: 20),
            _buildMysteryCard(),
            const SizedBox(height: 20),
            if (_currentClueIndex > 0) _buildCluesSection(),
            if (_currentClueIndex < 3) _buildRevealButton(),
            const Spacer(),
            _buildInputSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        children: [
          const Text('Session aléatoire', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            'Objet ${_currentObjectIndex + 1}/${widget.objects.length}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF6C63FF),
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: LinearProgressIndicator(
          value: _progress,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
  
  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(Icons.quiz_rounded, 'Essais', '$_attempts', Colors.blue),
          _buildStat(Icons.lightbulb_rounded, 'Indices', '$_currentClueIndex/3', Colors.amber),
          _buildStat(Icons.emoji_events_rounded, 'Score', '$_totalScore', Colors.amber),
        ],
      ),
    );
  }
  
  Widget _buildStat(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
        ),
      ],
    );
  }
  
  Widget _buildDifficultyBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _getDifficultyColor().withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _getDifficultyColor().withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getDifficultyIcon(), size: 16, color: _getDifficultyColor()),
            const SizedBox(width: 8),
            Text(
              'Difficulté : ${_getDifficultyText()}',
              style: TextStyle(color: _getDifficultyColor(), fontWeight: FontWeight.w500, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getDifficultyColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '×${_getPointsMultiplier()}',
                style: TextStyle(color: _getDifficultyColor(), fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMysteryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.15),
            const Color(0xFF4A3AFF).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology, size: 55, color: Color(0xFF6C63FF)),
          ),
          const SizedBox(height: 20),
          const Text(
            '❓ Quel est cet objet ? ❓',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Objet ${_currentObjectIndex + 1}/${widget.objects.length}',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCluesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb, size: 16, color: Colors.amber),
              ),
              const SizedBox(width: 10),
              const Text(
                'Indices disponibles',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '$_currentClueIndex/3',
                  style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_currentClueIndex, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentObject.clues[index],
                      style: const TextStyle(color: Colors.white, fontSize: 13),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _revealNextClue,
          icon: const Icon(Icons.lightbulb_outline, size: 18),
          label: Text(
            'Dévoiler l\'indice ${_currentClueIndex + 1}/3',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _guessController,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Écris ta réponse...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                prefixIcon: const Icon(Icons.edit_note, color: Color(0xFF6C63FF), size: 20),
              ),
              onSubmitted: (_) => _submitGuess(),
              enabled: !_isSubmitting,
            ),
          ),
          Container(
            margin: const EdgeInsets.all(4),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitGuess,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(14),
                shape: const CircleBorder(),
                minimumSize: const Size(48, 48),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
  
  int _getPointsMultiplier() {
    switch (widget.difficulty) {
      case Difficulty.easy: return 1;
      case Difficulty.medium: return 2;
      case Difficulty.hard: return 3;
    }
  }
  
  IconData _getDifficultyIcon() {
    switch (widget.difficulty) {
      case Difficulty.easy: return Icons.star;
      case Difficulty.medium: return Icons.star_half;
      case Difficulty.hard: return Icons.star_outline;
    }
  }
  
  @override
  void dispose() {
    _guessController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
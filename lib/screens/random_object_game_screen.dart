// lib/games/guess_game/screens/random_object_game_screen.dart

import 'package:flutter/material.dart';
import '../services/random_session_service.dart';
import '../models/game_session.dart';
import 'game_result_screen.dart';

class RandomObjectGameScreen extends StatefulWidget {
  final RandomGameSession session;
  final String childId;
  final String childName;
  
  const RandomObjectGameScreen({
    Key? key,
    required this.session,
    required this.childId,
    required this.childName,
  }) : super(key: key);
  
  @override
  State<RandomObjectGameScreen> createState() => _RandomObjectGameScreenState();
}

class _RandomObjectGameScreenState extends State<RandomObjectGameScreen> {
  final TextEditingController _guessController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  int currentClueIndex = 0;
  int attempts = 0;
  int hintsUsed = 0;
  bool isSubmitting = false;
  bool isGameFinished = false;
  
  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }
  
  void _revealNextClue() {
    if (currentClueIndex >= 3) return;
    setState(() {
      currentClueIndex++;
      hintsUsed++;
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
    
    if (isSubmitting) return;
    
    setState(() {
      isSubmitting = true;
      attempts++;
    });
    
    final currentObject = widget.session.getCurrentObject();
    final isCorrect = guess == currentObject.name.toLowerCase();
    
    if (isCorrect) {
      int points = 0;
      if (attempts == 1) points = 15;
      else if (attempts == 2) points = 10;
      else points = 5;
      
      // Bonus pour peu d'indices
      int hintBonus = 0;
      if (hintsUsed == 0) hintBonus = 10;
      else if (hintsUsed == 1) hintBonus = 5;
      
      final totalPoints = points + hintBonus;
      
      widget.session.completeCurrentObject(totalPoints);
      
      if (widget.session.isCompleted) {
        _showSessionComplete();
      } else {
        _showNextObjectDialog(totalPoints);
      }
    } else {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ "$guess" n\'est pas correct !'),
          backgroundColor: Colors.red,
        ),
      );
      _guessController.clear();
      _focusNode.requestFocus();
    }
  }
  
  void _showNextObjectDialog(int points) {
    final nextObject = widget.session.getCurrentObject();
    
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
              value: widget.session.progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
            const SizedBox(height: 16),
            Text(
              'Prochain objet : ${nextObject.displayName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.session.completedCount + 1}/${widget.session.objects.length}',
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
    final percentage = (widget.session.totalScore / widget.session.totalPossiblePoints * 100).toInt();
    
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
              'Score final : ${widget.session.totalScore} pts',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Objets trouvés : ${widget.session.completedCount}/${widget.session.objects.length}',
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
            ),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }
  
  void _resetForNextObject() {
    setState(() {
      currentClueIndex = 0;
      attempts = 0;
      hintsUsed = 0;
      isSubmitting = false;
      _guessController.clear();
    });
    _focusNode.requestFocus();
  }
  
  @override
  Widget build(BuildContext context) {
    final currentObject = widget.session.getCurrentObject();
    final progress = widget.session.progress;
    final currentNumber = widget.session.completedCount + 1;
    final totalNumber = widget.session.objects.length;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Session aléatoire', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Objet $currentNumber/$totalNumber',
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
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(Icons.quiz, 'Essais', '$attempts'),
                  _buildStat(Icons.lightbulb, 'Indices', '$currentClueIndex/3'),
                  _buildStat(Icons.emoji_events, 'Score', '${widget.session.totalScore}'),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Mystery container
            Container(
              width: double.infinity,
              height: 180,
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.psychology, size: 60, color: Color(0xFF6C63FF)),
                  const SizedBox(height: 16),
                  const Text(
                    '❓ Quel est cet objet ? ❓',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Objet ${currentNumber}/$totalNumber',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Clues
            if (currentClueIndex > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: List.generate(currentClueIndex, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${index + 1}', style: const TextStyle(color: Colors.black)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentObject.clues[index],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            
            if (currentClueIndex < 3 && !isGameFinished)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton.icon(
                  onPressed: _revealNextClue,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text('Indice ${currentClueIndex + 1}/3'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            
            const Spacer(),
            
            // Input
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _guessController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Ta réponse...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        prefixIcon: const Icon(Icons.edit_note, color: Color(0xFF6C63FF)),
                      ),
                      onSubmitted: (_) => _submitGuess(),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submitGuess,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.all(16),
                        shape: const CircleBorder(),
                      ),
                      child: isSubmitting
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
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
  
  @override
  void dispose() {
    _guessController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
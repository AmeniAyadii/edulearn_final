import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import '../../providers/game_provider.dart';
import '../../widgets/game/language_circle_widget.dart';

class GameResultScreen extends StatefulWidget {
  final File imageFile;
  final String childId;  // ← AJOUTER
  
  const GameResultScreen({
    super.key,
    required this.imageFile,
    required this.childId,  // ← AJOUTER
  });

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  
  String _selectedLanguage = 'fr';
  bool _isNewDiscovery = false;
  
  final List<Map<String, String>> _languages = [
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'},
    {'code': 'nl', 'name': 'Nederlands', 'flag': '🇳🇱'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇦🇪'},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳'},
  ];
  
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();
    _playSuccessSound();
    _checkIfNewDiscovery();
  }
  
  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      // Son non trouvé, ignorer
    }
  }
  
  void _checkIfNewDiscovery() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final isNew = gameProvider.discoveredAnimals
        .every((a) => a.id != gameProvider.currentAnimal?.id);
    setState(() {
      _isNewDiscovery = isNew;
    });
  }
  
  Future<void> _playPronunciation() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final animal = gameProvider.currentAnimal;
    if (animal == null) return;
    
    final textToSpeak = animal.getNameInLanguage(_selectedLanguage);
    
    // Configurer la langue TTS
    await _flutterTts.setLanguage(_selectedLanguage);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    
    // Parler
    await _flutterTts.speak(textToSpeak);
    
    // Marquer comme écouté - Utiliser widget.childId
    await gameProvider.markLanguageListened(
      widget.childId,  // ← Utiliser widget.childId
      animal.id,
      _selectedLanguage,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final animal = gameProvider.currentAnimal;
    
    if (animal == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text("Animal non reconnu", style: TextStyle(fontSize: 18)),
              SizedBox(height: 8),
              Text("Essayez de prendre une autre photo"),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isNewDiscovery
                ? [const Color(0xFF6B11CB), const Color(0xFF2575FC)]
                : [const Color(0xFF11998E), const Color(0xFF38EF7D)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple],
                ),
              ),
              
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '+${animal.basePoints} pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    if (_isNewDiscovery)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.amber),
                              SizedBox(width: 8),
                              Text(
                                'NOUVELLE DÉCOUVERTE !',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.star, color: Colors.amber),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 30),
                    
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(
                          widget.imageFile,
                          height: 200,
                          width: 300,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    Center(
                      child: Column(
                        children: [
                          Text(
                            animal.getNameInLanguage(_selectedLanguage),
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _languages.firstWhere((l) => l['code'] == _selectedLanguage)['name']!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _languages.firstWhere((l) => l['code'] == _selectedLanguage)['flag']!,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    const Text(
                      '🌍 Apprends dans 12 langues',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _languages.length,
                      itemBuilder: (context, index) {
                        final lang = _languages[index];
                        return LanguageCircleWidget(
                          flag: lang['flag']!,
                          languageName: lang['name']!,
                          languageCode: lang['code']!,
                          animalName: animal.getNameInLanguage(lang['code']!),
                          isActive: _selectedLanguage == lang['code'],
                          onTap: () {
                            setState(() {
                              _selectedLanguage = lang['code']!;
                            });
                          },
                          onListen: _playPronunciation,
                          isDiscovered: true,
                        );
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.yellow, size: 30),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              animal.getFunFact(_selectedLanguage),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Continuer l\'aventure →',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }
}
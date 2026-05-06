import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TSService {
  late final FlutterTts _flutterTts;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _flutterTts = FlutterTts();
    
    // Configuration de la voix
    await _flutterTts.setLanguage('fr-FR');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    
    _isInitialized = true;
  }
  
  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Arrêter la lecture en cours
      await _flutterTts.stop();
      
      // Jouer le texte
      await _flutterTts.speak(text);
    } catch (e) {
      print('Erreur TTS: $e');
      // Fallback: utiliser AudioPlayer si FlutterTTS échoue
      await _playFallbackSound();
    }
  }
  
  Future<void> _playFallbackSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      print('Erreur lecture son: $e');
    }
  }
  
  Future<void> stop() async {
    await _flutterTts.stop();
  }
  
  void dispose() {
    _flutterTts.stop();
    _audioPlayer.dispose();
  }
}
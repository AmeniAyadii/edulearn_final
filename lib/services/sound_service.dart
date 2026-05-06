import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'vibration_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'music_service.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final VibrationService _vibration = VibrationService();
  final MusicService _musicService = MusicService();
  
  bool _isSoundEnabled = true;
  bool _isMusicEnabled = true;
  
  
  Future<void> init() async {
    await _loadSettings();
    await _preloadSounds();
    await _loadSettings();
    await _musicService.init();
  }
  
  Future<void> _preloadSounds() async {
    try {
      // CHEMIN CORRIGÉ - sans "assets/" en double
      await _audioPlayer.setSourceAsset('sounds/success.mp3');
      debugPrint('✅ Sons préchargés avec succès');
    } catch (e) {
      debugPrint('❌ Erreur préchargement: $e');
    }
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundEnabled = prefs.getBool('sound') ?? true;
    _isMusicEnabled = prefs.getBool('music') ?? true;
  }
  
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound', _isSoundEnabled);
    await prefs.setBool('music', _isMusicEnabled);
    _musicService.setMusicEnabled(_isMusicEnabled);
  }
  
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isMusicEnabled => _isMusicEnabled;
  
  void setSoundEnabled(bool enabled) {
    _isSoundEnabled = enabled;
    saveSettings();
  }
  
  void setMusicEnabled(bool enabled) {
    _isMusicEnabled = enabled;
    saveSettings();
  }
  
   // Démarrer la musique de fond
  // lib/services/sound_service.dart
Future<void> startBackgroundMusic({String musicPath = 'music/background.mp3'}) async {
  // CORRECTION: Utiliser 'music/background.mp3' au lieu de 'assets/music/background.mp3'
  await _musicService.playBackgroundMusic(musicPath);
}

  // Arrêter la musique de fond
  Future<void> stopBackgroundMusic() async {
    await _musicService.stopBackgroundMusic();
  }

  // Sons UI
  
  
  Future<void> playClick() async {
    await _vibration.click();
    if (!_isSoundEnabled) return;
    await _playFeedback();
    await HapticFeedback.lightImpact();
  }
  
  Future<void> playSuccess() async {
    await _vibration.success();
    if (!_isSoundEnabled) return;
    await _playFeedback();
    await HapticFeedback.mediumImpact();
  }
  
  Future<void> playError() async {
    await _vibration.error();
    if (!_isSoundEnabled) return;
    await HapticFeedback.heavyImpact();
  }
  
  Future<void> playNotification() async {
    if (!_isSoundEnabled) return;
    await _playFeedback();
    await HapticFeedback.lightImpact();
  }
  
  Future<void> playLevelUp() async {
    await _vibration.click();
    if (!_isSoundEnabled) return;
    await _playFeedback();
    await HapticFeedback.mediumImpact();
  }
  
  Future<void> playWelcome() async {
    await _vibration.click();
    if (!_isSoundEnabled) return;
    await _playFeedback();
    await HapticFeedback.lightImpact();
  }
  
  Future<void> _playFeedback() async {
    try {
      // CHEMIN CORRIGÉ - sans "assets/" en double
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      debugPrint('❌ Erreur lecture son: $e');
    }
  }
  
  Future<void> playBackgroundMusic(String fileName) async {}
  //Future<void> stopBackgroundMusic() async {}
  Future<void> pauseBackgroundMusic() async {}
  
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
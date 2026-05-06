import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models/game_animal.dart';
import '../services/game_services/animal_recognition_service.dart';
import '../services/game_services/animal_data_service.dart';
import '../services/game_services/translation_game_service.dart';

class GameProvider extends ChangeNotifier {
  final AnimalRecognitionService _recognitionService = AnimalRecognitionService();
  final AnimalDataService _dataService = AnimalDataService();
  final TranslationGameService _translationService = TranslationGameService();
  
  // État du jeu
  GameAnimal? _currentAnimal;
  AnimalRecognitionResult? _lastRecognition;
  List<GameAnimal> _discoveredAnimals = [];
  bool _isProcessing = false;
  String? _errorMessage;
  int _currentScore = 0;
  
  // Getters
  GameAnimal? get currentAnimal => _currentAnimal;
  AnimalRecognitionResult? get lastRecognition => _lastRecognition;
  List<GameAnimal> get discoveredAnimals => _discoveredAnimals;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  int get discoveredCount => _discoveredAnimals.length;
  int get currentScore => _currentScore;
  
  // Initialiser le provider pour un enfant
  Future<void> initializeForChild(String childId) async {
    _dataService.getChildAnimals(childId).listen((animals) {
      _discoveredAnimals = animals;
      notifyListeners();
    });
  }

  // ✅ Méthode pour charger les animaux découverts
  Future<void> loadDiscoveredAnimals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final animalsIdsJson = prefs.getString('discovered_animals_ids');
      
      if (animalsIdsJson != null && animalsIdsJson.isNotEmpty) {
        final List<dynamic> decodedIds = jsonDecode(animalsIdsJson);
        // ✅ Utiliser GameAnimalsDatabase directement (sans alias)
        _discoveredAnimals = decodedIds.map((id) {
          return GameAnimalsDatabase.animals.firstWhere(
            (a) => a.id == id,
            orElse: () => GameAnimalsDatabase.animals.first,
          );
        }).toList();
      } else {
        // Animaux par défaut pour le démarrage
        _discoveredAnimals = _getDefaultAnimals();
      }
      
      notifyListeners();
    } catch (e) {
      print('Erreur lors du chargement des animaux: $e');
      _discoveredAnimals = _getDefaultAnimals();
      notifyListeners();
    }
  }

  List<GameAnimal> _getDefaultAnimals() {
    // ✅ Utiliser GameAnimalsDatabase directement
    return List.from(GameAnimalsDatabase.animals.take(3));
  }
  
  void addDiscoveredAnimal(GameAnimal animal) {
    if (!_discoveredAnimals.any((a) => a.id == animal.id)) {
      _discoveredAnimals.add(animal);
      _saveDiscoveredAnimals();
      notifyListeners();
    }
  }
  
  // Sauvegarder les IDs des animaux découverts
  Future<void> _saveDiscoveredAnimals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final animalsIds = _discoveredAnimals.map((animal) => animal.id).toList();
      await prefs.setString('discovered_animals_ids', jsonEncode(animalsIds));
    } catch (e) {
      print('Erreur lors de la sauvegarde des animaux: $e');
    }
  }
  
  // Scanner un animal
  Future<bool> scanAnimal(File imageFile, String childId) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await _recognitionService.recognizeAnimal(imageFile);
      
      if (result == null) {
        _errorMessage = "Je n'ai pas reconnu d'animal. Essaie encore ! 🦁";
        _isProcessing = false;
        notifyListeners();
        return false;
      }
      
      _lastRecognition = result;
      
      // ✅ Utiliser GameAnimalsDatabase directement
      final animal = GameAnimalsDatabase.animals.firstWhere(
        (a) => a.id == result.matchedAnimalId,
        orElse: () => GameAnimalsDatabase.animals.first,
      );
      
      _currentAnimal = animal;
      
      final alreadyDiscovered = _discoveredAnimals.any((a) => a.id == animal.id);
      
      if (!alreadyDiscovered) {
        _discoveredAnimals.add(animal);
        await _saveDiscoveredAnimals();
      }
      
      _isProcessing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Une erreur est survenue. Réessaie !";
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }
  
  // Marquer une langue comme écoutée
  Future<void> markLanguageListened(String childId, String animalId, String languageCode) async {
    await _dataService.updateLanguageProgress(childId, animalId, languageCode, 'listened');
    _updateLocalAnimal(animalId, languageCode, (t) => t.isListened = true);
    await _saveDiscoveredAnimals();
  }
  
  // Marquer une langue comme scannée
  Future<void> markLanguageScanned(String childId, String animalId, String languageCode) async {
    await _dataService.updateLanguageProgress(childId, animalId, languageCode, 'scanned');
    _updateLocalAnimal(animalId, languageCode, (t) => t.isScanned = true);
    await _saveDiscoveredAnimals();
  }
  
  // Déverrouiller une langue
  Future<void> unlockLanguage(String childId, String animalId, String languageCode) async {
    await _dataService.updateLanguageProgress(childId, animalId, languageCode, 'unlocked');
    _updateLocalAnimal(animalId, languageCode, (t) => t.isUnlocked = true);
    await _saveDiscoveredAnimals();
  }
  
  void _updateLocalAnimal(String animalId, String languageCode, void Function(AnimalTranslation) update) {
    final index = _discoveredAnimals.indexWhere((a) => a.id == animalId);
    if (index != -1) {
      final translation = _discoveredAnimals[index].translations[languageCode];
      if (translation != null) {
        update(translation);
        notifyListeners();
      }
    }
  }
  
  // Réinitialiser pour une nouvelle session
  void reset() {
    _currentAnimal = null;
    _lastRecognition = null;
    _errorMessage = null;
    notifyListeners();
  }

  void addPoints(int points) {
    _currentScore += points;
    notifyListeners();
  }
  
  Future<void> updateAnimalProgress(String animalId, String languageCode, bool isComplete) async {
    final index = _discoveredAnimals.indexWhere((a) => a.id == animalId);
    if (index != -1) {
      final animal = _discoveredAnimals[index];
      if (animal.translations.containsKey(languageCode)) {
        animal.translations[languageCode]?.isComplete = isComplete;
        await _saveDiscoveredAnimals();
        notifyListeners();
      }
    }
  }
  
  Future<void> resetProgress() async {
    _discoveredAnimals.clear();
    _currentScore = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('discovered_animals_ids');
    _discoveredAnimals = _getDefaultAnimals();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _recognitionService.dispose();
    _translationService.dispose();
    super.dispose();
  }
}
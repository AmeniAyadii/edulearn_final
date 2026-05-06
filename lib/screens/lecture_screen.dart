import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../screens/history/history_screen.dart';

// ============================================================================
// MODÈLES
// ============================================================================

class VoiceNote {
  final String text;
  final DateTime timestamp;
  final String id;
  final String? translatedText;
  final String? detectedLanguage;

  VoiceNote({
    required this.text,
    required this.timestamp,
    required this.id,
    this.translatedText,
    this.detectedLanguage,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'id': id,
    'translatedText': translatedText,
    'detectedLanguage': detectedLanguage,
  };

  factory VoiceNote.fromJson(Map<String, dynamic> json) => VoiceNote(
    text: json['text'],
    timestamp: DateTime.parse(json['timestamp']),
    id: json['id'],
    translatedText: json['translatedText'],
    detectedLanguage: json['detectedLanguage'],
  );
}

// ============================================================================
// EXTENSIONS POUR LES TYPES
// ============================================================================

extension LanguageCodeExtension on String {
  String get languageName {
    final languages = {
      'fr': 'Français', 'en': 'Anglais', 'es': 'Espagnol',
      'ar': 'Arabe', 'de': 'Allemand', 'it': 'Italien',
      'pt': 'Portugais', 'ru': 'Russe', 'zh': 'Chinois',
      'ja': 'Japonais', 'nl': 'Néerlandais', 'ko': 'Coréen',
    };
    return languages[this] ?? this.toUpperCase();
  }
  
  String get flag {
    final flags = {
      'fr': '🇫🇷', 'en': '🇬🇧', 'es': '🇪🇸',
      'ar': '🇸🇦', 'de': '🇩🇪', 'it': '🇮🇹',
      'pt': '🇵🇹', 'ru': '🇷🇺', 'zh': '🇨🇳',
      'ja': '🇯🇵', 'nl': '🇳🇱', 'ko': '🇰🇷',
    };
    return flags[this] ?? '🌐';
  }
}

// ============================================================================
// ÉCRAN PRINCIPAL
// ============================================================================

class LectureScreen extends StatefulWidget {
  final String? childId;
  final String? childName;
  
  const LectureScreen({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<LectureScreen> createState() => _LectureScreenState();
}

class _LectureScreenState extends State<LectureScreen>
    with TickerProviderStateMixin {
  // Services
  late stt.SpeechToText _speech;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // ML Kit Services
  late LanguageIdentifier _languageIdentifier;
  OnDeviceTranslator? _translator;
  
  // État
  bool _isListening = false;
  String _recognizedText = "";
  bool _isPermissionDenied = false;
  bool _isAvailable = false;
  double _soundLevel = 0.0;
  List<VoiceNote> _history = [];
  bool _showHistory = false;
  
  // Translation
  String _detectedLanguageCode = 'fr';
  String _detectedLanguageName = 'Français';
  String _translatedText = "";
  bool _isTranslating = false;
  bool _showTranslation = false;
  bool _isDetectingLanguage = false;
  bool _isSavingToFirebase = false;
  
  // Langue cible pour la traduction
  String _targetLanguage = 'en';
  final List<Map<String, String>> _targetLanguages = [
    {'code': 'en', 'name': 'English', 'display': 'Anglais'},
    {'code': 'fr', 'name': 'French', 'display': 'Français'},
    {'code': 'es', 'name': 'Spanish', 'display': 'Espagnol'},
    {'code': 'ar', 'name': 'Arabic', 'display': 'Arabe'},
    {'code': 'de', 'name': 'German', 'display': 'Allemand'},
    {'code': 'it', 'name': 'Italian', 'display': 'Italien'},
    {'code': 'pt', 'name': 'Portuguese', 'display': 'Portugais'},
    {'code': 'ru', 'name': 'Russian', 'display': 'Russe'},
    {'code': 'zh', 'name': 'Chinese', 'display': 'Chinois'},
    {'code': 'ja', 'name': 'Japanese', 'display': 'Japonais'},
  ];
  
  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _soundLevelController;

  @override
void initState() {
  super.initState();
  print('🔍 LectureScreen initState - childId = ${widget.childId}');
  print('🔍 LectureScreen initState - childName = ${widget.childName}');
  _initAnimations();
  _initMLKitServices();
  _initSpeech();
  _loadHistory();
  _preloadSounds();
}

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    
    _soundLevelController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  Future<void> _initMLKitServices() async {
    _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
    await _initTranslator('fr', 'en');
    print('✅ Services ML Kit initialisés');
  }

  Future<void> _initTranslator(String sourceLang, String targetLang) async {
    try {
      String normalizedSource = sourceLang;
      String normalizedTarget = targetLang;
      
      if (normalizedSource == 'f' || normalizedSource == 'fr') normalizedSource = 'fr';
      if (normalizedTarget == 'e' || normalizedTarget == 'en') normalizedTarget = 'en';
      
      final source = _getTranslateLanguage(normalizedSource);
      final target = _getTranslateLanguage(normalizedTarget);
      
      print('🔄 Initialisation traducteur: $normalizedSource -> $normalizedTarget');
      
      if (source != null && target != null) {
        if (_translator != null) {
          await _translator!.close();
        }
        
        _translator = OnDeviceTranslator(
          sourceLanguage: source,
          targetLanguage: target,
        );
        
        print('✅ Traducteur initialisé: $normalizedSource -> $normalizedTarget');
      } else {
        print('❌ Langues non supportées: $normalizedSource -> $normalizedTarget');
        _showMessage('Langue non supportée pour la traduction', isError: true);
      }
    } catch (e) {
      print('❌ Erreur initialisation traducteur: $e');
    }
  }

  TranslateLanguage? _getTranslateLanguage(String code) {
    switch (code.toLowerCase()) {
      case 'fr': return TranslateLanguage.french;
      case 'en': return TranslateLanguage.english;
      case 'es': return TranslateLanguage.spanish;
      case 'ar': return TranslateLanguage.arabic;
      case 'de': return TranslateLanguage.german;
      case 'it': return TranslateLanguage.italian;
      case 'pt': return TranslateLanguage.portuguese;
      case 'ru': return TranslateLanguage.russian;
      case 'zh': return TranslateLanguage.chinese;
      case 'ja': return TranslateLanguage.japanese;
      default: return null;
    }
  }

  Future<void> _preloadSounds() async {
    try {
      await _audioPlayer.setSource(AssetSource('sounds/success.mp3'));
    } catch (e) {}
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('voice_notes_enhanced');
    if (historyString != null) {
      try {
        final List<dynamic> historyData = jsonDecode(historyString);
        _history = historyData
            .map((item) => VoiceNote.fromJson(item as Map<String, dynamic>))
            .toList();
        setState(() {});
      } catch (e) {}
    }
  }

  Future<void> _saveToHistory(String text, {String? translated, String? language}) async {
    if (text.trim().isEmpty) return;
    
    final note = VoiceNote(
      text: text,
      timestamp: DateTime.now(),
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      translatedText: translated,
      detectedLanguage: language,
    );
    _history.insert(0, note);
    if (_history.length > 30) _history.removeLast();
    
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _history.map((note) => note.toJson()).toList();
    await prefs.setString('voice_notes_enhanced', jsonEncode(historyJson));
    setState(() {});
  }

  // ============================================================================
  // SAUVEGARDE FIREBASE HISTORY
  // ============================================================================

  Future<void> _saveToFirebaseHistory(String text, int points, {String? translated, String? language}) async {
    if (widget.childId == null || widget.childId!.isEmpty) {
      print('⚠️ Pas de childId, sauvegarde Firebase ignorée');
      return;
    }
    
    setState(() {
      _isSavingToFirebase = true;
    });
    
    try {
      final historyService = HistoryFirebaseService();
      
      final wordCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
      final title = '🎙️ Dictée Magique';
      final subtitle = text.length > 40 ? '${text.substring(0, 40)}...' : text;
      
      await historyService.saveHistoryItem(
        HistoryItem(
          id: 'dictation_${DateTime.now().millisecondsSinceEpoch}_${widget.childId}',
          type: 'speech',
          category: 'activity',
          title: title,
          subtitle: subtitle,
          imageUrl: null,
          timestamp: DateTime.now(),
          points: points,
          details: {
            'wordCount': wordCount,
            'charCount': text.length,
            'text': text.length > 200 ? text.substring(0, 200) : text,
            'translatedText': translated,
            'detectedLanguage': language ?? 'fr',
          },
          childId: widget.childId!,
          childName: widget.childName ?? 'Mon enfant',
        ),
      );
      
      print('✅ Dictée sauvegardée dans Firebase: $wordCount mots, +$points points');
    } catch (e) {
      print('❌ Erreur sauvegarde Firebase: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingToFirebase = false;
        });
      }
    }
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    await _requestPermission();
  }

  Future<void> _requestPermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    if (status.isGranted) {
      setState(() => _isPermissionDenied = false);
      await _initSpeechRecognizer();
    } else {
      setState(() => _isPermissionDenied = true);
    }
  }

  Future<void> _initSpeechRecognizer() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Statut: $status'),
      onError: (error) => print('Erreur: $error'),
    );
    
    setState(() {
      _isAvailable = available;
      if (!available) {
        _recognizedText = "Reconnaissance vocale non disponible sur cet appareil";
      }
    });
  }

  Future<void> _detectLanguage(String text) async {
    if (text.trim().isEmpty || text.length < 3) {
      print('Texte trop court pour détection de langue');
      return;
    }
    
    setState(() => _isDetectingLanguage = true);
    
    try {
      final identifiedLanguages = await _languageIdentifier.identifyLanguage(text);
      
      if (identifiedLanguages.isNotEmpty) {
        String detectedCode = identifiedLanguages[0];
        
        if (detectedCode.startsWith('f')) {
          detectedCode = 'fr';
        } else if (detectedCode.startsWith('e')) {
          detectedCode = 'en';
        } else if (detectedCode.startsWith('a')) {
          detectedCode = 'ar';
        } else if (detectedCode.startsWith('e')) {
          detectedCode = 'es';
        } else if (detectedCode.startsWith('d')) {
          detectedCode = 'de';
        }
        
        print('🔍 Langue détectée: $detectedCode');
        
        setState(() {
          _detectedLanguageCode = detectedCode;
          _detectedLanguageName = detectedCode.languageName;
          _isDetectingLanguage = false;
        });
        
        _showMessage('🌍 Langue détectée : $_detectedLanguageName', isSuccess: true);
        
        if (_translator != null) {
          await _translator!.close();
          _translator = null;
        }
        
        if (_recognizedText.isNotEmpty && _detectedLanguageCode != _targetLanguage) {
          _showTranslationSuggestion();
        }
      } else {
        setState(() => _isDetectingLanguage = false);
        print('⚠️ Aucune langue détectée');
      }
    } catch (e) {
      print('❌ Erreur détection langue: $e');
      setState(() => _isDetectingLanguage = false);
    }
  }

  void _showTranslationSuggestion() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate, size: 50, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Traduire en ${_targetLanguage.languageName} ?',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Texte détecté en $_detectedLanguageName',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Plus tard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _translateText();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Traduire'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _translateText() async {
    if (_recognizedText.trim().isEmpty) {
      _showMessage('Aucun texte à traduire', isError: true);
      return;
    }
    
    String sourceLang = _detectedLanguageCode;
    String targetLang = _targetLanguage;
    
    if (sourceLang == 'f' || sourceLang == 'fr') sourceLang = 'fr';
    if (targetLang == 'e' || targetLang == 'en') targetLang = 'en';
    
    print('🔄 Demande de traduction: $sourceLang -> $targetLang');
    
    setState(() {
      _isTranslating = true;
      _showTranslation = true;
    });
    
    try {
      if (_translator == null) {
        await _initTranslator(sourceLang, targetLang);
      }
      
      if (_translator == null) {
        throw Exception('Traducteur non initialisé');
      }
      
      final translated = await _translator!.translateText(_recognizedText);
      
      setState(() {
        _translatedText = translated;
        _isTranslating = false;
      });
      
      _showMessage('✅ Traduction terminée !', isSuccess: true);
      
    } catch (e) {
      print('❌ Erreur traduction: $e');
      setState(() => _isTranslating = false);
      _showMessage('Erreur de traduction: ${e.toString()}', isError: true);
    }
  }

  Future<void> _swapLanguages() async {
    setState(() {
      final temp = _detectedLanguageCode;
      _detectedLanguageCode = _targetLanguage;
      _targetLanguage = temp;
      _detectedLanguageName = _detectedLanguageCode.languageName;
      _translator = null;
      _translatedText = "";
      _showTranslation = false;
    });
    
    if (_recognizedText.isNotEmpty) {
      await _translateText();
    }
    
    _showMessage('Langues inversées !', isSuccess: true);
  }

  Future<void> _startListening() async {
    if (_isPermissionDenied) {
      await _requestPermission();
      return;
    }

    if (!_speech.isAvailable) {
      await _initSpeechRecognizer();
    }

    setState(() {
      _isListening = true;
      _recognizedText = "";
      _translatedText = "";
      _showTranslation = false;
    });
    
    _pulseController.forward();

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
        _soundLevelController.forward(from: 0.0);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      onSoundLevelChange: (level) {
        setState(() {
          _soundLevel = level;
        });
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _soundLevel = 0.0;
    });
    _pulseController.stop();
    
    if (_recognizedText.trim().isNotEmpty) {
      await _detectLanguage(_recognizedText);
      
      final wordCount = _recognizedText.trim().split(RegExp(r'\s+')).length;
      final points = wordCount * 5;
      
      await _saveToHistory(
        _recognizedText,
        translated: _translatedText.isNotEmpty ? _translatedText : null,
        language: _detectedLanguageCode,
      );
      
      await _saveToFirebaseHistory(
        _recognizedText, 
        points,
        translated: _translatedText.isNotEmpty ? _translatedText : null,
        language: _detectedLanguageCode,
      );
      
      await _playFeedback();
      _showMessage('✅ Texte enregistré ! +$points points', isSuccess: true);
    }
  }

  Future<void> _saveManually() async {
    if (_recognizedText.trim().isEmpty) {
      _showMessage('Aucun texte à enregistrer', isError: true);
      return;
    }
    
    final wordCount = _recognizedText.trim().split(RegExp(r'\s+')).length;
    final points = wordCount * 5;
    
    await _saveToHistory(
      _recognizedText,
      translated: _translatedText.isNotEmpty ? _translatedText : null,
      language: _detectedLanguageCode,
    );
    
    await _saveToFirebaseHistory(
      _recognizedText, 
      points,
      translated: _translatedText.isNotEmpty ? _translatedText : null,
      language: _detectedLanguageCode,
    );
    
    await _playFeedback();
    _showMessage('✅ Texte enregistré ! +$points points', isSuccess: true);
  }

  Future<void> _playFeedback() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      if (await Vibrate.canVibrate) {
        Vibrate.feedback(FeedbackType.light);
      }
    } catch (e) {}
  }

  void _showMessage(String message, {bool isError = false, bool isSuccess = false}) {
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

  void _clearText() {
    setState(() {
      _recognizedText = "";
      _translatedText = "";
      _showTranslation = false;
    });
    _playFeedback();
  }

  void _copyToClipboard() {
    if (_recognizedText.isNotEmpty) {
      // Copier dans le presse-papiers
      Clipboard.setData(ClipboardData(text: _recognizedText));
      _showMessage('📋 Texte copié dans le presse-papiers', isSuccess: true);
    }
  }

  void _deleteFromHistory(int index) {
    setState(() {
      _history.removeAt(index);
    });
    final prefs = SharedPreferences.getInstance();
    prefs.then((prefs) {
      final historyJson = _history.map((note) => note.toJson()).toList();
      prefs.setString('voice_notes_enhanced', jsonEncode(historyJson));
    });
    _showMessage('🗑️ Note supprimée', isSuccess: true);
  }

  void _restoreFromHistory(VoiceNote note) {
    setState(() {
      _recognizedText = note.text;
      _translatedText = note.translatedText ?? "";
      _detectedLanguageCode = note.detectedLanguage ?? 'fr';
      _detectedLanguageName = _detectedLanguageCode.languageName;
      _showTranslation = note.translatedText != null && note.translatedText!.isNotEmpty;
      _showHistory = false;
    });
    _showMessage('📝 Note restaurée', isSuccess: true);
    _playFeedback();
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          childId: widget.childId,
          childName: widget.childName,
        ),
      ),
    );
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              elevation: 0,
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  '🎙️ Dictée Magique',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: 0.1,
                      child: const Icon(Icons.mic, size: 100, color: Colors.white),
                    ),
                  ),
                ),
              ),
              actions: [
                if (_isSavingToFirebase)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: _navigateToHistory,
                  tooltip: 'Historique complet',
                ),
                IconButton(
                  icon: const Icon(Icons.history_toggle_off),
                  onPressed: () => setState(() => _showHistory = !_showHistory),
                  tooltip: 'Historique local',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'clear') _clearText();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'clear', child: Text('🗑️ Effacer le texte')),
                  ],
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildLanguageInfo(),
                  const SizedBox(height: 12),
                  _buildTextArea(),
                  const SizedBox(height: 16),
                  if (_showTranslation) _buildTranslationSection(),
                  if (_showTranslation) const SizedBox(height: 16),
                  if (_showHistory) _buildHistorySection(),
                  if (_showHistory) const SizedBox(height: 16),
                  _buildControlSection(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isDetectingLanguage
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _detectedLanguageCode.flag,
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Langue détectée',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                Text(
                  _detectedLanguageName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Auto',
                  style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                ),
              ],
            ),
          ),
          if (widget.childId != null && widget.childId!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_sync, size: 10, color: Colors.blue),
                  const SizedBox(width: 2),
                  Text(
                    'Cloud',
                    style: TextStyle(fontSize: 8, color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextArea() {
    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isListening ? Colors.red.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isListening ? Icons.mic : Icons.lightbulb,
                      size: 14,
                      color: _isListening ? Colors.red : AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isListening ? 'Écoute en cours...' : 'Texte original',
                      style: TextStyle(
                        fontSize: 10,
                        color: _isListening ? Colors.red : AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_recognizedText.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: _copyToClipboard,
                  tooltip: 'Copier',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                _recognizedText.isEmpty 
                    ? "👋 Appuyez sur le micro et parlez...\n\nVotre texte apparaîtra ici."
                    : _recognizedText,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  height: 1.5,
                  color: _recognizedText.isEmpty ? Colors.grey.shade400 : AppTheme.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '📝 Traduction',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.swap_horiz, size: 18),
                onPressed: _swapLanguages,
                tooltip: 'Inverser les langues',
              ),
              DropdownButton<String>(
                value: _targetLanguage,
                underline: const SizedBox(),
                items: _targetLanguages.map((lang) {
                  return DropdownMenuItem(
                    value: lang['code'],
                    child: Text('${lang['code']!.flag} ${lang['display']}'),
                  );
                }).toList(),
                onChanged: (value) async {
                  if (value != null && value != _targetLanguage) {
                    setState(() {
                      _targetLanguage = value;
                      _translator = null;
                      _translatedText = "";
                    });
                    if (_recognizedText.isNotEmpty) {
                      await _translateText();
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isTranslating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.translate, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    _translatedText.isEmpty 
                        ? "Appuyez sur 'Traduire' pour voir la traduction"
                        : _translatedText,
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                ),
              ],
            ),
          if (!_isTranslating && _recognizedText.isNotEmpty && _translatedText.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton.icon(
                onPressed: _translateText,
                icon: const Icon(Icons.translate, size: 18),
                label: const Text('Traduire'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlSection() {
    return Column(
      children: [
        if (_isListening)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _soundLevel,
                    backgroundColor: Colors.grey.shade200,
                    color: AppTheme.primaryColor,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Parlez...',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        
        GestureDetector(
          onTap: _isListening ? _stopListening : _startListening,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.red : AppTheme.primaryColor).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: _isListening ? Colors.red : AppTheme.primaryColor,
                    child: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      size: 45,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearText,
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Effacer'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _recognizedText.isNotEmpty ? _saveManually : null,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: AppTheme.secondaryColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _navigateToHistory,
            icon: const Icon(Icons.history),
            label: const Text('Historique'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.history, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  '📜 Historique local',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(),
          if (_history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Aucune note enregistrée'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final note = _history[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Icon(Icons.note, size: 16, color: AppTheme.primaryColor),
                  ),
                  title: Text(
                    note.text.length > 40 ? '${note.text.substring(0, 40)}...' : note.text,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${note.timestamp.day}/${note.timestamp.month}/${note.timestamp.year} ${note.timestamp.hour}:${note.timestamp.minute}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      if (note.detectedLanguage != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '🌍 ${note.detectedLanguage!.languageName}',
                            style: TextStyle(fontSize: 9, color: Colors.green.shade700),
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore, size: 20),
                        onPressed: () => _restoreFromHistory(note),
                        tooltip: 'Restaurer',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deleteFromHistory(index),
                        tooltip: 'Supprimer',
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextButton.icon(
              onPressed: _navigateToHistory,
              icon: const Icon(Icons.cloud_queue),
              label: const Text('Voir tout l\'historique synchronisé'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();
    _soundLevelController.dispose();
    _audioPlayer.dispose();
    _languageIdentifier.close();
    _translator?.close();
    super.dispose();
  }
}